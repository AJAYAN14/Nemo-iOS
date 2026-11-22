//
//  ThemeSettingsView.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 应用程序桌面主图标样式枚举
public enum AppIconOption: String, CaseIterable, Identifiable {
    /// 经典旗舰冰蓝（系统默认）
    case blue = "Apple-blue"
    /// 黑曜透亮
    case black = "Apple-black"
    /// 薄荷翠绿
    case green = "Apple-green"
    /// 鲜活亮橙
    case orange = "Apple-orange"
    /// 樱花透粉
    case pink = "Apple-pink"
    /// 赛博幻紫
    case purple = "Apple-purple"
    /// 珊瑚暖红
    case red = "Apple-red"
    /// 璨金阳光
    case yellow = "Apple-yellow"

    public var id: String { rawValue }

    /// 图标显示标题
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

    /// 图标视觉风格副标题
    public var subtitle: String {
        switch self {
        case .blue: return "经典冰蓝"
        case .black: return "黑曜石通透高光"
        case .green: return "薄荷翠绿微光"
        case .orange: return "明快活力橙"
        case .pink: return "轻盈樱粉晶莹"
        case .purple: return "赛博流体幻紫"
        case .red: return "热烈珊瑚红"
        case .yellow: return "温暖璨金阳光"
        }
    }

    /// 资源键值名
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

    /// 预览图标资源名
    public var previewImageName: String {
        "AppIconPreview-\(colorKey)"
    }

    /// 供系统调用的候选图标名称（默认冰蓝传 nil）
    public var alternateIconName: String? {
        if self == .blue { return nil }
        return "AppIcon-\(colorKey)"
    }

    /// 对应的主题强调色
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

/// 主题强调色选项枚举（遵循 Apple HIG 官方原生调色盘）
public enum ThemeAccentColorOption: String, CaseIterable, Identifiable {
    /// 旗舰深蓝（默认）
    case blue = "旗舰蓝"
    /// 极光青蓝
    case cyan = "极光青"
    /// 晨曦青绿
    case teal = "晨曦青"
    /// 清爽薄荷
    case mint = "清爽薄荷"
    /// 生机翠绿
    case green = "生机绿"
    /// 璨金明黄
    case yellow = "璨金黄"
    /// 活力暖橙
    case orange = "活力橙"
    /// 珊瑚绯红
    case red = "珊瑚红"
    /// 晶莹樱粉
    case pink = "樱花粉"
    /// 赛博幻紫
    case purple = "赛博紫"

    public var id: String { rawValue }

    /// 选项对应的 SwiftUI 官方原生语义色彩
    public var color: Color {
        switch self {
        case .blue: return Color.blue
        case .cyan: return Color.cyan
        case .teal: return Color.teal
        case .mint: return Color.mint
        case .green: return Color.green
        case .yellow: return Color.yellow
        case .orange: return Color.orange
        case .red: return Color.red
        case .pink: return Color.pink
        case .purple: return Color.purple
        }
    }
}

/// 设置列表项图标呈现风格枚举
public enum SettingIconStyleOption: String, CaseIterable, Identifiable {
    /// 柔和半透材质
    case softTranslucent = "柔和半透"
    /// 鲜活纯色材质
    case vibrantSolid = "鲜活纯色"

    public var id: String { rawValue }
}

/// 主题与外观个性化配置视图
///
/// 提供系统深浅色外观调度、自定时段选择、主题强调色与应用桌面图标切换功能。
public struct ThemeSettingsView: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss

    // 存储与状态
    @AppStorage("settings_dark_mode_option") private var storedDarkMode: String = "auto"
    @AppStorage("settings_auto_strategy") private var storedAutoStrategy: String = "follow_system"
    @AppStorage("settings_dark_start_time") private var darkModeStartTime: String = "21:00"
    @AppStorage("settings_dark_end_time") private var darkModeEndTime: String = "07:00"
    @AppStorage("settings_theme_accent") private var storedAccentColor: String = "旗舰蓝"
    @AppStorage("settings_icon_style") private var storedIconStyle: String = "柔和半透"
    @AppStorage("settings_app_icon_option") private var storedAppIcon: String = "Apple-blue"

    // 局部交互状态
    @State private var isAutoSwitch: Bool = true
    @State private var selectedAppIcon: AppIconOption = .blue
    @State private var selectedAccent: ThemeAccentColorOption = .blue
    @State private var selectedIconStyle: SettingIconStyleOption = .softTranslucent
    @State private var isTabBarHidden: Bool = false

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

    // MARK: - 自定义时间绑定
    private var darkStartDate: Binding<Date> {
        Binding {
            dateFromTimeString(darkModeStartTime) ?? defaultStartDate
        } set: { newDate in
            darkModeStartTime = timeStringFromDate(newDate)
        }
    }

    private var darkEndDate: Binding<Date> {
        Binding {
            dateFromTimeString(darkModeEndTime) ?? defaultEndDate
        } set: { newDate in
            darkModeEndTime = timeStringFromDate(newDate)
        }
    }

    private var defaultStartDate: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 21
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    private var defaultEndDate: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 7
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func dateFromTimeString(_ str: String) -> Date? {
        let parts = str.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = parts[0]
        comps.minute = parts[1]
        return Calendar.current.date(from: comps)
    }

    private func timeStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// 执行系统级平滑外观切换动效（触发原生 Window 交叉溶解）
    /// - Parameter mode: 目标外观模式 ("light"、"dark" 或 "auto")
    private func updateAppearance(to mode: String) {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first {
            UIView.transition(with: window, duration: 0.35, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
                if mode != "auto" {
                    self.isAutoSwitch = false
                }
                self.storedDarkMode = mode
            }
            return
        }
        #endif

        withAnimation(.easeInOut(duration: 0.35)) {
            if mode != "auto" {
                isAutoSwitch = false
            }
            storedDarkMode = mode
        }
    }

    public var body: some View {
        List {
            // MARK: - 外观显示模式
            Section {
                VStack(spacing: 14) {
                    HStack(spacing: 28) {
                        Spacer()
                        themeModePreviewCard(
                            title: "浅色",
                            isDark: false,
                            isSelected: !isDarkEffective
                        ) {
                            updateAppearance(to: "light")
                        }

                        themeModePreviewCard(
                            title: "深色",
                            isDark: true,
                            isSelected: isDarkEffective
                        ) {
                            updateAppearance(to: "dark")
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowSeparator(.hidden)

                // 自动切换开关
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
                .listRowSeparator(.hidden, edges: .top)
                .onChange(of: isAutoSwitch) { auto in
                    if auto {
                        updateAppearance(to: "auto")
                    } else {
                        updateAppearance(to: isDarkEffective ? "dark" : "light")
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
                        DatePicker(selection: darkStartDate, displayedComponents: .hourAndMinute) {
                            Label("深色开始时间", systemImage: "moon.fill")
                                .foregroundStyle(.primary)
                        }
                        .tint(currentAccentColor)

                        DatePicker(selection: darkEndDate, displayedComponents: .hourAndMinute) {
                            Label("深色结束时间", systemImage: "sun.max.fill")
                                .foregroundStyle(.primary)
                        }
                        .tint(currentAccentColor)
                    }
                }
            } header: {
                NemoSectionHeader("外观")
            } footer: {
                Text("开启“自动”后，应用将始终与 iOS 系统设定的日出日落或全局外观偏好保持一致。选择“自定时段”可自由设定浅色与深色生效时间。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // MARK: - 个性化定制
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

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
                        spacing: 14
                    ) {
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
                    .sensoryFeedback(.selection, trigger: selectedAccent)
                    .padding(.vertical, 4)
                }
                .padding(.vertical, 4)

                // 设置项图标风格
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
                NemoSectionHeader("个性化定制")
            }

            // MARK: - 应用桌面图标
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
                    .sensoryFeedback(.selection, trigger: selectedAppIcon)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
            } header: {
                NemoSectionHeader("应用桌面图标")
            } footer: {
                Text("提供 8 款专为 Apple 设计的 Squircle 流体玻璃高光图标，默认采用旗舰冰蓝风格。点击可实时在桌面生效。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .nemoTopAppBarEffect()
        .navigationTitle("主题与外观")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isTabBarHidden ? .hidden : .visible, for: .tabBar)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isTabBarHidden)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isTabBarHidden = true
            }

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
            } else {
                selectedAccent = .blue
                storedAccentColor = "旗舰蓝"
            }
            if let savedIconStyle = SettingIconStyleOption(rawValue: storedIconStyle) {
                selectedIconStyle = savedIconStyle
            }
            isAutoSwitch = (storedDarkMode == "auto")
        }
        .onDisappear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isTabBarHidden = false
            }
        }
    }

    // MARK: - 主题模式机身微缩预览卡片
    @ViewBuilder
    private func themeModePreviewCard(
        title: String,
        isDark: Bool,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            isSelected ? currentAccentColor : Color.clear,
                            lineWidth: 2.5
                        )
                        .frame(width: 96, height: 188)

                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(isDark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.94, green: 0.95, blue: 0.97))

                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.15),
                                lineWidth: 1.5
                            )

                        VStack(spacing: 8) {
                            Capsule()
                                .fill(isDark ? Color.black : Color(red: 0.12, green: 0.12, blue: 0.14))
                                .frame(width: 28, height: 7.5)
                                .padding(.top, 5)

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

                            VStack(spacing: 5) {
                                ForEach(0..<2) { _ in
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isDark ? Color(red: 0.15, green: 0.15, blue: 0.18) : Color.white.opacity(0.8))
                                        .frame(height: 16)
                                        .padding(.horizontal, 8)
                                }
                            }

                            Spacer()

                            HStack(spacing: 12) {
                                Circle().fill(currentAccentColor).frame(width: 4, height: 4)
                                Circle().fill(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)).frame(width: 4, height: 4)
                                Circle().fill(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)).frame(width: 4, height: 4)
                                Circle().fill(isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)).frame(width: 4, height: 4)
                            }
                            .padding(.bottom, 2)

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
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - 单个 App 图标卡片
    @ViewBuilder
    private func appIconItemView(_ opt: AppIconOption) -> some View {
        let isSelected = (selectedAppIcon == opt)

        Button {
            applyAppIconChange(opt)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            isSelected ? currentAccentColor : Color.clear,
                            lineWidth: 2.5
                        )
                        .frame(width: 74, height: 74)

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

                Text(opt.title)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 应用图标变更调用
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
