import Foundation

/// Supabase 会话错误精准分类器
public enum SessionErrorClassifier {
    /// 判定是否属于确定性的服务端会话失效（需要清空本地凭证）
    public static func isPermanentSessionInvalidation(_ error: Error) -> Bool {
        if isNetworkTransientError(error) {
            return false
        }

        let nsError = error as NSError
        if nsError.domain == "SupabaseAuthError" {
            if nsError.code == 401 || nsError.code == 403 {
                return true
            }
            if nsError.code == 400 {
                let desc = nsError.localizedDescription.lowercased()
                let failureKeywords = [
                    "invalid_grant",
                    "validation_failed",
                    "invalid refresh token",
                    "refresh token is not valid",
                    "already used",
                    "token not found",
                    "session_not_found",
                    "bad_jwt"
                ]
                return failureKeywords.contains { desc.contains($0) }
            }
        }
        return false
    }

    /// 判定是否属于网络不可达或服务端暂态故障（需保留凭据，支持离线降级）
    public static func isNetworkTransientError(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain || nsError.domain == NSPOSIXErrorDomain {
            return true
        }
        if nsError.domain == "SupabaseAuthError" {
            if (500...599).contains(nsError.code) || nsError.code == 429 {
                return true
            }
        }
        return false
    }
}

/// 基于原生 URLSession 实现的 Supabase GoTrue 认证客户端
public final class SupabaseAuthService: AuthService, @unchecked Sendable {
    public static let shared = SupabaseAuthService()

    private let baseUrl: String
    private let apiKey: String
    private let session: URLSession
    private let localStorage: AuthLocalStorage

    private var authObservers: [@Sendable (User?) -> Void] = []
    private let observerLock = NSLock()

    private var activeRefreshTask: Task<AuthSession, Error>?
    private let refreshLock = NSLock()

    public init(
        baseUrl: String = "https://ccggidebxekvqbpjktxl.supabase.co/auth/v1",
        apiKey: String = "sb_publishable_c6vmYxJAeY8mqXvitlb3Pw_WkrzsRqg",
        session: URLSession = .shared,
        localStorage: AuthLocalStorage = .shared
    ) {
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.session = session
        self.localStorage = localStorage
    }

    // MARK: - AuthService 实现

    public func currentSessionUser() async throws -> User? {
        guard let savedSession = await localStorage.loadSession() else {
            return nil
        }

        if !savedSession.isExpired {
            return savedSession.user
        }

        do {
            let refreshed = try await refreshToken(savedSession.refreshToken)
            await notifyAuthStateChanged(refreshed.user)
            return refreshed.user
        } catch {
            if SessionErrorClassifier.isPermanentSessionInvalidation(error) {
                try? await localStorage.clearSession()
                await notifyAuthStateChanged(nil)
                return nil
            } else {
                return savedSession.user
            }
        }
    }

    public func login(email: String, password: String) async throws -> User {
        guard let url = URL(string: "\(baseUrl)/token?grant_type=password") else {
            throw URLError(.badURL)
        }

        let bodyPayload: [String: Any] = [
            "email": email,
            "password": password
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyPayload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = parseErrorMessage(from: data) ?? "登录失败，请检查账号密码"
            throw NSError(domain: "SupabaseAuthError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        let authResponse = try parseTokenResponse(data: data)
        let authSession = AuthSession(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            tokenType: authResponse.tokenType,
            expiresIn: authResponse.expiresIn,
            expiresAt: Date().addingTimeInterval(TimeInterval(authResponse.expiresIn)),
            user: authResponse.user
        )

        try await localStorage.saveSession(authSession)
        await notifyAuthStateChanged(authSession.user)
        return authSession.user
    }

    public func register(username: String, email: String, password: String) async throws -> User {
        guard let url = URL(string: "\(baseUrl)/signup") else {
            throw URLError(.badURL)
        }

        var bodyPayload: [String: Any] = [
            "email": email,
            "password": password
        ]
        let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            bodyPayload["data"] = ["nickname": trimmedName]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyPayload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            let errorMessage = parseErrorMessage(from: data) ?? "注册失败，请稍后重试"
            throw NSError(domain: "SupabaseAuthError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        if let authResponse = try? parseTokenResponse(data: data) {
            let authSession = AuthSession(
                accessToken: authResponse.accessToken,
                refreshToken: authResponse.refreshToken,
                tokenType: authResponse.tokenType,
                expiresIn: authResponse.expiresIn,
                expiresAt: Date().addingTimeInterval(TimeInterval(authResponse.expiresIn)),
                user: authResponse.user
            )
            try await localStorage.saveSession(authSession)
            await notifyAuthStateChanged(authSession.user)
            return authSession.user
        }

        let user = parseUser(from: data, fallbackNickname: trimmedName)
        await notifyAuthStateChanged(user)
        return user
    }

    public func signInWithGoogle() async throws -> User {
        let googleService = GoogleAuthService.shared
        let user = try await googleService.authenticateWithGoogle()
        await notifyAuthStateChanged(user)
        return user
    }

    public func logout() async throws {
        if let savedSession = await localStorage.loadSession() {
            if let url = URL(string: "\(baseUrl)/logout") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue(apiKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(savedSession.accessToken)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 10
                _ = try? await session.data(for: request)
            }
        }
        try await localStorage.clearSession()
        await notifyAuthStateChanged(nil)
    }

    public func observeAuthState(onChange: @escaping @Sendable (User?) -> Void) async {
        observerLock.lock()
        authObservers.append(onChange)
        observerLock.unlock()

        let cachedUser = await localStorage.loadSession()?.user
        onChange(cachedUser)
    }

    // MARK: - 凭证刷新与 In-Flight 去重

    public func refreshToken(_ refreshToken: String) async throws -> AuthSession {
        let task: Task<AuthSession, Error> = refreshLock.withLock {
            if let existing = activeRefreshTask {
                return existing
            }

            let newTask = Task<AuthSession, Error> {
                defer {
                    refreshLock.withLock {
                        activeRefreshTask = nil
                    }
                }
                return try await executeRefreshTokenRequest(refreshToken)
            }

            activeRefreshTask = newTask
            return newTask
        }

        return try await task.value
    }

    private func executeRefreshTokenRequest(_ refreshToken: String) async throws -> AuthSession {
        guard let url = URL(string: "\(baseUrl)/token?grant_type=refresh_token") else {
            throw URLError(.badURL)
        }

        let bodyPayload: [String: Any] = [
            "refresh_token": refreshToken
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyPayload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 200 {
            let authResponse = try parseTokenResponse(data: data)
            let newSession = AuthSession(
                accessToken: authResponse.accessToken,
                refreshToken: authResponse.refreshToken,
                tokenType: authResponse.tokenType,
                expiresIn: authResponse.expiresIn,
                expiresAt: Date().addingTimeInterval(TimeInterval(authResponse.expiresIn)),
                user: authResponse.user
            )

            try await localStorage.saveSession(newSession)
            return newSession
        }

        let errorMessage = parseErrorMessage(from: data) ?? "会话凭据已失效"
        throw NSError(domain: "SupabaseAuthError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }

    // MARK: - 辅助解析方法

    private struct ParsedTokenResponse {
        let accessToken: String
        let refreshToken: String
        let tokenType: String
        let expiresIn: Int
        let user: User
    }

    private func parseTokenResponse(data: Data) throws -> ParsedTokenResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            throw NSError(domain: "SupabaseAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析认证响应"])
        }

        let tokenType = json["token_type"] as? String ?? "bearer"
        let expiresIn = json["expires_in"] as? Int ?? 3600

        var userJson = json["user"] as? [String: Any] ?? [:]
        if userJson.isEmpty {
            userJson = json
        }
        let user = parseUser(fromDict: userJson, fallbackToken: accessToken)

        return ParsedTokenResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresIn: expiresIn,
            user: user
        )
    }

    public func parseUser(fromDict dict: [String: Any], fallbackNickname: String? = nil, fallbackToken: String = "") -> User {
        let id = dict["id"] as? String ?? UUID().uuidString
        let email = dict["email"] as? String

        let meta = dict["user_metadata"] as? [String: Any] ?? [:]
        var nickname = fallbackNickname
        if let nick = meta["nickname"] as? String, !nick.isEmpty {
            nickname = nick
        } else if let fullName = meta["full_name"] as? String, !fullName.isEmpty {
            nickname = fullName
        } else if let name = meta["name"] as? String, !name.isEmpty {
            nickname = name
        } else if nickname == nil || nickname?.isEmpty == true {
            nickname = email?.components(separatedBy: "@").first ?? "Nemo 用户"
        }

        var avatarUrl: String?
        if let avatar = meta["avatar"] as? String, !avatar.isEmpty {
            avatarUrl = avatar
        } else if let url = meta["avatar_url"] as? String, !url.isEmpty {
            avatarUrl = url
        } else if let pic = meta["picture"] as? String, !pic.isEmpty {
            avatarUrl = pic
        }

        let identities = dict["identities"] as? [[String: Any]] ?? []
        let hasGoogleLinked = identities.contains { ($0["provider"] as? String) == "google" }
        let isOnlyGoogle = (identities.count == 1) && hasGoogleLinked

        var isNewUser = false
        if let createdAtString = dict["created_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let createdDate = formatter.date(from: createdAtString) {
                isNewUser = abs(createdDate.timeIntervalSinceNow) < 120
            }
        }

        return User(
            id: id,
            username: nickname ?? "Nemo 用户",
            email: email,
            avatarUrl: avatarUrl,
            sessionToken: fallbackToken,
            hasGoogleLinked: hasGoogleLinked,
            isOnlyGoogleIdentity: isOnlyGoogle,
            isNewUser: isNewUser
        )
    }

    private func parseUser(from data: Data, fallbackNickname: String? = nil) -> User {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let userDict = json["user"] as? [String: Any] ?? json
            return parseUser(fromDict: userDict, fallbackNickname: fallbackNickname)
        }
        return User(id: UUID().uuidString, username: fallbackNickname ?? "Nemo 用户", isNewUser: true)
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let msg = json["msg"] as? String { return msg }
        if let errorDesc = json["error_description"] as? String { return errorDesc }
        if let message = json["message"] as? String { return message }
        return nil
    }

    private func notifyAuthStateChanged(_ user: User?) async {
        observerLock.lock()
        let observers = authObservers
        observerLock.unlock()

        for observer in observers {
            observer(user)
        }
    }
}
