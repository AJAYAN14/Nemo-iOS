import SwiftUI

/// 注册表单视图
public struct RegisterFormView: View {
    @Binding public var username: String
    @Binding public var email: String
    @Binding public var password: String
    @Binding public var confirmPassword: String
    @Binding public var isPasswordVisible: Bool
    @Binding public var isConfirmPasswordVisible: Bool
    public var isLoading: Bool
    public var emailError: Bool
    public var passwordError: Bool
    public var confirmPasswordError: Bool
    public var onRegister: () -> Void
    public var onNavigateToLogin: () -> Void
    public var onGoogleRegister: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        username: Binding<String>,
        email: Binding<String>,
        password: Binding<String>,
        confirmPassword: Binding<String>,
        isPasswordVisible: Binding<Bool>,
        isConfirmPasswordVisible: Binding<Bool>,
        isLoading: Bool,
        emailError: Bool = false,
        passwordError: Bool = false,
        confirmPasswordError: Bool = false,
        onRegister: @escaping () -> Void,
        onNavigateToLogin: @escaping () -> Void,
        onGoogleRegister: @escaping () -> Void
    ) {
        self._username = username
        self._email = email
        self._password = password
        self._confirmPassword = confirmPassword
        self._isPasswordVisible = isPasswordVisible
        self._isConfirmPasswordVisible = isConfirmPasswordVisible
        self.isLoading = isLoading
        self.emailError = emailError
        self.passwordError = passwordError
        self.confirmPasswordError = confirmPasswordError
        self.onRegister = onRegister
        self.onNavigateToLogin = onNavigateToLogin
        self.onGoogleRegister = onGoogleRegister
    }

    private var isDark: Bool {
        colorScheme == .dark
    }

    private var titleTextColor: Color {
        isDark ? .white : Color(red: 0.06, green: 0.09, blue: 0.16)
    }

    private var descTextColor: Color {
        isDark ? Color.white.opacity(0.60) : Color(red: 0.39, green: 0.45, blue: 0.55)
    }

    private var capsuleBg: Color {
        isDark ? Color.white.opacity(0.10) : Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.06)
    }

    private var capsuleTextColor: Color {
        isDark ? Color(red: 0.49, green: 0.83, blue: 0.99) : Color(red: 0.14, green: 0.39, blue: 0.92)
    }

    private var dividerColor: Color {
        isDark ? Color.white.opacity(0.10) : Color(red: 0.88, green: 0.91, blue: 0.94)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题行：左侧标题与副标题，右侧【去登录】胶囊切换
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("开启旅程")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(titleTextColor)
                        .tracking(-0.5)

                    Text("开启您的沉浸式日语假名习得之旅")
                        .font(.system(size: 13))
                        .foregroundStyle(descTextColor)
                }

                Spacer()

                Button(action: onNavigateToLogin) {
                    Text("去登录")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(capsuleTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(capsuleBg)
                        .clipShape(Capsule())
                }
                .buttonStyle(NemoPressableButtonStyle())
            }

            Spacer().frame(height: 20)

            // 输入框列表
            VStack(spacing: 12) {
                // 1. 称呼
                AuthTextField(
                    text: $username,
                    placeholder: "您的称呼（选填，最多16字）",
                    systemImage: "person",
                    keyboardType: .default
                )

                // 2. 邮箱
                AuthTextField(
                    text: $email,
                    placeholder: "电子邮箱地址",
                    systemImage: "envelope",
                    isError: emailError,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )

                // 3. 设置密码
                AuthTextField(
                    text: $password,
                    placeholder: "设置密码（至少 8 位）",
                    systemImage: "lock",
                    isSecure: true,
                    isPasswordVisible: $isPasswordVisible,
                    isError: passwordError,
                    textContentType: .newPassword
                )

                // 4. 确认密码
                AuthTextField(
                    text: $confirmPassword,
                    placeholder: "再次输入密码确认",
                    systemImage: "lock",
                    isSecure: true,
                    isPasswordVisible: $isConfirmPasswordVisible,
                    isError: confirmPasswordError,
                    textContentType: .newPassword,
                    onSubmit: onRegister
                )
            }

            Spacer().frame(height: 16)

            // 全宽立即注册按钮
            Button(action: onRegister) {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 18, height: 18)
                    } else {
                        Text("立即注册")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.39, blue: 0.96),
                            Color(red: 0.08, green: 0.32, blue: 0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(
                    color: Color(red: 0.15, green: 0.39, blue: 0.96).opacity(0.35),
                    radius: 10,
                    x: 0,
                    y: 3
                )
            }
            .buttonStyle(NemoPressableButtonStyle())
            .disabled(isLoading)

            Spacer().frame(height: 14)

            // 分割线「或」
            HStack(spacing: 14) {
                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)

                Text("或")
                    .font(.system(size: 12))
                    .foregroundStyle(descTextColor)

                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)
            }
            .padding(.vertical, 4)

            Spacer().frame(height: 14)

            // Google 快捷注册按钮
            GoogleLoginButton(
                title: "使用 Google 账号快捷注册",
                isLoading: false,
                action: onGoogleRegister
            )
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}
