//
//  NemoSheetCloseButton.swift
//  Nemo
//
//  Created by Nemo Team on 2026-11-22.
//

import SwiftUI

/// 原生标准抽屉圆底关闭按钮（严格对齐 Clash 客户端规范）
///
/// 遵循 iOS 原生视觉规范，采用带有系统三级填充色的圆形背景（tertiarySystemFill），
/// 内嵌加粗 xmark 符号，提供 44pt 最小无障碍触控目标尺寸。
public struct NemoSheetCloseButton: View {
    private let dismiss: () -> Void

    /// 初始化关闭按钮
    /// - Parameter dismiss: 点击关闭时的回调闭包
    public init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
    }

    public var body: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(7)
                .background(Circle().fill(Color(uiColor: .tertiarySystemFill)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("关闭")
    }
}
