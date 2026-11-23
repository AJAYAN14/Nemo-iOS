import SwiftUI

/// 列表项入场动效修饰符（100% 对齐 Android `animateListItem` 规范）。
/// 在单元格首次滑入视野或挂载时驱动一次淡入、微缩放与上移弹簧动效，完成后保持常态。
public struct ListItemEntranceModifier: ViewModifier {
    @State private var hasAppeared: Bool = false

    public init() {}

    public func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1.0 : 0.08)
            .scaleEffect(hasAppeared ? 1.0 : 0.90)
            .offset(y: hasAppeared ? 0 : 18)
            .onAppear {
                guard !hasAppeared else { return }
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    hasAppeared = true
                }
            }
    }
}

public extension View {
    /// 为列表项添加平滑弹簧入场动效（淡入 + 0.90 缩放 + 18pt 上移弹簧）
    func animateListItem() -> some View {
        modifier(ListItemEntranceModifier())
    }
}
