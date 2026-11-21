//
//  ThemeSettingsView.swift
//  Nemo
//
//  Created by AJIAN on 2026/11/22.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 8 款专为 Apple 打造的高清流体玻璃图标选项
public enum AppIconOption: String, CaseIterable, Identifiable {
    case blue = "Apple-blue"
    case black = "Apple-black"
    case green = "Apple-green"
    case orange = "Apple-orange"
    case pink = "Apple-pink"
    case purple = "Apple-purple"
    case red = "Apple-red"
    case yellow = "Apple-yellow"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .blue: return "旗舰冰蓝"
        case .black: return "黑曜透亮"
        case .green: return "薄荷翠绿"
        case .orange: return "鲜活亮橙"
        case .pink: return "樱花透粉"
        case .purple: return "赛博幻紫"
        case .red: return "珊瑚暖红"
        case .yellow: return "璨金阳光"
        }
    }

    public var subtitle: String {
        switch self {
        case .blue: return "对齐 Android 原生默认"
        case .black: return "黑曜石通透高光"
        case .green: return "薄荷翠绿微光"
        case .orange: return "明快活力橙"
        case .pink: return "轻盈樱粉晶莹"
        case .purple: return "赛博流体幻紫"
        case .red: return "热烈珊瑚红"
        case .yellow: return "温暖璨金阳光"
        }
    }

    public var colorKey: String {
        switch self {
        case .blue: return "blue"
        case .black: return "black"
        case .green: return "green"
        case .orange: return "orange"
        case .pink: return "pink"
        case .purple: return "purple"
        case .red: return "red"
        case .yellow: return "yellow"
        }
    }

    public var previewImageName: String {
        "AppIconPreview-\(colorKey)"
    }

    public var alternateIconName: String? {
        if self == .blue { return nil }
        return "AppIcon-\(colorKey)"
    }

    public var accentColor: Color {
        switch self {
        case .blue: return Color.blue
        case .black: return Color.primary
        case .green: return Color.green
        case .orange: return Color.orange
        case .pink: return Color.pink
        case .purple: return Color.purple
        case .red: return Color.red
        case .yellow: return Color.yellow
        }
    }
}

// MARK: - 主题强调色枚举
public enum ThemeAccentColorOption: String, CaseIterable, Identifiable {
    case green = "薄荷绿"
    case orange = "活力橙"
    case blue = "旗舰蓝"
    case purple = "赛博紫"
    case pink = "樱花粉"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .green: return Color.green
        case .orange: return Color.orange
        case .blue: return Color.blue
        case .purple: return Color.purple
        case .pink: return Color.pink
        }
    }
}

// MARK: - 设置图标风格枚举
public enum SettingIconStyleOption: String, CaseIterable, Identifiable {
    case softTranslucent = "柔和半透"
    case vibrantSolid = "鲜活纯色"

    public var id: String { rawValue }
}

// MARK: - 主题与外观视图
public struct ThemeSettingsView: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss

    // 存储与状态
    @AppStorage("settings_dark_mode_option") private var storedDarkMode: String = "auto"
    @AppStorage("settings_auto_strategy") private var storedAutoStrategy: String = "follow_system"
    @AppStorage("settings_dark_start_time") private var darkModeStartTime: String = "21:00"
    @AppStorage("settings_dark_end_time") private var darkModeEndTime: String = "07:00"
    @AppStorage("settings_theme_accent") private var storedAccentColor: String = "薄荷绿"
    @AppStorage("settings_icon_style") private var storedIconStyle: String = "柔和半透"
    @AppStorage("settings_app_icon_option") private var storedAppIcon: String = "Apple-blue"

    // 局部交互状态
    @State private var isAutoSwitch: Bool = true
    @State private var selectedAppIcon: AppIconOption = .blue
    @State private var selectedAccent: ThemeAccentColorOption = .green
    @State private var selectedIconStyle: SettingIconStyleOption = .softTranslucent

    public init() {}

    private var isDarkEffective: Bool {
        if isAutoSwitch {
            return systemColorScheme == .dark
        }
        return storedDarkMode == "dark"
    }

    private var currentAccentColor: Color {
        selectedAccent.color
    }

    public var body: some View {
        List {
            // MARK: 1. 外观显示模式 (遵循 Apple HIG 标准)
            Section {
                VStack(spacing: 14) {
                    // 真实 iPhone 宽高比浅色/深色机身微缩预览
                    HStack(spacing: 28) {
                        Spacer()
                        themeModePreviewCard(
                            title: "浅色",
                            isDark: false,
                            isSelected: !isDarkEffective
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isAutoSwitch = false
                                storedDarkMode = "light"
                            }
                        }

                        themeModePreviewCard(
                            title: "深色",
                            isDark: true,
                            isSelected: isDarkEffective
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isAutoSwitch = false
                                storedDarkMode = "dark"
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                // 自动切换开关 (Apple HIG 标准交互)
                Toggle(isOn: $isAutoSwitch.animation(.easeInOut(duration: 0.2))) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("自动")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("遵从 iOS 系统外观或根据自定时段自动切换")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(currentAccentColor)
                .onChange(of: isAutoSwitch) { auto in
                    if auto {
                        storedDarkMode = "auto"
                    } else {
                        storedDarkMode = isDarkEffective ? "dark" : "light"
                    }
                }

                // 自动模式下的切换策略
                if isAutoSwitch {
                    Picker("选项", selection: $storedAutoStrategy) {
                        Text("跟随系统").tag("follow_system")
                        Text("自定时段").tag("scheduled")
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    if storedAutoStrategy == "scheduled" {
                        HStack {
                            Label("深色开始时间", systemImage: "moon.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(darkModeStartTime)
                                .font(.subheadline.bold())
                                .foregroundStyle(currentAccentColor)
                        }

                        HStack {
                            Label("深色结束时间", systemImage: "sun.max.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(darkModeEndTime)
                                .font(.subheadline.bold())
                                .foregroundStyle(currentAccentColor)
                        }
                    }
                }
            } header: {
                Text("外观")
            } footer: {
                Text("开启“自动”后，应用将始终与 iOS 系统设定的日出日落或全局外观偏好保持一致。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // MARK: 2. 个性化定制 (Customization)
            Section {
                // 主题强调色
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("主题色彩")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedAccent.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        ForEach(ThemeAccentColorOption.allCases) { opt in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedAccent = opt
                                    storedAccentColor = opt.rawValue
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(opt.color)
                                        .frame(width: 36, height: 36)

                                    if selectedAccent == opt {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
                .padding(.vertical, 4)

                // 设置项图标风格 (已去除重复的“图标风格”文字)
                HStack {
                    Text("设置项图标风格")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker("", selection: $selectedIconStyle) {
                        ForEach(SettingIconStyleOption.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedIconStyle) { newStyle in
                        storedIconStyle = newStyle.rawValue
                    }
                }
            } header: {
                Text("个性化定制")
            }

            // MARK: 3. 应用桌面图标 (App Desktop Icon - 核心 8 款)
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(AppIconOption.allCases) { opt in
                                appIconItemView(opt)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
            } header: {
                Text("应用桌面图标")
            } footer: {
                Text("提供 8 款专为 Apple 设计的 Squircle 流体玻璃高光图标，默认对齐 Android 旗舰蓝。点击可实时在桌面生效。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("主题与外观")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar) // 子界面隐藏底部导航栏，仅在四个主界面显示
        .onAppear {
            #if canImport(UIKit)
            if let currentAlternate = UIApplication.shared.alternateIconName {
                if let match = AppIconOption.allCases.first(where: { $0.alternateIconName == currentAlternate }) {
                    selectedAppIcon = match
                }
            } else {
                selectedAppIcon = .blue
            }
            #else
            if let savedOpt = AppIconOption(rawValue: storedAppIcon) {
                selectedAppIcon = savedOpt
            }
            #endif

            if let savedAccent = ThemeAccentColorOption(rawValue: storedAccentColor) {
                selectedAccent = savedAccent
            }
            if let savedIconStyle = SettingIconStyleOption(rawValue: storedIconStyle) {
                selectedIconStyle = savedIconStyle
            }
            isAutoSwitch = (storedDarkMode == "auto")
        }
    }

    // MARK: - 主题模式微缩 iPhone 预览卡片 (符合 Apple HIG 规范与真实 iPhone 比例)
    @ViewBuilder
    private func themeModePreviewCard(
        title: String,
        isDark: Bool,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 1. iPhone 手机微缩外壳 (真实 9:19.5 宽高比)
                ZStack {
                    // 选中状态高亮外轮廓
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            isSelected ? currentAccentColor : Color.clear,
                            lineWidth: 2.5
                        )
                        .frame(width: 96, height: 188)

                    // iPhone 机身与屏幕容器
                    ZStack(alignment: .top) {
                        // 屏幕底色
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.94, green: 0.95, blue: 0.97))

                        // 机身边框（精密微金属边缘线）
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.15),
                                lineWidth: 1.5
                            )

                        // 屏幕内部微缩元素
                        VStack(spacing: 8) {
                            // 灵动岛 (Dynamic Island)
                            Capsule()
                                .fill(isDark ? Color.black : Color(red: 0.12, green: 0.12, blue: 0.14))
                                .frame(width: 28, height: 7.5)
                                .padding(.top, 5)

                            // 模拟微缩导航栏与标题
                            HStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isDark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                                    .frame(width: 32, height: 5)
                                Spacer()
                                Circle()
                                    .fill(currentAccentColor.opacity(0.8))
                                    .frame(width: 7, height: 7)
                            }
                            .padding(.horizontal, 10)
                            .padding(.top, 2)

                            // 模拟主卡片 (Nemo 学习进度卡片)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isDark ? Color(red: 0.18, green: 0.18, blue: 0.22) : Color.white)
                                .frame(height: 44)
                                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.06), radius: 3, y: 1)
                                .overlay {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(currentAccentColor)
                                                .frame(width: 8, height: 8)
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.35))
                                                .frame(width: 26, height: 4)
                                        }
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.15))
                                            .frame(width: 40, height: 3)
                                        Capsule()
                                            .fill(currentAccentColor.opacity(0.7))
                                            .frame(width: 22, height: 3)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 8)
                                }
                                .padding(.horizontal, 8)

                            // 模拟列表小行
                            VStack(spacing: 5) {
                                ForEach(0..<2) { _ in
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isDark ? Color(red: 0.15, green: 0.15, blue: 0.18) : Color.white.opacity(0.8))
                                        .frame(height: 16)
                                        .padding(.horizontal, 8)
                                }
                            }

                            Spacer()

                            // 模拟底栏四个 Tab 点
                            HStack(spacing: 12) {
                                Circle().fill(currentAccentColor).frame(width: 4, height: 4)
                                Circle().fill(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)).frame(width: 4, height: 4)
                                Circle().fill(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)).frame(width: 4, height: 4)
                                Circle().fill(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)).frame(width: 4, height: 4)
                            }
                            .padding(.bottom, 2)

                            // 底部 Home Indicator (主屏幕横条)
                            Capsule()
                                .fill(isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.4))
                                .frame(width: 32, height: 2.5)
                                .padding(.bottom, 5)
                        }
                    }
                    .frame(width: 88, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .frame(width: 96, height: 188)

                // 2. 底部单选与文字标签 (对齐 iOS 系统外观设置)
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundStyle(isSelected ? currentAccentColor : Color.secondary)

                    Text(title)
                        .font(.subheadline.weight(isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 单个 App 图标卡片
    @ViewBuilder
    private func appIconItemView(_ opt: AppIconOption) -> some View {
        let isSelected = (selectedAppIcon == opt)

        Button {
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            applyAppIconChange(opt)
        } label: {
            VStack(spacing: 8) {
                // 图标本体容器
                ZStack {
                    // 选中时的大外框环
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            isSelected ? currentAccentColor : Color.clear,
                            lineWidth: 2.5
                        )
                        .frame(width: 74, height: 74)

                    // 64×64 高清 Squircle 图标
                    ZStack {
                        Image(opt.previewImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                            }
                    }

                    // 选中时右上角 Check Badge
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(currentAccentColor)
                                        .frame(width: 20, height: 20)
                                    Circle()
                                        .strokeBorder(Color(uiColor: .systemBackground), lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                        .frame(width: 74, height: 74)
                    }
                }
                .frame(width: 74, height: 74)

                // 图标名称
                Text(opt.title)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 应用图标切换逻辑
    private func applyAppIconChange(_ opt: AppIconOption) {
        selectedAppIcon = opt
        storedAppIcon = opt.rawValue

        #if canImport(UIKit)
        if UIApplication.shared.supportsAlternateIcons {
            UIApplication.shared.setAlternateIconName(opt.alternateIconName) { error in
                if let error = error {
                    print("[AppIcon] Failed to change alternate icon: \(error.localizedDescription)")
                } else {
                    print("[AppIcon] Successfully changed alternate icon to: \(String(describing: opt.alternateIconName))")
                }
            }
        }
        #endif
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
    }
}
