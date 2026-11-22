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
}
