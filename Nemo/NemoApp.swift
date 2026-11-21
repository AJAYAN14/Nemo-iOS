//
//  NemoApp.swift
//  Nemo
//
//  Created by AJIAN on 2026/11/21.
//

import SwiftUI

@main
struct NemoApp: App {
    @AppStorage("settings_dark_mode_option") private var storedDarkMode: String = "auto"
    @AppStorage("settings_auto_strategy") private var storedAutoStrategy: String = "follow_system"
    @AppStorage("settings_dark_start_time") private var darkModeStartTime: String = "21:00"
    @AppStorage("settings_dark_end_time") private var darkModeEndTime: String = "07:00"

    private var currentColorScheme: ColorScheme? {
        if storedDarkMode == "light" {
            return .light
        } else if storedDarkMode == "dark" {
            return .dark
        } else {
            // "auto" 模式
            if storedAutoStrategy == "scheduled" {
                return isCurrentTimeInDarkWindow() ? .dark : .light
            }
            // "follow_system" - 返回 nil 遵从 iOS 系统外观 (Apple HIG 规范)
            return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(currentColorScheme)
        }
    }

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
            // 跨天情况，如 21:00 到 07:00
            return currentTotal >= startTotal || currentTotal < endTotal
        }
    }
}
