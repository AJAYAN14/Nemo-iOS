//
//  TtsSpeechService.swift
//  Nemo
//

import Foundation
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// 全局语音发音单例中枢
@MainActor
public final class TtsSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = TtsSpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private var onFinishedCallback: (() -> Void)?
    private var currentUtterance: AVSpeechUtterance?

    @Published public private(set) var isSpeaking: Bool = false
    @Published public private(set) var currentSpeakingText: String? = nil

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// 配置并激活音频播放会话
    private func configureAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // 忽略非致命音频会话激活异常
        }
        #endif
    }

    /// 释放音频会话
    private func deactivateAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // 忽略非致命音频会话释放异常
        }
        #endif
    }

    /// 朗读指定文本
    /// - Parameters:
    ///   - text: 待发音文本（单词发音请传入平假名以确保多音字音准）
    ///   - language: 语言代码（如 ja-JP 或 zh-CN）
    ///   - completion: 朗读完成或被中断时的回调
    public func speak(
        text: String,
        language: String = "ja-JP",
        completion: (() -> Void)? = nil
    ) {
        stop()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion?()
            return
        }

        self.onFinishedCallback = completion
        self.isSpeaking = true
        self.currentSpeakingText = text

        configureAudioSession()

        let utterance = AVSpeechUtterance(string: text)

        // 读取用户偏好设置
        let selectedVoiceName: String
        let rateMultiplier: Double
        let pitchMultiplier: Double

        if language.lowercased().hasPrefix("ja") {
            selectedVoiceName = UserDefaults.standard.string(forKey: "settings_tts_voice_name") ?? "Kyoko"
        } else {
            selectedVoiceName = UserDefaults.standard.string(forKey: "settings_tts_chinese_voice_name") ?? "Tingting"
        }

        let storedSpeed = UserDefaults.standard.double(forKey: "settings_tts_speed")
        rateMultiplier = storedSpeed > 0 ? storedSpeed : 1.0

        let storedPitch = UserDefaults.standard.double(forKey: "settings_tts_pitch")
        pitchMultiplier = storedPitch > 0 ? storedPitch : 1.0

        let defaultRate = Double(AVSpeechUtteranceDefaultSpeechRate)
        utterance.rate = Float(min(max(rateMultiplier * defaultRate, Double(AVSpeechUtteranceMinimumSpeechRate)), Double(AVSpeechUtteranceMaximumSpeechRate)))
        utterance.pitchMultiplier = Float(min(max(pitchMultiplier, 0.5), 2.0))

        if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.lowercased().hasPrefix(language.prefix(2).lowercased()) &&
            ($0.name.localizedCaseInsensitiveContains(selectedVoiceName) || $0.identifier.localizedCaseInsensitiveContains(selectedVoiceName))
        }) {
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(language: language.hasPrefix("ja") ? "ja-JP" : "zh-CN") {
            utterance.voice = fallbackVoice
        }

        synthesizer.speak(utterance)
        self.currentUtterance = utterance
    }

    /// 立即停止发音
    public func stop() {
        self.currentUtterance = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentSpeakingText = nil
        let callback = onFinishedCallback
        onFinishedCallback = nil
        callback?()
        deactivateAudioSession()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard utterance === self.currentUtterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            self.currentSpeakingText = nil
            let callback = self.onFinishedCallback
            self.onFinishedCallback = nil
            callback?()
            self.deactivateAudioSession()
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard utterance === self.currentUtterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            self.currentSpeakingText = nil
            let callback = self.onFinishedCallback
            self.onFinishedCallback = nil
            callback?()
            self.deactivateAudioSession()
        }
    }
}
