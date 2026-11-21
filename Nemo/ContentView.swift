//
//  ContentView.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 顶层导航 Tab 类型安全枚举
public enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case learning
    case progress
    case test
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .learning:
            return "主页"
        case .progress:
            return "进度"
        case .test:
            return "测试"
        case .settings:
            return "个人"
        }
    }

    public var iconName: String {
        switch self {
        case .learning:
            return "house.fill"
        case .progress:
            return "chart.bar.fill"
        case .test:
            return "sparkles"
        case .settings:
            return "person.crop.circle.fill"
        }
    }

    public var systemImage: String { iconName }
    public var icon: String { iconName }
}

/// 顶层主界面视图
public struct ContentView: View {
    @State private var selectedTab: AppTab = .learning

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LearningHomeView()
            }
            .tabItem {
                Label(AppTab.learning.title, systemImage: AppTab.learning.iconName)
            }
            .tag(AppTab.learning)

            NavigationStack {
                ProgressHomeView()
            }
            .tabItem {
                Label(AppTab.progress.title, systemImage: AppTab.progress.iconName)
            }
            .tag(AppTab.progress)

            NavigationStack {
                TestHomeView()
            }
            .tabItem {
                Label(AppTab.test.title, systemImage: AppTab.test.iconName)
            }
            .tag(AppTab.test)

            NavigationStack {
                SettingsHomeView()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.iconName)
            }
            .tag(AppTab.settings)
        }
    }
}

#Preview {
    ContentView()
}
