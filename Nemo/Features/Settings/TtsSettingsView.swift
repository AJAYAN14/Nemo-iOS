//
//  TtsSettingsView.swift
//  Nemo
//
//  Created by Nemo Team on 2026-11-22.
//

import SwiftUI
import AVFoundation

/// 语音发音人描述项
public struct SpeechVoiceOption: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let language: String
    public let displayName: String
    public let tags: String

    public init(id: String, name: String, language: String, displayName: String, tags: String = "") {
        self.id = id
        self.name = name
        self.language = language
        self.displayName = displayName
        self.tags = tags
    }
}

/// 抽屉弹窗选择目标语言枚举
public enum TtsVoiceSheetTarget: String, Identifiable {
    case japanese = "ja"
    case chinese = "zh"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .japanese: return "选择日语发音人"
        case .chinese: return "选择中文发音人"
        }
    }
}

/// 语音合成试听管理中心
@MainActor
@Observable
final class TtsPreviewManager: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    /// 是否正在试听日语
    var isPlayingJapanese: Bool = false
    /// 是否正在试听中文
    var isPlayingChinese: Bool = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// 停止所有朗读任务
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlayingJapanese = false
        isPlayingChinese = false
    }

    /// 播放指定语言与发音人试听
    /// - Parameters:
    ///   - text: 试听文案
    ///   - voiceName: 发音人名称或代号
    ///   - language: 语言代码前缀 (ja 或 zh)
    ///   - rate: 语速倍率
    ///   - pitch: 音调倍率
    ///   - isJapanese: 是否为日语试听
    func speak(
        text: String,
        voiceName: String,
        language: String,
        rate: Double,
        pitch: Double,
        isJapanese: Bool
    ) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        let defaultRate = AVSpeechUtteranceDefaultSpeechRate
        utterance.rate = Float(min(max(rate * Double(defaultRate), Double(AVSpeechUtteranceMinimumSpeechRate)), Double(AVSpeechUtteranceMaximumSpeechRate)))
        utterance.pitchMultiplier = Float(min(max(pitch, 0.5), 2.0))

        if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.lowercased().hasPrefix(language.prefix(2).lowercased()) &&
            ($0.name.localizedCaseInsensitiveContains(voiceName) || $0.identifier.localizedCaseInsensitiveContains(voiceName))
        }) {
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(language: language == "ja" ? "ja-JP" : "zh-CN") {
            utterance.voice = fallbackVoice
        }

        if isJapanese {
            isPlayingJapanese = true
        } else {
            isPlayingChinese = true
        }

        synthesizer.speak(utterance)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlayingJapanese = false
            self.isPlayingChinese = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlayingJapanese = false
            self.isPlayingChinese = false
        }
    }
}

/// 语音合成设置主视图
///
/// 完全采用 Apple iOS 原生控件规范（原生 NavigationLink Picker、原生系统 Slider 与原生操作单元），
/// 涵盖语音来源、语速调节、音调调节以及双语例句试听与重置四大核心功能。
public struct TtsSettingsView: View {
    // MARK: - 持久化存储
    @AppStorage("settings_tts_voice_name") private var selectedJapaneseVoice: String = "Kyoko"
    @AppStorage("settings_tts_chinese_voice_name") private var selectedChineseVoice: String = "Tingting"
    @AppStorage("settings_tts_speed") private var speechRate: Double = 1.0
    @AppStorage("settings_tts_pitch") private var speechPitch: Double = 1.0

    // MARK: - 内部状态
    @State private var previewManager = TtsPreviewManager()
    @State private var isTabBarHidden: Bool = false
    @State private var japaneseVoices: [SpeechVoiceOption] = []
    @State private var chineseVoices: [SpeechVoiceOption] = []
    @State private var activeVoiceSheet: TtsVoiceSheetTarget? = nil
    @State private var hapticSelectionTrigger: Bool = false

    /// 当前选中的日语音色显示名称
    private var selectedJapaneseVoiceDisplayName: String {
        japaneseVoices.first(where: { $0.name == selectedJapaneseVoice })?.displayName ?? selectedJapaneseVoice
    }

    /// 当前选中的中语音色显示名称
    private var selectedChineseVoiceDisplayName: String {
        chineseVoices.first(where: { $0.name == selectedChineseVoice })?.displayName ?? selectedChineseVoice
    }

    // MARK: - 试听例句
    private let sampleJapaneseText = "こんにちは、Nemoへようこそ。一緒に日本語を勉強しましょう！"
    private let sampleChineseText = "你好，欢迎使用 Nemo 日语，一起开启高效学习之旅！"

    public init() {}

    public var body: some View {
        List {
            // MARK: - 1. 语音来源（抽屉弹窗选择）
            Section {
                Button {
                    activeVoiceSheet = .japanese
                } label: {
                    HStack {
                        Text("日语发音人")
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(selectedJapaneseVoiceDisplayName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Button {
                    activeVoiceSheet = .chinese
                } label: {
                    HStack {
                        Text("中文发音人")
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(selectedChineseVoiceDisplayName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                NemoSectionHeader("语音来源")
            } footer: {
                Text("优先调用 iOS 设备内置神经引擎发音人，音质纯净自然，且免网络流量消耗。")
            }

            // MARK: - 2. 语速调节
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("朗读语速")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(String(format: "%.1fx", speechRate))
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }

                    Slider(value: $speechRate, in: 0.5...2.0, step: 0.1) {
                        Text("朗读语速")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Image(systemName: "hare.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            } header: {
                NemoSectionHeader("语速调节")
            } footer: {
                Text("初学者推荐设定在 0.8x 慢速以便听清假名长短音，熟练后推荐 1.0x 正常速度。")
            }

            // MARK: - 3. 音调调节
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("音调高低")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(String(format: "%.1fx", speechPitch))
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }

                    Slider(value: $speechPitch, in: 0.5...2.0, step: 0.1) {
                        Text("音调高低")
                    } minimumValueLabel: {
                        Text("低")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("高")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            } header: {
                NemoSectionHeader("音调调节")
            } footer: {
                Text("微调发音音频基频，数值越小声音越浑厚，数值越大声音越清脆。")
            }

            // MARK: - 4. 试听与重置
            Section {
                Button {
                    if previewManager.isPlayingJapanese {
                        previewManager.stop()
                    } else {
                        previewManager.speak(
                            text: sampleJapaneseText,
                            voiceName: selectedJapaneseVoice,
                            language: "ja",
                            rate: speechRate,
                            pitch: speechPitch,
                            isJapanese: true
                        )
                    }
                } label: {
                    HStack {
                        Text(previewManager.isPlayingJapanese ? "停止日语试听" : "试听日语发音")
                            .foregroundStyle(previewManager.isPlayingJapanese ? .red : .primary)

                        Spacer()

                        Image(systemName: previewManager.isPlayingJapanese ? "stop.fill" : "play.fill")
                            .foregroundStyle(previewManager.isPlayingJapanese ? .red : Color.accentColor)
                    }
                }

                Button {
                    if previewManager.isPlayingChinese {
                        previewManager.stop()
                    } else {
                        previewManager.speak(
                            text: sampleChineseText,
                            voiceName: selectedChineseVoice,
                            language: "zh",
                            rate: speechRate,
                            pitch: speechPitch,
                            isJapanese: false
                        )
                    }
                } label: {
                    HStack {
                        Text(previewManager.isPlayingChinese ? "停止中文试听" : "试听中文释义")
                            .foregroundStyle(previewManager.isPlayingChinese ? .red : .primary)

                        Spacer()

                        Image(systemName: previewManager.isPlayingChinese ? "stop.fill" : "play.fill")
                            .foregroundStyle(previewManager.isPlayingChinese ? .red : Color.accentColor)
                    }
                }
            } header: {
                NemoSectionHeader("试听")
            }

            Section {
                Button(role: .destructive) {
                    previewManager.stop()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        speechRate = 1.0
                        speechPitch = 1.0
                        selectedJapaneseVoice = "Kyoko"
                        selectedChineseVoice = "Tingting"
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("恢复默认设置")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("语音设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isTabBarHidden ? .hidden : .visible, for: .tabBar)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isTabBarHidden)
        .sheet(item: $activeVoiceSheet) { target in
            voiceSelectionDrawerSheet(for: target)
        }
        .sensoryFeedback(.selection, trigger: hapticSelectionTrigger)
        .onAppear {
            loadAvailableVoices()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isTabBarHidden = true
            }
        }
        .onDisappear {
            previewManager.stop()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isTabBarHidden = false
            }
        }
    }

    // MARK: - 语音选择抽屉弹窗（iOS 原生 Bottom Sheet）

    @ViewBuilder
    private func voiceSelectionDrawerSheet(for target: TtsVoiceSheetTarget) -> some View {
        let voices = target == .japanese ? japaneseVoices : chineseVoices
        let currentSelectedName = target == .japanese ? selectedJapaneseVoice : selectedChineseVoice

        NavigationStack {
            List {
                Section {
                    ForEach(voices, id: \.name) { voice in
                        Button {
                            if target == .japanese {
                                selectedJapaneseVoice = voice.name
                            } else {
                                selectedChineseVoice = voice.name
                            }
                            hapticSelectionTrigger.toggle()
                            activeVoiceSheet = nil
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(voice.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)

                                    if !voice.tags.isEmpty {
                                        Text(voice.tags)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if currentSelectedName == voice.name {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text(target == .japanese
                         ? "支持系统的原生日语音频库，优先选用高保真发音人，音质更加真实自然。"
                         : "支持系统的原生中文音频库，包含标准普通话与特色发音。")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(target.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        activeVoiceSheet = nil
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    // MARK: - 发音人列表加载

    private func loadAvailableVoices() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // 1. 日语音色列表
        var jaList = allVoices.filter { $0.language.lowercased().hasPrefix("ja") }.map { voice -> SpeechVoiceOption in
            let gender = voice.gender == .female ? "女声" : (voice.gender == .male ? "男声" : "")
            let quality = voice.quality == .enhanced ? "高保真" : (voice.quality == .premium ? "超清" : "")
            let tags = [gender, quality].filter { !$0.isEmpty }.joined(separator: " · ")
            let display = tags.isEmpty ? voice.name : "\(voice.name) (\(tags))"
            return SpeechVoiceOption(id: voice.identifier, name: voice.name, language: voice.language, displayName: display, tags: tags)
        }

        if jaList.isEmpty {
            jaList = [
                SpeechVoiceOption(id: "com.apple.voice.compact.ja-JP.Kyoko", name: "Kyoko", language: "ja-JP", displayName: "Kyoko (系统默认 · 女声)", tags: "系统默认 · 女声"),
                SpeechVoiceOption(id: "com.apple.voice.compact.ja-JP.Otoya", name: "Otoya", language: "ja-JP", displayName: "Otoya (男声)", tags: "男声"),
                SpeechVoiceOption(id: "com.apple.ttsbundle.siri_ja-JP", name: "Siri", language: "ja-JP", displayName: "Siri (官方音声)", tags: "官方音声")
            ]
        }

        // 2. 中语音色列表
        var zhList = allVoices.filter { $0.language.lowercased().hasPrefix("zh") }.map { voice -> SpeechVoiceOption in
            let gender = voice.gender == .female ? "女声" : (voice.gender == .male ? "男声" : "")
            let quality = voice.quality == .enhanced ? "高保真" : (voice.quality == .premium ? "超清" : "")
            let tags = [gender, quality].filter { !$0.isEmpty }.joined(separator: " · ")
            let display = tags.isEmpty ? voice.name : "\(voice.name) (\(tags))"
            return SpeechVoiceOption(id: voice.identifier, name: voice.name, language: voice.language, displayName: display, tags: tags)
        }

        if zhList.isEmpty {
            zhList = [
                SpeechVoiceOption(id: "com.apple.voice.compact.zh-CN.Tingting", name: "Tingting", language: "zh-CN", displayName: "婷婷 (普通话 · 女声)", tags: "普通话 · 女声"),
                SpeechVoiceOption(id: "com.apple.voice.compact.zh-CN.Yu-shu", name: "Yu-shu", language: "zh-CN", displayName: "玉舒 (高保真 · 女声)", tags: "高保真 · 女声"),
                SpeechVoiceOption(id: "com.apple.ttsbundle.siri_zh-CN", name: "Siri", language: "zh-CN", displayName: "Siri (官方音声)", tags: "官方音声")
            ]
        }

        self.japaneseVoices = jaList
        self.chineseVoices = zhList
    }
}

#Preview {
    NavigationStack {
        TtsSettingsView()
    }
}
