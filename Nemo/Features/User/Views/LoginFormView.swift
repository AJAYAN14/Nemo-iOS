import SwiftUI

/// 登录表单视图
public struct LoginFormView: View {
    @Binding public var email: String
    @Binding public var password: String
    @Binding public var isPasswordVisible: Bool
    public var isLoading: Bool
    public var emailError: Bool
    public var passwordError: Bool
    public var onLogin: () -> Void
    public var onNavigateToRegister: () -> Void
    public var onForgotPassword: () -> Void
    public var onGoogleLogin: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        email: Binding<String>,
        password: Binding<String>,
        isPasswordVisible: Binding<Bool>,
        isLoading: Bool,
        emailError: Bool = false,
        passwordError: Bool = false,
        onLogin: @escaping () -> Void,
        onNavigateToRegister: @escaping () -> Void,
        onForgotPassword: @escaping () -> Void,
        onGoogleLogin: @escaping () -> Void
    ) {
        self._email = email
        self._password = password
        self._isPasswordVisible = isPasswordVisible
        self.isLoading = isLoading
        self.emailError = emailError
        self.passwordError = passwordError
        self.onLogin = onLogin
        self.onNavigateToRegister = onNavigateToRegister
        self.onForgotPassword = onForgotPassword
        self.onGoogleLogin = onGoogleLogin
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

    private var secondaryButtonBg: Color {
        isDark ? Color.white.opacity(0.08) : Color.white
    }

    private var secondaryButtonTextColor: Color {
        isDark ? Color.white.opacity(0.90) : Color(red: 0.12, green: 0.16, blue: 0.24)
    }

    private var dividerColor: Color {
        isDark ? Color.white.opacity(0.10) : Color(red: 0.88, green: 0.91, blue: 0.94)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题行：左侧标题与副标题，右侧【去注册】胶囊切换
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("欢迎回来")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(titleTextColor)
                        .tracking(-0.5)

                    Text("使用邮箱密码或 Google 账号继续")
                        .font(.system(size: 13))
                        .foregroundStyle(descTextColor)
                }

                Spacer()

                Button(action: onNavigateToRegister) {
                    Text("去注册")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(capsuleTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(capsuleBg)
                        .clipShape(Capsule())
                }
                .buttonStyle(NemoPressableButtonStyle())
            }

            Spacer().frame(height: 24)

            // 输入框区域
            VStack(spacing: 14) {
                AuthTextField(
                    text: $email,
                    placeholder: "电子邮箱地址",
                    systemImage: "envelope",
                    isError: emailError,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )

                AuthTextField(
                    text: $password,
                    placeholder: "输入登录密码",
                    systemImage: "lock",
                    isSecure: true,
                    isPasswordVisible: $isPasswordVisible,
                    isError: passwordError,
                    textContentType: .password,
                    onSubmit: onLogin
                )
            }

            Spacer().frame(height: 16)

            // 核心横向双按钮行：【忘记密码】(权重 1.0) 与【立即登录 >】(权重 1.35)
            GeometryReader { geometry in
                let spacing: CGFloat = 12
                let totalAvailableWidth = max(0, geometry.size.width - spacing)
                let leftWidth = totalAvailableWidth * (1.0 / 2.35)
                let rightWidth = totalAvailableWidth * (1.35 / 2.35)

                HStack(spacing: spacing) {
                    // 左侧：忘记密码 (权重 1.0)
                    Button(action: onForgotPassword) {
                        Text("忘记密码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(secondaryButtonTextColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(secondaryButtonBg)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(isDark ? Color.white.opacity(0.10) : Color(red: 0.88, green: 0.91, blue: 0.94), lineWidth: 1)
                            )
                    }
                    .buttonStyle(NemoPressableButtonStyle())
                    .frame(width: leftWidth)

                    // 右侧：立即登录 > (权重 1.35)
                    Button(action: onLogin) {
                        HStack(spacing: 4) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 18, height: 18)
                            } else {
                                Text("立即登录")
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
                    .frame(width: rightWidth)
                    .disabled(isLoading)
                }
            }
            .frame(height: 52)

            Spacer().frame(height: 16)

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

            Spacer().frame(height: 16)

            // Google 快捷登录按钮
            GoogleLoginButton(
                title: "使用 Google 账号登录",
                isLoading: false,
                action: onGoogleLogin
            )
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}
