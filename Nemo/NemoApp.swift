//
//  NemoApp.swift
//  Nemo
//

import SwiftUI

/// Nemo iOS 应用程序入口
///
/// 负责全局窗口构建与外观模式（深浅色调度）的统一生命周期管理。
@main
struct NemoApp: App {
    @AppStorage("settings_dark_mode_option") private var storedDarkMode: String = "auto"
    @AppStorage("settings_auto_strategy") private var storedAutoStrategy: String = "follow_system"
    @AppStorage("settings_dark_start_time") private var darkModeStartTime: String = "21:00"
    @AppStorage("settings_dark_end_time") private var darkModeEndTime: String = "07:00"

    /// 控制启动开屏动画的生命周期展示状态
    @State private var isSplashActive: Bool = true

    /// 当前生效的全局颜色外观配置
    ///
    /// 当设为自动跟随系统时返回 `nil`，交由系统级外观调度；当设为自定时段时根据时间窗口计算返回 `.dark` 或 `.light`。
    private var currentColorScheme: ColorScheme? {
        if storedDarkMode == "light" {
            return .light
        } else if storedDarkMode == "dark" {
            return .dark
        } else {
            if storedAutoStrategy == "scheduled" {
                return isCurrentTimeInDarkWindow() ? .dark : .light
            }
            return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(isSplashActive ? 0.0 : 1.0)

                if isSplashActive {
                    NemoSplashView {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            isSplashActive = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .preferredColorScheme(currentColorScheme)
            .animation(.easeInOut(duration: 0.35), value: currentColorScheme)
        }
    }

    /// 校验当前本地系统时间是否处于用户设定的深色时间窗口内
    /// - Returns: 若在深色时段内则返回 `true`，否则返回 `false`
    private func isCurrentTimeInDarkWindow() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotal = currentHour * 60 + currentMinute

        let startParts = darkModeStartTime.split(separator: ":").compactMap { Int($0) }
        let endParts = darkModeEndTime.split(separator: ":").compactMap { Int($0) }

        guard startParts.count == 2, endParts.count == 2 else { return false }
        let startTotal = startParts[0] * 60 + startParts[1]
        let endTotal = endParts[0] * 60 + endParts[1]

        if startTotal < endTotal {
            return currentTotal >= startTotal && currentTotal < endTotal
        } else {
            // 处理跨午夜时段（例如 21:00 至次日 07:00）
            return currentTotal >= startTotal || currentTotal < endTotal
        }
    }
}
