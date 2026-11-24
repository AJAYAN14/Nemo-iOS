import SwiftUI

/// 登录与注册主视图（贴底两段式容器）
public struct LoginScreenView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // 表单输入绑定
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var registerUsername: String = ""
    @State private var registerConfirmPassword: String = ""

    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false

    // 校验与交互状态
    @State private var isFormAttempted: Bool = false
    @State private var toastMessage: String?
    @State private var isToastPresented: Bool = false

    public init() {}

    private var isDark: Bool {
        colorScheme == .dark
    }

    private var pageBackgroundColor: Color {
        if isDark {
            return Color(red: 0.051, green: 0.047, blue: 0.067) // #0D0C11
        } else {
            return Color(red: 0.969, green: 0.976, blue: 0.988) // #F7F9FC
        }
    }

    private var backButtonBackground: Color {
        isDark ? Color.white.opacity(0.10) : Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.08)
    }

    private var backButtonTint: Color {
        isDark ? .white : Color(red: 0.06, green: 0.09, blue: 0.16)
    }

    // 表单校验计算
    private var emailError: Bool {
        isFormAttempted && (email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !email.contains("@"))
    }

    private var passwordError: Bool {
        isFormAttempted && (authStore.currentStage == .login ? password.isEmpty : password.count < 8)
    }

    private var confirmPasswordError: Bool {
        isFormAttempted && authStore.currentStage == .register && (registerConfirmPassword != password)
    }

    public var body: some View {
        ZStack {
            // 1. 全局底色
            pageBackgroundColor
                .ignoresSafeArea()

            // 2. 顶部装饰假名天幕波纹
            VStack {
                KanaWaveHeaderView()
                    .frame(height: 320)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)

            // 3. 核心主内容区：统一贴底对齐（Bottom-Pinned）
            GeometryReader { outerProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 160)

                        // 阶段切换容器
                        Group {
                            switch authStore.currentStage {
                            case .welcome:
                                AuthWelcomeView(
                                    onNavigateToLogin: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            authStore.currentStage = .login
                                            isFormAttempted = false
                                        }
                                    },
                                    onNavigateToRegister: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            authStore.currentStage = .register
                                            isFormAttempted = false
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))

                            case .login:
                                LoginFormView(
                                    email: $email,
                                    password: $password,
                                    isPasswordVisible: $isPasswordVisible,
                                    isLoading: authStore.isLoading,
                                    emailError: emailError,
                                    passwordError: passwordError,
                                    onLogin: handleLogin,
                                    onNavigateToRegister: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            authStore.currentStage = .register
                                            isFormAttempted = false
                                        }
                                    },
                                    onForgotPassword: handleForgotPassword,
                                    onGoogleLogin: handleGoogleAuth
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))

                            case .register:
                                RegisterFormView(
                                    username: $registerUsername,
                                    email: $email,
                                    password: $password,
                                    confirmPassword: $registerConfirmPassword,
                                    isPasswordVisible: $isPasswordVisible,
                                    isConfirmPasswordVisible: $isConfirmPasswordVisible,
                                    isLoading: authStore.isLoading,
                                    emailError: emailError,
                                    passwordError: passwordError,
                                    confirmPasswordError: confirmPasswordError,
                                    onRegister: handleRegister,
                                    onNavigateToLogin: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            authStore.currentStage = .login
                                            isFormAttempted = false
                                        }
                                    },
                                    onGoogleRegister: handleGoogleAuth
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: outerProxy.size.height, alignment: .bottom)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            // 4. 左上角返回按钮（非 WELCOME 阶段显示）
            if authStore.currentStage != .welcome {
                VStack {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                authStore.currentStage = .welcome
                                isFormAttempted = false
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(backButtonTint)
                                .frame(width: 44, height: 44)
                                .background(backButtonBackground)
                                .clipShape(Circle())
                        }
                        .buttonStyle(NemoPressableButtonStyle())
                        .padding(.leading, 20)
                        .padding(.top, 10)

                        Spacer()
                    }
                    Spacer()
                }
            }

            // 5. 浮层轻量级提示 Toast
            if isToastPresented, let message = toastMessage {
                VStack {
                    Spacer().frame(height: 50)
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .shadow(radius: 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .zIndex(99)
            }
        }
        .onChange(of: authStore.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                showToast("登录成功")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    dismiss()
                }
            }
        }
        .onChange(of: authStore.errorMessage) { _, error in
            if let error = error {
                showToast(error)
            }
        }
    }

    // MARK: - 业务交互动作

    private func handleLogin() {
        isFormAttempted = true
        guard !email.isEmpty, email.contains("@"), !password.isEmpty else {
            showToast("请检查邮箱与密码")
            return
        }

        Task {
            _ = await authStore.login(email: email, password: password)
        }
    }

    private func handleRegister() {
        isFormAttempted = true
        guard !email.isEmpty, email.contains("@") else {
            showToast("请输入有效的电子邮箱地址")
            return
        }
        guard password.count >= 8 else {
            showToast("密码长度不能少于 8 位")
            return
        }
        guard registerConfirmPassword == password else {
            showToast("两次输入的密码不一致")
            return
        }

        Task {
            _ = await authStore.register(username: registerUsername, email: email, password: password)
        }
    }

    private func handleGoogleAuth() {
        Task {
            _ = await authStore.signInWithGoogle()
        }
    }

    private func handleForgotPassword() {
        showToast("重置链接已准备就绪，请查阅邮箱")
    }

    private func showToast(_ text: String) {
        toastMessage = text
        withAnimation(.spring()) {
            isToastPresented = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut) {
                isToastPresented = false
            }
        }
    }
}
