//
//  NemoTabBarFollowsThePush.swift
//  Nemo
//
//

import SwiftUI
import UIKit

/// 100% 对齐参考项目 Clash 原生架构（ClashTabBarFollowsThePush）
///
/// 通过透明的 UIViewControllerRepresentable 探针：
/// 1. 在二级页面推入时隐藏底栏，返回时恢复底栏；
/// 2. 精确联动 UITabBarController.setTabBarHidden，消除边缘手势下的闪烁；
/// 3. 在自定义返回按钮导致系统手势被禁用的情况下，恢复 interactivePopGestureRecognizer 边缘侧滑返回手势。
public struct NemoTabBarFollowsThePush: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context: Context) -> Probe { Probe() }
    public func updateUIViewController(_ probe: Probe, context: Context) {}

    public final class Probe: UIViewController, UIGestureRecognizerDelegate {
        public override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
            view.isHidden = true
        }

        public override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            setTabBarHidden(true, animated: animated)
            setupInteractivePopGesture()
        }

        public override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            setTabBarHidden(false, animated: animated)
        }

        private func setTabBarHidden(_ hidden: Bool, animated: Bool) {
            guard let tabs = tabBarController, tabs.isTabBarHidden != hidden else { return }
            tabs.setTabBarHidden(hidden, animated: animated)
        }

        private func setupInteractivePopGesture() {
            guard let nav = navigationController else { return }
            nav.interactivePopGestureRecognizer?.isEnabled = true
            nav.interactivePopGestureRecognizer?.delegate = self
        }

        public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let nav = navigationController else { return false }
            return nav.viewControllers.count > 1
        }
    }
}
