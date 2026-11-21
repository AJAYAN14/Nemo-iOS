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
    case green = "Apple-green"
    case black = "Apple-black"
    case blue = "Apple-blue"
    case orange = "Apple-orange"
    case pink = "Apple-pink"
    case purple = "Apple-purple"
    case red = "Apple-red"
    case yellow = "Apple-yellow"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .green: return "薄荷翠绿"
        case .black: return "黑曜透亮"
        case .blue: return "旗舰冰蓝"
        case .orange: return "鲜活亮橙"
        case .pink: return "樱花透粉"
        case .purple: return "赛博幻紫"
        case .red: return "珊瑚暖红"
        case .yellow: return "璨金阳光"
        }
    }

    public var subtitle: String {
        switch self {
        case .green: return "对齐 Android 原生尺寸"
        case .black: return "黑曜石通透高光"
        case .blue: return "经典旗舰蓝宝石"
        case .orange: return "明快活力橙"
        case .pink: return "轻盈樱粉晶莹"
        case .purple: return "赛博流体幻紫"
        case .red: return "热烈珊瑚红"
        case .yellow: return "温暖璨金阳光"
        }
    }

    public var colorKey: String {
        switch self {
        case .green: return "green"
        case .black: return "black"
        case .blue: return "blue"
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
        if self == .green { return nil }
        return "AppIcon-\(colorKey)"
    }

    public var accentColor: Color {
        switch self {
        case .green: return Color.green
        case .black: return Color.primary
        case .blue: return Color.blue
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

// MARK: - 主题与外观视图（100% 对齐 Android ThemeSettingsScreen.kt）
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
    @AppStorage("settings_app_icon_option") private var storedAppIcon: String = "Apple-green"

    // 局部交互状态
    @State private var isAutoSwitch: Bool = true
    @State private var selectedAppIcon: AppIconOption = .green
    @State private var selectedAccent: ThemeAccentColorOption = .green
    @State private var selectedIconStyle: SettingIconStyleOption = .softTranslucent
    @State private var showIconSwitchAlert: Bool = false
    @State private var pendingIcon: AppIconOption?

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
            // MARK: 1. 显示模式 (Display Mode)
            Section {
                VStack(spacing: 16) {
                    // 浅色 / 深色双微缩卡片切换
                    HStack(spacing: 14) {
                        themeModePreviewCard(
                            title: "浅色模式",
                            isDark: false,
                            isSelected: !isDarkEffective
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isAutoSwitch = false
                                storedDarkMode = "light"
                            }
                        }

                        themeModePreviewCard(
                            title: "深色模式",
                            isDark: true,
                            isSelected: isDarkEffective
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isAutoSwitch = false
                                storedDarkMode = "dark"
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                // 自动切换开关
                Toggle(isOn: $isAutoSwitch.animation(.easeInOut(duration: 0.2))) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("自动切换")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("跟随系统或定时在浅色与深色之间平滑切换")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(currentAccentColor)

                // 自动模式下的切换策略
                if isAutoSwitch {
                    Picker("切换策略", selection: $storedAutoStrategy) {
                        Text("跟随系统").tag("follow_system")
                        Text("定时切换").tag("scheduled")
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
                Text("显示模式")
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

                // 设置图标风格
                HStack {
                    Text("设置项图标风格")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker("图标风格", selection: $selectedIconStyle) {
                        ForEach(SettingIconStyleOption.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
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
                Text("一共 8 款专为 Apple 设计的 Squircle 流体玻璃高光图标，点击可实时更换并在桌面生效。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("主题与外观")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let savedOpt = AppIconOption(rawValue: storedAppIcon) {
                selectedAppIcon = savedOpt
            }
            if let savedAccent = ThemeAccentColorOption(rawValue: storedAccentColor) {
                selectedAccent = savedAccent
            }
            if let savedIconStyle = SettingIconStyleOption(rawValue: storedIconStyle) {
                selectedIconStyle = savedIconStyle
            }
            isAutoSwitch = (storedDarkMode == "auto")
        }
        .alert("切换桌面图标", isPresented: $showIconSwitchAlert) {
            Button("取消", role: .cancel) {
                pendingIcon = nil
            }
            Button("确认切换") {
                if let icon = pendingIcon {
                    applyAppIconChange(icon)
                }
            }
        } message: {
            if let icon = pendingIcon {
                Text("是否将 Nemo 桌面图标切换为「\(icon.title)」？")
            }
        }
    }

    // MARK: - 主题模式微缩预览卡片
    @ViewBuilder
    private func themeModePreviewCard(
        title: String,
        isDark: Bool,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // 微缩模拟界面
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isDark ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color(red: 0.95, green: 0.95, blue: 0.97))
                        .overlay {
                            VStack(spacing: 6) {
                                // 模拟顶部条
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.12))
                                    .frame(width: 48, height: 6)

                                // 模拟内容小卡片
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isDark ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color.white)
                                    .frame(height: 38)
                                    .overlay {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(currentAccentColor.opacity(0.8))
                                                .frame(width: 14, height: 14)
                                            VStack(alignment: .leading, spacing: 3) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25))
                                                    .frame(width: 32, height: 4)
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.12))
                                                    .frame(width: 20, height: 3)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                    }

                                // 模拟微型胶囊按钮
                                Capsule()
                                    .fill(currentAccentColor)
                                    .frame(height: 12)
                            }
                            .padding(10)
                        }

                    // 选中状态高亮外边框
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected ? currentAccentColor : Color.clear,
                            lineWidth: 2.5
                        )
                }
                .frame(height: 100)

                // 底部单选标题与指示器
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
        .frame(maxWidth: .infinity)
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
            pendingIcon = opt
            showIconSwitchAlert = true
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
        pendingIcon = nil

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
