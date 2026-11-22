//
//  View+NemoModal.swift
//  Nemo
//
//  Created by Nemo Team on 2026-11-22.
//

import SwiftUI

/// 抽屉模态角色类型（严格对齐 Clash 客户端规范）
public enum NemoModalRole: Sendable {
    /// 页面级全高/半高自适应抽屉
    case page
    /// 表单级抽屉
    case form
    /// 紧凑贴合内容抽屉
    case fitted
}

public extension View {
    /// 统一抽屉弹窗自适应 Presentation 规范（严格对齐 Clash 客户端规范）
    ///
    /// 对齐现代 iOS 18+ 原生 presentationSizing，非 iOS 18 保持系统原生全屏 Page Sheet 卡片。
    @ViewBuilder
    func nemoModalPresentation(_ role: NemoModalRole = .page) -> some View {
        if #available(iOS 18.0, *) {
            switch role {
            case .page:
                self.presentationSizing(.page)
            case .form:
                self.presentationSizing(.form)
            case .fitted:
                self.presentationSizing(.fitted)
            }
        } else {
            self
        }
    }

    /// 标准抽屉视窗外观修饰（严格对齐 Clash 规范，彻底隐藏顶部拖拽横杠）
    ///
    /// 包含隐藏系统拖拽横杠胶囊、连续曲率圆角与背景适配。
    /// - Parameter cornerRadius: 抽屉顶部圆角半径，默认 24pt
    @ViewBuilder
    func nemoSheetSurface(cornerRadius: CGFloat = 24) -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(cornerRadius)
        } else {
            self
                .presentationDragIndicator(.hidden)
        }
    }

    /// 统一标准抽屉导航容器包裹
    /// - Parameters:
    ///   - title: 抽屉内联标题
    ///   - onClose: 点击左上角关闭按钮时的回调闭包
    func nemoSheetContainer(title: String, onClose: @escaping () -> Void) -> some View {
        NavigationStack {
            self
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        NemoSheetCloseButton(dismiss: onClose)
                    }
                }
        }
        .nemoModalPresentation(.page)
        .nemoSheetSurface()
    }
}
