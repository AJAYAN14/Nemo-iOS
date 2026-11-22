//
//  NemoSheetCloseButton.swift
//  Nemo
//
//  Created by Nemo Team on 2026-11-22.
//

import SwiftUI

/// 原生标准导航栏关闭按钮
///
/// 遵循苹果原生 NavigationBar 规范，采用纯血原生 Label 图标按钮，
/// 交由系统自动处理触控高亮反馈、原生图标渲染与无障碍标签，杜绝任何人工手写背景圆圈。
public struct NemoSheetCloseButton: View {
    private let dismiss: () -> Void

    /// 初始化关闭按钮
    /// - Parameter dismiss: 点击关闭时的回调闭包
    public init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
    }

    public var body: some View {
        Button(action: dismiss) {
            Label("关闭", systemImage: "xmark")
        }
        .labelStyle(.iconOnly)
        .accessibilityLabel("关闭")
    }
}
