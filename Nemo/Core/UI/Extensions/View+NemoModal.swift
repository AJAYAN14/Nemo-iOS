//
//  View+NemoModal.swift
//  Nemo
//
//  Created by Nemo Team on 2026-11-22.
//

import SwiftUI

/// 模态视窗自适应展示角色类型
public enum NemoModalRole: Sendable {
    /// 页面级全高自适应模态
    case page
    /// 表单级自适应模态
    case form
    /// 紧凑贴合内容模态
    case fitted
}

public extension View {
    /// 统一模态弹窗自适应 Presentation 规范
    ///
    /// 适配 iOS 18+ 原生 presentationSizing，低版本系统保持系统原生全屏 Page Sheet 卡片。
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

    /// 标准抽屉视窗外观修饰
    ///
    /// 隐藏顶部拖拽横杠，完全继承苹果原生 Sheet 系统自适应硬件大圆角。
    @ViewBuilder
    func nemoSheetSurface() -> some View {
        self
            .presentationDragIndicator(.hidden)
    }

    /// 统一标准抽屉导航容器包裹
    /// - Parameters:
    ///   - title: 抽屉内联标题
    ///   - onClose: 点击左上角关闭按钮时的回调闭包
    func nemoSheetContainer(title: String, onClose: @escaping () -> Void) -> some View {
        NavigationStack {
            self
                .navigationTitle(title)
                .nemoInlinePageTitle()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        NemoSheetCloseButton(dismiss: onClose)
                    }
                }
                .nemoTransparentNavigationBar()
        }
        .nemoModalPresentation(.page)
        .nemoSheetSurface()
    }

    /// 内联导航栏标题修饰符
    @ViewBuilder
    func nemoInlinePageTitle() -> some View {
        if #available(iOS 17.0, *) {
            self.toolbarTitleDisplayMode(.inline)
        } else {
            self.navigationBarTitleDisplayMode(.inline)
        }
    }

    /// 表单顶部紧凑边距修饰符
    @ViewBuilder
    func nemoConfigurationFormSpacing() -> some View {
        if #available(iOS 17.0, *) {
            self.listSectionSpacing(16)
                .contentMargins(.top, 4, for: .scrollContent)
        } else {
            self
        }
    }

    /// 导航栏背景完全透明穿透修饰符
    ///
    /// 页面向上滑动时导航栏背景保持全透明，彻底消除系统默认的毛玻璃材质与分割线遮罩。
    @ViewBuilder
    func nemoTransparentNavigationBar() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbarBackground(.hidden, for: .navigationBar)
                .background(NemoTransparentNavBarHelper())
        } else {
            self
        }
    }
}

/// 导航栏透明外观注入辅助器（彻底消除滚动时系统默认激活的毛玻璃与分割线）
private struct NemoTransparentNavBarHelper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let navigationBar = uiViewController.navigationController?.navigationBar else { return }
            let transparentAppearance = UINavigationBarAppearance()
            transparentAppearance.configureWithTransparentBackground()
            transparentAppearance.backgroundColor = .clear
            transparentAppearance.shadowColor = .clear
            transparentAppearance.backgroundEffect = nil

            navigationBar.standardAppearance = transparentAppearance
            navigationBar.scrollEdgeAppearance = transparentAppearance
            navigationBar.compactAppearance = transparentAppearance
        }
    }
}
