//
//  SettingsHomeView.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 设置主页（100% 对齐 Android SettingsScreen.kt 结构与文案）
public struct SettingsHomeView: View {
    // 账户状态
    @State private var isLoggedIn: Bool = true
    @State private var username: String = "Nemo"

    // 主题外观
    @AppStorage("settings_dark_mode_option") private var storedDarkMode: String = "auto"
    private var appearanceMode: String {
        switch storedDarkMode {
        case "light": return "浅色模式"
        case "dark": return "深色模式"
        default: return "跟随系统"
        }
    }

    // 学习设置 (100% 对齐 Android SettingsScreen.kt 参数)
    @AppStorage("settings_daily_word_goal") private var dailyWordGoal: Int = 20
    @AppStorage("settings_daily_grammar_goal") private var dailyGrammarGoal: Int = 10
    @AppStorage("settings_learning_day_reset_hour") private var learningDayResetHour: Int = 4
    @AppStorage("settings_random_extract_new_content") private var isRandomNewContentEnabled: Bool = false

    // 对齐 Android: listOf(5, 10, 20, 30, 50)
    private let wordGoalOptions: [Int] = [5, 10, 20, 30, 50]
    // 对齐 Android: listOf(5, 10, 15, 20, 25)
    private let grammarGoalOptions: [Int] = [5, 10, 15, 20, 25]
    // 对齐 Android: listOf(0, 2, 4, 5, 6)
    private let resetHourOptions: [(hour: Int, label: String)] = [
        (0, "凌晨 0:00 (午夜)"),
        (2, "凌晨 2:00"),
        (4, "凌晨 4:00 (推荐)"),
        (5, "凌晨 5:00"),
        (6, "凌晨 6:00")
    ]

    // 语音发音
    @State private var autoPlayTTS: Bool = true
    @State private var ttsVoice: String = "Kyoko (系统原生 · 女声)"
    @State private var ttsSpeed: Double = 1.0
    private let voiceOptions = ["Kyoko (系统原生 · 女声)", "Otoya (系统原生 · 男声)", "Siri 日语音声"]

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
            // MARK: - 1. 账户与同步 (对齐 Android settings_section_title_account)
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isLoggedIn ? username : "未登录")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(isLoggedIn ? "账号同步已开启" : "点击登录以同步学习数据")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }

                Button {
                    // 备份至云端动作
                } label: {
                    Label("备份至云端", systemImage: "icloud.and.arrow.up")
                }

                Button {
                    // 备份历史动作
                } label: {
                    Label("云端备份历史", systemImage: "clock.arrow.circlepath")
                }
            } header: {
                NemoSectionHeader("账户与同步")
            }

            // MARK: - 2. 主题与外观 (对齐 Android settings_section_title_appearance)
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

            // MARK: - 3. 学习设置 (100% 对齐 Android settings_section_title_learning)
            Section {
                // 1. 每日单词目标 (5, 10, 20, 30, 50)
                HStack(spacing: 12) {
                    settingIcon(systemName: "target", color: .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("每日单词目标")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("设置每天要学习的单词数量")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $dailyWordGoal) {
                        ForEach(wordGoalOptions, id: \.self) { goal in
                            Text("\(goal)个").tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 2. 每日语法目标 (5, 10, 15, 20, 25)
                HStack(spacing: 12) {
                    settingIcon(systemName: "book.closed.fill", color: .green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("每日语法目标")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("设置每天要学习的语法数量")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $dailyGrammarGoal) {
                        ForEach(grammarGoalOptions, id: \.self) { goal in
                            Text("\(goal)条").tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 3. 学习日重置时间 (0, 2, 4, 5, 6)
                HStack(spacing: 12) {
                    settingIcon(systemName: "timer", color: .mint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("学习日重置时间")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("零点跨天保护，过了此时间才算新的一天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $learningDayResetHour) {
                        ForEach(resetHourOptions, id: \.hour) { item in
                            Text(item.label).tag(item.hour)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 4. 新内容乱序抽取 (Toggle)
                HStack(spacing: 12) {
                    settingIcon(systemName: "shuffle", color: .teal)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("新内容乱序抽取")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text(isRandomNewContentEnabled ? "随机抽取新内容" : "按顺序抽取新内容")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $isRandomNewContentEnabled)
                        .labelsHidden()
                }

                // 5. 记忆算法配置 (对齐 Android settings_item_title_algorithm)
                Button {
                    // 进入记忆算法配置
                } label: {
                    HStack(spacing: 12) {
                        settingIcon(systemName: "brain.head.profile", color: .purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("记忆算法配置")
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text("步进、提前复习与 Leech 策略")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // 6. AI 工坊配置 (对齐 Android settings_item_title_ai_workshop)
                Button {
                    // 进入 AI 工坊配置
                } label: {
                    HStack(spacing: 12) {
                        settingIcon(systemName: "sparkles", color: .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI 工坊配置")
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text("设置 API Key 与 AI 模型")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

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
                Text("学习目标与重置时点将影响每日新学分配与连续打卡统计。")
            }

            // MARK: - 4. 语音发音 (对齐 Android settings_section_title_voice)
            Section {
                Toggle(isOn: $autoPlayTTS) {
                    Label("翻卡自动朗读", systemImage: "speaker.wave.2.fill")
                }

                Picker(selection: $ttsVoice) {
                    ForEach(voiceOptions, id: \.self) { voice in
                        Text(voice).tag(voice)
                    }
                } label: {
                    Label("发音人", systemImage: "person.wave.2.fill")
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("发音语速", systemImage: "gauge.with.needle.fill")
                        Spacer()
                        Text(String(format: "%.1fx", ttsSpeed))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $ttsSpeed, in: 0.5...2.0, step: 0.1)
                }
            } header: {
                NemoSectionHeader("语音发音")
            } footer: {
                Text("优先使用 iOS 原生 AVSpeechSynthesizer 离线发音，零延迟、零流量消耗。")
            }

            // MARK: - 5. 数据管理 (对齐 Android settings_section_title_data)
            Section {
                Button {
                    // 导出数据
                } label: {
                    Label("导出学习数据", systemImage: "square.and.arrow.up")
                }

                Button {
                    // 导入数据
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
                    // 重置数据
                } label: {
                    Label("重置学习数据", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(.red)
                }
            } header: {
                NemoSectionHeader("数据管理")
            }



            // MARK: - 7. 关于 Nemo (对齐 Android settings_section_title_about)
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
        .navigationTitle("个人")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsHomeView()
    }
}
