//
//  NemoPressableButtonStyle.swift
//  Nemo
//

import SwiftUI

/// Nemo 通用轻触动效按钮样式
/// 为自定义卡片与胶囊按钮提供符合 Apple HIG 的按压反馈与触感缩放动效
public struct NemoPressableButtonStyle: ButtonStyle {
    private let pressedScale: CGFloat
    private let pressedOpacity: Double

    public init(pressedScale: CGFloat = 0.98, pressedOpacity: Double = 0.85) {
        self.pressedScale = pressedScale
        self.pressedOpacity = pressedOpacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}

public extension ButtonStyle where Self == NemoPressableButtonStyle {
    static var nemoPressable: NemoPressableButtonStyle {
        NemoPressableButtonStyle()
    }
}

/// 遵循 Apple HIG 规范的主交互行动按钮样式（Primary Interactive Button）
/// 严格对齐苹果原生锁屏/控制中心同款弹簧物理学（interpolatingSpring），
/// 在手指触碰按下时产生深度微暗（-0.06 brightness）与触觉马达物理交汇，杜绝伪流光干扰。
public struct NemoPrimaryInteractiveButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0.0)
            .animation(.interpolatingSpring(mass: 1.0, stiffness: 350, damping: 25), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .medium), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}

public extension ButtonStyle where Self == NemoPrimaryInteractiveButtonStyle {
    static var nemoPrimaryInteractive: NemoPrimaryInteractiveButtonStyle {
        NemoPrimaryInteractiveButtonStyle()
    }
}

/// 遵循 Apple HIG 规范并 100% 复用 Clash-Client 的主行动按钮修饰符
/// 在 iOS 26+/27 系统上原生支持苹果官方 .glassProminent 液态玻璃材质，旧版本优雅降级为 .borderedProminent
public extension View {
    func nemoPrimaryActionButtonStyle() -> AnyView {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, *) {
            return AnyView(buttonStyle(.glassProminent))
        }
        return AnyView(buttonStyle(.borderedProminent))
    }

    @ViewBuilder
    func nemoCapsuleButtonBorderShape() -> some View {
        #if os(macOS)
        if #available(macOS 14.0, *) {
            buttonBorderShape(.capsule)
        } else {
            self
        }
        #else
        buttonBorderShape(.capsule)
        #endif
    }
}

