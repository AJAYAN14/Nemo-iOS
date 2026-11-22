//
//  ContentView.swift
//  Nemo
//

import SwiftUI

/// 顶层导航栏标签项类型枚举
public enum AppTab: String, Hashable, CaseIterable, Identifiable {
    /// 学习主页
    case learning
    /// 进度分析
    case progress
    /// 能力测试
    case test
    /// 个人中心与设置
    case settings

    public var id: String { rawValue }

    /// 标签项本地化显示标题
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

    /// 标签项对应的 SF Symbols 图标名称
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

    /// 兼容性系统图标名称别名
    public var systemImage: String { iconName }
    /// 兼容性图标名称别名
    public var icon: String { iconName }
}

/// 应用顶层根视图
///
/// 包含四个核心功能模块的 TabView 容器并维护当前选中的导航分支。
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
