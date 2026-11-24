import Foundation

/// 认证服务通用抽象协议
public protocol AuthService: Sendable {
    /// 获取当前有效会话对应的用户，若未登录或已失效则返回 nil
    func currentSessionUser() async throws -> User?

    /// 邮箱密码登录
    func login(email: String, password: String) async throws -> User

    /// 邮箱注册新账号
    func register(username: String, email: String, password: String) async throws -> User

    /// Google 账号快捷登录
    func signInWithGoogle() async throws -> User

    /// 退出登录并清除会话
    func logout() async throws

    /// 监听认证状态变更
    func observeAuthState(onChange: @escaping @Sendable (User?) -> Void) async
}

/// 模拟认证服务（供自动化测试与快速离线验证使用）
public final class MockAuthService: AuthService, @unchecked Sendable {
    private var simulatedUser: User?
    private var authObservers: [@Sendable (User?) -> Void] = []
    private let lock = NSLock()

    public init(initialUser: User? = nil) {
        self.simulatedUser = initialUser
    }

    public func currentSessionUser() async throws -> User? {
        lock.lock()
        defer { lock.unlock() }
        return simulatedUser
    }

    public func login(email: String, password: String) async throws -> User {
        guard !email.isEmpty, !password.isEmpty else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "邮箱和密码不能为空"])
        }
        let nickname = email.components(separatedBy: "@").first ?? "Nemo 用户"
        let user = User(
            id: UUID().uuidString,
            username: nickname,
            email: email,
            sessionToken: "mock_session_token_\(UUID().uuidString)",
            hasGoogleLinked: false,
            isOnlyGoogleIdentity: false,
            isNewUser: false
        )
        setSimulatedUser(user)
        return user
    }

    public func register(username: String, email: String, password: String) async throws -> User {
        guard !email.isEmpty, !password.isEmpty else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "邮箱和密码不能为空"])
        }
        let displayName = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (email.components(separatedBy: "@").first ?? "Nemo 用户")
            : username
        let user = User(
            id: UUID().uuidString,
            username: displayName,
            email: email,
            sessionToken: "mock_session_token_\(UUID().uuidString)",
            hasGoogleLinked: false,
            isOnlyGoogleIdentity: false,
            isNewUser: true
        )
        setSimulatedUser(user)
        return user
    }

    public func signInWithGoogle() async throws -> User {
        let randomSuffix = UUID().uuidString.prefix(6)
        let user = User(
            id: "mock_user_\(UUID().uuidString)",
            username: "测试用户",
            email: "test_user_\(randomSuffix)@test.local",
            avatarUrl: nil,
            sessionToken: "session_\(UUID().uuidString)",
            hasGoogleLinked: true,
            isOnlyGoogleIdentity: true,
            isNewUser: false
        )
        setSimulatedUser(user)
        return user
    }

    public func logout() async throws {
        setSimulatedUser(nil)
    }

    public func observeAuthState(onChange: @escaping @Sendable (User?) -> Void) async {
        lock.lock()
        authObservers.append(onChange)
        let current = simulatedUser
        lock.unlock()
        onChange(current)
    }

    private func setSimulatedUser(_ user: User?) {
        lock.lock()
        self.simulatedUser = user
        let observers = self.authObservers
        lock.unlock()

        for observer in observers {
            observer(user)
        }
    }
}
