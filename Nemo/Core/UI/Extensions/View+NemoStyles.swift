//
//  View+NemoStyles.swift
//  Nemo
//

import SwiftUI

public extension View {
    /// 全局主行动按钮外观修饰符
    ///
    /// 在高版本系统上启用系统级原生材质（如 .glassProminent），其他系统版本自适应降级为原生带边框高亮样式（.borderedProminent）。
    func nemoPrimaryActionButtonStyle() -> AnyView {
        if #available(iOS 26.0, *) {
            return AnyView(buttonStyle(.glassProminent))
        }
        return AnyView(buttonStyle(.borderedProminent))
    }

    /// 全局胶囊型按钮外框形状修饰符
    @ViewBuilder
    func nemoCapsuleButtonBorderShape() -> some View {
        buttonBorderShape(.capsule)
    }

    /// 全局顶部导航栏与状态容器边缘渐变过渡模糊修饰符
    ///
    /// 在 iOS 26+ 环境下启用原生 Liquid Glass 柔和渐变边缘效果，内容向上滚动经过顶部导航栏时呈现平滑羽化的毛玻璃过渡遮罩；
    /// 在早期系统版本上自动优雅降级，维持系统标准材质与滚动边缘外观。
    @ViewBuilder
    func nemoTopAppBarEffect() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}
