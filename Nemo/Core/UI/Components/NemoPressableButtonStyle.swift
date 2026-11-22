//
//  NemoPressableButtonStyle.swift
//  Nemo
//

import SwiftUI

/// 通用轻触动效按钮样式
///
/// 为自定义卡片与胶囊按钮提供符合 Apple HIG 的按压缩放反馈与轻触觉动效。
public struct NemoPressableButtonStyle: ButtonStyle {
    private let pressedScale: CGFloat
    private let pressedOpacity: Double

    /// 初始化轻触反馈按钮样式
    /// - Parameters:
    ///   - pressedScale: 按下时的微缩比例，默认值为 0.98
    ///   - pressedOpacity: 按下时的透明度，默认值为 0.85
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
    /// 通用轻触动效样式便捷访问器
    static var nemoPressable: NemoPressableButtonStyle {
        NemoPressableButtonStyle()
    }
}

/// 核心主交互行动按钮样式
///
/// 遵循 Apple 物理动效设计，按下时产生细微明度加深（-0.06 brightness）与触觉马达反馈。
public struct NemoPrimaryInteractiveButtonStyle: ButtonStyle {
    /// 初始化主行动按钮样式
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
    /// 核心主交互行动按钮样式便捷访问器
    static var nemoPrimaryInteractive: NemoPrimaryInteractiveButtonStyle {
        NemoPrimaryInteractiveButtonStyle()
    }
}
