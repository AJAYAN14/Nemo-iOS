import Foundation
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Google 快捷登录真实 OAuth 鉴权服务
public final class GoogleAuthService: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
    public static let shared = GoogleAuthService()

    private let supabaseAuthUrl: String
    private let apiKey: String
    private let callbackScheme: String
    private let redirectUri: String
    private let session: URLSession
    private var activeAuthSession: ASWebAuthenticationSession?

    public init(
        supabaseAuthUrl: String = "https://ccggidebxekvqbpjktxl.supabase.co/auth/v1",
        apiKey: String = "sb_publishable_c6vmYxJAeY8mqXvitlb3Pw_WkrzsRqg",
        callbackScheme: String = "nemo",
        redirectUri: String = "nemo://auth-callback",
        session: URLSession = .shared
    ) {
        self.supabaseAuthUrl = supabaseAuthUrl
        self.apiKey = apiKey
        self.callbackScheme = callbackScheme
        self.redirectUri = redirectUri
        self.session = session
        super.init()
    }

    /// 发起 Google 账号 OAuth 快捷登录流程并换取 Supabase 用户会话
    @MainActor
    public func authenticateWithGoogle() async throws -> User {
        guard var urlComponents = URLComponents(string: "\(supabaseAuthUrl)/authorize") else {
            throw URLError(.badURL)
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectUri)
        ]
        guard let authorizeUrl = urlComponents.url else {
            throw URLError(.badURL)
        }

        let callbackUrl: URL = try await withCheckedThrowingContinuation { continuation in
            let webSession = ASWebAuthenticationSession(
                url: authorizeUrl,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                self?.activeAuthSession = nil

                if let error = error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        continuation.resume(throwing: NSError(
                            domain: "GoogleAuthError",
                            code: -1001,
                            userInfo: [NSLocalizedDescriptionKey: "已取消 Google 账号登录"]
                        ))
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: NSError(
                        domain: "GoogleAuthError",
                        code: -1002,
                        userInfo: [NSLocalizedDescriptionKey: "未收到授权回调信息"]
                    ))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            webSession.presentationContextProvider = self
            webSession.prefersEphemeralWebBrowserSession = false
            self.activeAuthSession = webSession

            if !webSession.start() {
                continuation.resume(throwing: NSError(
                    domain: "GoogleAuthError",
                    code: -1003,
                    userInfo: [NSLocalizedDescriptionKey: "无法拉起系统身份验证界面"]
                ))
            }
        }

        let tokens = try parseCallbackParameters(from: callbackUrl)
        let user = try await fetchUserProfile(accessToken: tokens.accessToken)

        let authSession = AuthSession(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            tokenType: "bearer",
            expiresIn: tokens.expiresIn,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokens.expiresIn)),
            user: user
        )
        try await AuthLocalStorage.shared.saveSession(authSession)

        return user
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    #if canImport(UIKit)
    @MainActor
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) {
            return window
        }
        if let fallbackScene = scenes.first, let window = fallbackScene.windows.first {
            return window
        }
        return UIWindow()
    }
    #elseif canImport(AppKit)
    @MainActor
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
    #endif

    // MARK: - 回调参数解析与网络请求

    public func parseCallbackParameters(from url: URL) throws -> (accessToken: String, refreshToken: String, expiresIn: Int) {
        var params: [String: String] = [:]

        if let fragment = url.fragment, !fragment.isEmpty {
            for pair in fragment.components(separatedBy: "&") {
                let parts = pair.components(separatedBy: "=")
                if parts.count == 2,
                   let key = parts[0].removingPercentEncoding,
                   let value = parts[1].removingPercentEncoding {
                    params[key] = value
                }
            }
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let items = components.queryItems {
            for item in items {
                if let val = item.value {
                    params[item.name] = val
                }
            }
        }

        if let error = params["error"] {
            let desc = params["error_description"] ?? error
            throw NSError(domain: "GoogleAuthError", code: -1004, userInfo: [NSLocalizedDescriptionKey: "Google 授权失败: \(desc)"])
        }

        guard let accessToken = params["access_token"], !accessToken.isEmpty else {
            throw NSError(domain: "GoogleAuthError", code: -1005, userInfo: [NSLocalizedDescriptionKey: "回调中缺少有效授权凭证"])
        }

        let refreshToken = params["refresh_token"] ?? ""
        let expiresIn = Int(params["expires_in"] ?? "3600") ?? 3600

        return (accessToken, refreshToken, expiresIn)
    }

    public func fetchUserProfile(accessToken: String) async throws -> User {
        guard let url = URL(string: "\(supabaseAuthUrl)/user") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "SupabaseAuthError", code: code, userInfo: [NSLocalizedDescriptionKey: "获取用户信息失败"])
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SupabaseAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析用户数据"])
        }

        return SupabaseAuthService.shared.parseUser(fromDict: json, fallbackToken: accessToken)
    }
}
