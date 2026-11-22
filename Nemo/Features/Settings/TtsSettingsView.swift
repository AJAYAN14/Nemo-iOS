//
//  TtsSettingsView.swift
//  Nemo
//
//  Created by Nemo Team on 2026-11-22.
//

import SwiftUI
import AVFoundation

/// 语音发音人描述项
public struct SpeechVoiceOption: NemoPickerItem, Hashable {
    public let id: String
    public let name: String
    public let language: String
    public let displayName: String
    public let tags: String

    public var title: String { name }
    public var subtitle: String? {
        language.lowercased().hasPrefix("ja") ? "日语 · 神经引擎合成" : "普通话 · 神经引擎合成"
    }
    public var badge: String? { tags.isEmpty ? nil : tags }

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
    /// 当前正在独立试听的发音人名称（用于抽屉内单行试听状态联动）
    var previewingVoiceName: String? = nil

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// 停止所有朗读任务
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlayingJapanese = false
        isPlayingChinese = false
        previewingVoiceName = nil
        deactivateAudioSession()
    }

    /// 配置并激活音频播放会话
    ///
    /// 将音频会话类别设为播放模式，确保设备处于物理静音状态下仍能正常播发试听语音。
    private func prepareAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // 忽略非关键音频会话配置异常，确保语音任务正常流转
        }
    }

    /// 释放音频会话占用
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // 忽略清理阶段异常
        }
    }

    /// 在抽屉中试听指定发音人
    /// - Parameters:
    ///   - name: 发音人代号
    ///   - sampleText: 朗读例句
    ///   - language: 语言代码前缀 (ja 或 zh)
    ///   - rate: 语速倍率
    ///   - pitch: 音调倍率
    func previewVoice(
        name: String,
        sampleText: String,
        language: String,
        rate: Double,
        pitch: Double
    ) {
        if previewingVoiceName == name {
            stop()
            return
        }

        stop()
        previewingVoiceName = name

        let utterance = AVSpeechUtterance(string: sampleText)
        let defaultRate = AVSpeechUtteranceDefaultSpeechRate
        utterance.rate = Float(min(max(rate * Double(defaultRate), Double(AVSpeechUtteranceMinimumSpeechRate)), Double(AVSpeechUtteranceMaximumSpeechRate)))
        utterance.pitchMultiplier = Float(min(max(pitch, 0.5), 2.0))

        if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.lowercased().hasPrefix(language.prefix(2).lowercased()) &&
            ($0.name.localizedCaseInsensitiveContains(name) || $0.identifier.localizedCaseInsensitiveContains(name))
        }) {
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(language: language.hasPrefix("ja") ? "ja-JP" : "zh-CN") {
            utterance.voice = fallbackVoice
        }

        prepareAudioSession()
        synthesizer.speak(utterance)
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

        prepareAudioSession()
        synthesizer.speak(utterance)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlayingJapanese = false
            self.isPlayingChinese = false
            self.previewingVoiceName = nil
            self.deactivateAudioSession()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlayingJapanese = false
            self.isPlayingChinese = false
            self.previewingVoiceName = nil
            self.deactivateAudioSession()
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
    private let sampleJapaneseText = "これは音声テストです。"
    private let sampleChineseText = "这是中文语音测试。"

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

                        Image(systemName: "chevron.forward")
                            .font(.footnote.weight(.semibold))
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

                        Image(systemName: "chevron.forward")
                            .font(.footnote.weight(.semibold))
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
        .sheet(item: $activeVoiceSheet, onDismiss: {
            previewManager.stop()
        }) { target in
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

    // MARK: - 语音选择抽屉弹窗（接入通用 NemoItemPickerSheet）

    @ViewBuilder
    private func voiceSelectionDrawerSheet(for target: TtsVoiceSheetTarget) -> some View {
        let voices = target == .japanese ? japaneseVoices : chineseVoices
        let currentSelectedName = target == .japanese ? selectedJapaneseVoice : selectedChineseVoice
        let sampleText = target == .japanese ? sampleJapaneseText : sampleChineseText

        NemoItemPickerSheet(
            title: target.title,
            items: voices,
            selectedID: currentSelectedName,
            onSelect: { voice in
                if target == .japanese {
                    selectedJapaneseVoice = voice.name
                } else {
                    selectedChineseVoice = voice.name
                }
                previewManager.stop()
                hapticSelectionTrigger.toggle()
                activeVoiceSheet = nil
            },
            onClose: {
                previewManager.stop()
                activeVoiceSheet = nil
            },
            trailingAction: { voice in
                let isPreviewing = previewManager.previewingVoiceName == voice.name

                Button {
                    previewManager.previewVoice(
                        name: voice.name,
                        sampleText: sampleText,
                        language: target.rawValue,
                        rate: speechRate,
                        pitch: speechPitch
                    )
                } label: {
                    Image(systemName: isPreviewing ? "speaker.wave.3.fill" : "play.circle")
                        .font(.title3)
                        .foregroundStyle(isPreviewing ? Color.accentColor : Color.secondary)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("试听 \(voice.name) 发音")
            }
        )
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
