import SwiftUI

/// 认证流程所处的交互阶段
public enum AuthStage: Hashable, Sendable {
    case welcome
    case login
    case register
}

/// 顶层导航鉴权受控状态
public enum AuthNavigationState: Equatable, Sendable {
    case launching
    case unauthenticated
    case authenticating
    case authenticated
}

/// 全局用户认证与会话状态管理中枢
@MainActor
@Observable
public final class AuthStore {
    public var currentUser: User?
    public var currentStage: AuthStage = .welcome
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var successMessage: String?
    public var isSessionResolved: Bool = false

    /// 当前是否已处于有效登录状态
    public var isLoggedIn: Bool {
        currentUser != nil
    }

    /// 统一全局导航流转状态
    public var navigationState: AuthNavigationState {
        if !isSessionResolved {
            return .launching
        }
        if isLoading {
            return .authenticating
        }
        if isLoggedIn {
            return .authenticated
        }
        return .unauthenticated
    }

    private let authService: AuthService

    public init(authService: AuthService = SupabaseAuthService.shared) {
        self.authService = authService
    }

    /// 应用冷启动或初始化时解析并恢复本地会话
    public func resolveSession() async {
        do {
            currentUser = try await authService.currentSessionUser()
            isSessionResolved = true
        } catch {
            isSessionResolved = true
        }

        // 持续监听认证会话变更
        await authService.observeAuthState { [weak self] updatedUser in
            Task { @MainActor in
                self?.currentUser = updatedUser
                self?.isSessionResolved = true
            }
        }
    }

    /// 邮箱密码登录
    @discardableResult
    public func login(email: String, password: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "请输入邮箱和密码"
            return false
        }

        guard trimmedEmail.contains("@") else {
            errorMessage = "请输入有效的电子邮箱地址"
            return false
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let user = try await authService.login(email: trimmedEmail, password: password)
            currentUser = user
            isLoading = false
            successMessage = "登录成功"
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// 邮箱密码注册
    @discardableResult
    public func register(username: String, email: String, password: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "请补全邮箱和密码"
            return false
        }

        guard trimmedEmail.contains("@") else {
            errorMessage = "请输入有效的电子邮箱地址"
            return false
        }

        guard password.count >= 8 else {
            errorMessage = "密码长度不能少于 8 位"
            return false
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let user = try await authService.register(username: username, email: trimmedEmail, password: password)
            currentUser = user
            isLoading = false
            successMessage = "注册成功"
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Google 快捷登录
    @discardableResult
    public func signInWithGoogle() async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let user = try await authService.signInWithGoogle()
            currentUser = user
            isLoading = false
            successMessage = "Google 登录成功"
            return true
        } catch {
            isLoading = false
            errorMessage = "Google 登录失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 退出登录
    public func logout() async {
        isLoading = true
        do {
            try await authService.logout()
            currentUser = nil
            currentStage = .welcome
            isSessionResolved = true
            isLoading = false
        } catch {
            currentUser = nil
            currentStage = .welcome
            isSessionResolved = true
            isLoading = false
        }
    }

    /// 清理全局提示消息
    public func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - 导航守卫状态判断扩展
public extension AuthStore {
    /// 是否满足进入主界面的放行条件
    var shouldShowMainInterface: Bool {
        isSessionResolved && isLoggedIn
    }

    /// 是否应展示登录/注册认证阻断界面
    var shouldShowAuthentication: Bool {
        isSessionResolved && !isLoggedIn
    }
}
