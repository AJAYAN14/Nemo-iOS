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
    @State private var appearanceMode: String = "跟随系统"
    private let appearanceOptions = ["浅色模式", "深色模式", "跟随系统"]

    // 学习设置
    @State private var dailyWordGoal: Int = 20
    @State private var dailyGrammarGoal: Int = 10
    @State private var srsAlgorithm: String = "FSRS (新一代神经网络)"
    @State private var resetHour: String = "04:00 (推荐)"

    private let wordGoalOptions = [10, 20, 30, 50]
    private let grammarGoalOptions = [5, 10, 15, 20]
    private let srsOptions = ["FSRS (新一代神经网络)", "Anki SM-2 (经典)"]
    private let resetHourOptions = ["00:00 (午夜)", "02:00", "04:00 (推荐)", "06:00"]

    // 语音发音
    @State private var autoPlayTTS: Bool = true
    @State private var ttsVoice: String = "Kyoko (系统原生 · 女声)"
    @State private var ttsSpeed: Double = 1.0
    private let voiceOptions = ["Kyoko (系统原生 · 女声)", "Otoya (系统原生 · 男声)", "Siri 日语音声"]



    public init() {}

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
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.purple)
                                .frame(width: 28, height: 28)
                            Image(systemName: "circle.righthalf.filled")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }

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

            // MARK: - 3. 学习设置 (对齐 Android settings_section_title_learning)
            Section {
                Picker(selection: $dailyWordGoal) {
                    ForEach(wordGoalOptions, id: \.self) { goal in
                        Text("\(goal) 词/天").tag(goal)
                    }
                } label: {
                    Label("每日新词目标", systemImage: "sparkles")
                }

                Picker(selection: $dailyGrammarGoal) {
                    ForEach(grammarGoalOptions, id: \.self) { goal in
                        Text("\(goal) 条/天").tag(goal)
                    }
                } label: {
                    Label("每日语法目标", systemImage: "book.pages")
                }

                Picker(selection: $srsAlgorithm) {
                    ForEach(srsOptions, id: \.self) { algo in
                        Text(algo).tag(algo)
                    }
                } label: {
                    Label("记忆算法模型", systemImage: "brain.head.profile")
                }

                Picker(selection: $resetHour) {
                    ForEach(resetHourOptions, id: \.self) { hour in
                        Text(hour).tag(hour)
                    }
                } label: {
                    Label("每日重置时间", systemImage: "clock")
                }
            } header: {
                NemoSectionHeader("学习设置")
            } footer: {
                Text("FSRS 算法根据个人遗忘反馈动态调参，优化学习间隔与复习负荷。")
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
