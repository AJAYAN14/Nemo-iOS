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

    /// 全局认证与会话状态中枢
    @State private var authStore = AuthStore()

    /// 控制启动开屏动画的完成状态
    @State private var isSplashAnimationFinished: Bool = false

    /// 是否应保持开屏保护罩遮挡（等待动画播放完毕且会话完成解析）
    private var isCoverActive: Bool {
        !authStore.isSessionResolved || !isSplashAnimationFinished
    }

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
                // 1. 核心导航守卫：仅当会话解析完成且已登录，才挂载主界面
                if authStore.shouldShowMainInterface {
                    ContentView()
                        .transition(.opacity)
                } else if authStore.shouldShowAuthentication {
                    // 未登录/未注册状态：全屏展示登录流程，严禁挂载主界面与底栏
                    LoginScreenView()
                        .transition(.opacity)
                }

                // 2. 启动开屏保护罩：在动效未完成或会话未解析时保持全屏遮挡
                if isCoverActive {
                    NemoSplashView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isSplashAnimationFinished = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .environment(authStore)
            .task {
                // 启动生命周期并发任务：会话解析 + 词库同步 + 权限/网络探针
                async let sessionResolution: () = authStore.resolveSession()
                async let startupDataSync: () = AppStartupManager.shared.performStartupSync()
                async let permissions: () = SystemPermissionCoordinator.shared.requestStartupPermissionsAndProbeNetwork()
                _ = await (sessionResolution, startupDataSync, permissions)
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
