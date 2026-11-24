import SwiftUI

/// 认证两段式流程的欢迎封面视图
public struct AuthWelcomeView: View {
    public var onNavigateToLogin: () -> Void
    public var onNavigateToRegister: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        onNavigateToLogin: @escaping () -> Void,
        onNavigateToRegister: @escaping () -> Void
    ) {
        self.onNavigateToLogin = onNavigateToLogin
        self.onNavigateToRegister = onNavigateToRegister
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

    private var secondaryButtonBg: Color {
        isDark ? Color.white.opacity(0.08) : Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.06)
    }

    private var secondaryButtonTextColor: Color {
        isDark ? Color.white.opacity(0.90) : Color(red: 0.06, green: 0.09, blue: 0.16)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 大标题
            Text("在流动之间，\n精准掌握日语。")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(titleTextColor)
                .lineSpacing(6)
                .tracking(-0.5)

            Spacer().frame(height: 14)

            // 副标题说明
            Text("Nemo 将沉浸式语言美学与 FSRS 科学记忆算法融合，助您轻松攻克假名、词汇、语法与动词变形。")
                .font(.system(size: 14))
                .foregroundStyle(descTextColor)
                .lineSpacing(4)

            Spacer().frame(height: 28)

            // 主操作大按钮：登录账号 >
            Button(action: onNavigateToLogin) {
                HStack(spacing: 4) {
                    Text("登录账号")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
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
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: Color(red: 0.15, green: 0.39, blue: 0.96).opacity(0.35),
                    radius: 12,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(NemoPressableButtonStyle())

            Spacer().frame(height: 12)

            // 次操作按钮：注册新账号
            Button(action: onNavigateToRegister) {
                Text("注册新账号")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(secondaryButtonTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(secondaryButtonBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(NemoPressableButtonStyle())
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}
