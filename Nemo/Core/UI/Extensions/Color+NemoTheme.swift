//
//  Color+NemoTheme.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public extension Color {
    /// 全局系统一级分组背景语义色
    ///
    /// 遵循 Apple HIG 规范，浅色模式呈现浅灰（#F2F2F7），深色模式呈现纯黑（#000000）。
    static var nemoGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color.gray.opacity(0.12)
        #endif
    }

    /// 全局系统二级分组背景语义色（卡片与容器主体底色）
    ///
    /// 浅色模式呈现纯白（#FFFFFF），深色模式呈现深层抬升灰（#1C1C1E）。
    static var nemoSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color.white
        #endif
    }

    /// 全局系统三级分组背景语义色（徽章与微缩容器底色）
    static var nemoTertiaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        Color.gray.opacity(0.2)
        #endif
    }

    // MARK: - 启动屏品牌语义调色盘（纯正原生高保真）

    /// 启动屏深海呼吸环境光晕深海蓝
    static let nemoSplashGlowSky = Color(red: 0x0E / 255.0, green: 0xA5 / 255.0, blue: 0xE9 / 255.0)
    /// 启动屏深海呼吸环境光晕青绿
    static let nemoSplashGlowTeal = Color(red: 0x2D / 255.0, green: 0xD4 / 255.0, blue: 0xBF / 255.0)
    /// 启动屏浅色模式天蓝光晕
    static let nemoSplashGlowLightBlue = Color(red: 0x38 / 255.0, green: 0xBD / 255.0, blue: 0xF8 / 255.0)
    /// 启动屏浅色模式柔橙光晕
    static let nemoSplashGlowOrange = Color(red: 0xFB / 255.0, green: 0x92 / 255.0, blue: 0x3C / 255.0)

    /// 启动屏漂浮装饰玫瑰粉心形
    static let nemoSplashShapeRose = Color(red: 0xFB / 255.0, green: 0x71 / 255.0, blue: 0x85 / 255.0)
    /// 启动屏漂浮装饰浅紫心形
    static let nemoSplashShapeViolet = Color(red: 0xA7 / 255.0, green: 0x8B / 255.0, blue: 0xFA / 255.0)
    /// 启动屏漂浮装饰明蓝圆角块
    static let nemoSplashShapeBlue = Color(red: 0x60 / 255.0, green: 0xA5 / 255.0, blue: 0xFA / 255.0)
}
