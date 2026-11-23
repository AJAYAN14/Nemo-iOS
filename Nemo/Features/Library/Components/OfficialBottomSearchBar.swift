import SwiftUI

/// 100% 像素级还原 iOS 官方底层悬浮搜索栏交互与视觉规范。
/// 
/// - 未激活态：底部全宽毛玻璃悬浮胶囊，内嵌粗体放大镜与“搜索”占位文本，浮动于底部安全区上方；
/// - 激活聚焦态：跟随软键盘平滑升起，输入胶囊自适应收窄，右侧以弹簧动效独立滑出 50pt 圆形“✕”退出按钮。
public struct OfficialBottomSearchBar: View {
    @Binding public var text: String
    public let placeholder: String
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String = "搜索") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack(spacing: 10) {
            // 左侧：主搜索胶囊
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)

                TextField(placeholder, text: $text)
                    .font(.system(size: 17, weight: .medium))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                // 输入框内快速清空小圆标（有文字输入且聚焦时出现）
                if !text.isEmpty && isFocused {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .contentShape(Capsule())
            .onTapGesture {
                if !isFocused {
                    isFocused = true
                }
            }
            .background(
                Capsule()
                    .fill(Color(uiColor: .systemBackground).opacity(0.88))
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 3)
            )
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )

            // 右侧：获得焦点时独立滑出的圆形“✕”关闭退出按钮（完全对齐官方真机截屏）
            if isFocused {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isFocused = false
                        text = ""
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .systemBackground).opacity(0.88))
                            .background(.regularMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 3)

                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)

                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .frame(width: 50, height: 50)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.6).combined(with: .opacity),
                    removal: .scale(scale: 0.6).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFocused)
    }
}
