import SwiftUI

/// 词库列表通用磨砂玻璃回顶悬浮按钮（100% 对齐 Android `LibraryScrollToTopButton` 交互与视觉规范）。
public struct LibraryScrollToTopButton: View {
    public let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)

                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)

                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.6).combined(with: .opacity),
            removal: .scale(scale: 0.6).combined(with: .opacity)
        ))
    }
}
