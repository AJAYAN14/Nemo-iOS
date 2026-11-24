//
//  SettingsHomeView.swift
//  Nemo
//

import SwiftUI

/// 个人中心与全局系统设置主视图
///
/// 涵盖账户数据同步、主题与外观配置、学习目标规划、离线发音人与数据备份管理。
public struct SettingsHomeView: View {
    // 认证与会话状态
    @Environment(AuthStore.self) private var authStore
    @State private var isLoginSheetPresented: Bool = false
    @State private var isLogoutAlertPresented: Bool = false

    // 主题外观
    @AppStorage("settings_dark_mode_option") private var storedDarkMode: String = "auto"
    private var appearanceMode: String {
        switch storedDarkMode {
        case "light": return "浅色模式"
        case "dark": return "深色模式"
        default: return "跟随系统"
        }
    }

    // 学习设置配置
    @AppStorage("settings_daily_word_goal") private var dailyWordGoal: Int = 20
    @AppStorage("settings_daily_grammar_goal") private var dailyGrammarGoal: Int = 10
    @AppStorage("settings_learning_day_reset_hour") private var learningDayResetHour: Int = 4
    @AppStorage("settings_random_extract_new_content") private var isRandomNewContentEnabled: Bool = false

    private let wordGoalOptions: [Int] = [5, 10, 20, 30, 50]
    private let grammarGoalOptions: [Int] = [5, 10, 15, 20, 25]
    private let resetHourOptions: [(hour: Int, label: String)] = [
        (0, "00:00"),
        (2, "02:00"),
        (4, "04:00"),
        (5, "05:00"),
        (6, "06:00")
    ]

    public init() {}

    @ViewBuilder
    private func settingIcon(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color)
                .frame(width: 28, height: 28)
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    public var body: some View {
        List {
            // MARK: - 账户与同步
            Section {
                Button {
                    if !authStore.isLoggedIn {
                        isLoginSheetPresented = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        if let avatarUrlString = authStore.currentUser?.avatarUrl,
                           let url = URL(string: avatarUrlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.blue)
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(authStore.isLoggedIn ? (authStore.currentUser?.username ?? "Nemo 用户") : "未登录")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            Text(authStore.isLoggedIn ? (authStore.currentUser?.email ?? "账号同步已开启") : "点击登录以同步学习数据")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(Color.secondary.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)

                Button {
                    // 接入云端备份动作
                } label: {
                    Label("备份至云端", systemImage: "icloud.and.arrow.up")
                }

                Button {
                    // TODO: 接入云端备份历史
                } label: {
                    Label("云端备份历史", systemImage: "clock.arrow.circlepath")
                }
            } header: {
                NemoSectionHeader("账户与同步")
            }

            // MARK: - 主题与外观
            Section {
                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    HStack(spacing: 12) {
                        settingIcon(systemName: "circle.righthalf.filled", color: .purple)

                        Text("主题与外观")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(appearanceMode)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                NemoSectionHeader("主题与外观")
            }

            // MARK: - 学习设置
            Section {
                // 1. 每日单词目标
                HStack(spacing: 12) {
                    settingIcon(systemName: "target", color: .orange)

                    Text("每日单词目标")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    Picker("", selection: $dailyWordGoal) {
                        ForEach(wordGoalOptions, id: \.self) { goal in
                            Text("\(goal)个").tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 2. 每日语法目标
                HStack(spacing: 12) {
                    settingIcon(systemName: "book.closed.fill", color: .green)

                    Text("每日语法目标")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    Picker("", selection: $dailyGrammarGoal) {
                        ForEach(grammarGoalOptions, id: \.self) { goal in
                            Text("\(goal)条").tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 3. 学习日重置时间
                HStack(spacing: 12) {
                    settingIcon(systemName: "timer", color: .mint)

                    Text("学习日重置时间")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    Picker("", selection: $learningDayResetHour) {
                        ForEach(resetHourOptions, id: \.hour) { item in
                            Text(item.label).tag(item.hour)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 4. 新内容乱序抽取
                HStack(spacing: 12) {
                    settingIcon(systemName: "shuffle", color: .teal)

                    Text("新内容乱序抽取")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    Toggle("", isOn: $isRandomNewContentEnabled)
                        .labelsHidden()
                }

                // 5. 记忆算法配置
                Button {
                    // TODO: 接入记忆算法配置页
                } label: {
                    HStack(spacing: 12) {
                        settingIcon(systemName: "brain.head.profile", color: .purple)

                        Text("记忆算法配置")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // 6. AI 工坊配置
                Button {
                    // TODO: 接入 AI 工坊配置页
                } label: {
                    HStack(spacing: 12) {
                        settingIcon(systemName: "sparkles", color: .blue)

                        Text("AI 工坊配置")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                NemoSectionHeader("学习设置")
            } footer: {
                Text("学习目标与重置时点将影响每日新学分配。重置时间提供零点跨天保护，过了指定时点才计算新一天的打卡与任务。")
            }

            // MARK: - 语音设置
            Section {
                NavigationLink {
                    TtsSettingsView()
                } label: {
                    HStack(spacing: 12) {
                        settingIcon(systemName: "speaker.wave.2.fill", color: .pink)

                        Text("语音设置")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                }
            } header: {
                NemoSectionHeader("语音设置")
            } footer: {
                Text("配置日语与中文发音人、朗读语速、音调以及翻卡自动朗读偏好。")
            }

            // MARK: - 数据管理
            Section {
                Button {
                    // TODO: 接入导出学习数据交互
                } label: {
                    Label("导出学习数据", systemImage: "square.and.arrow.up")
                }

                Button {
                    // TODO: 接入导入学习数据交互
                } label: {
                    Label("导入学习数据", systemImage: "square.and.arrow.down")
                }

                HStack {
                    Label("存储空间占用", systemImage: "internaldrive")
                    Spacer()
                    Text("14.2 MB")
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    // 接入重置学习数据二次确认弹窗
                } label: {
                    Label("重置学习数据", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(.red)
                }

                if authStore.isLoggedIn {
                    Button(role: .destructive) {
                        isLogoutAlertPresented = true
                    } label: {
                        Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                NemoSectionHeader("数据管理")
            }

            // MARK: - 关于 Nemo
            Section {
                HStack {
                    Label("应用版本", systemImage: "info.circle.fill")
                    Spacer()
                    Text("1.0.0 Dev (Build 2601)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("技术底座", systemImage: "swift")
                    Spacer()
                    Text("SwiftUI · Swift 6")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("工程定位", systemImage: "shield.checkerboard")
                    Spacer()
                    Text("纯个人自用 (免 App Store 审核)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                NemoSectionHeader("关于 Nemo")
            } footer: {
                Text("Nemo 专注于极致纯粹、无干扰的高效日语学习体验。")
            }
        }
        .listStyle(.insetGrouped)
        .nemoTopAppBarEffect()
        .navigationTitle("个人")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isLoginSheetPresented) {
            LoginScreenView()
        }
        .alert("退出登录", isPresented: $isLogoutAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                Task {
                    await authStore.logout()
                }
            }
        } message: {
            Text("确定要退出当前登录账号吗？本地离线缓存将受到保护。")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsHomeView()
            .environment(AuthStore())
    }
}
