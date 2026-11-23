//
//  TypingPracticeSheet.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 单词跟打练习半屏/抽屉弹窗（1:1 对齐 Android 端 TypingPracticeDialog 结构与交互）
public struct TypingPracticeSheet: View {
    public let word: Word

    @Environment(\.dismiss) private var dismiss
    @State private var kanaInput: String = ""
    @State private var kanjiInput: String = ""
    @State private var feedbackState: FeedbackState = .hidden

    private enum Field: Hashable {
        case kana
        case kanji
    }

    @FocusState private var focusedField: Field?

    private enum FeedbackState {
        case hidden
        case correct
        case incorrect
    }

    public init(word: Word) {
        self.word = word
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. 目标单词卡片
                VStack(spacing: 8) {
                    Text(word.japanese)
                        .font(.system(size: 32, weight: .heavy, design: .serif))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text(word.hiragana)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                // 2. 校验反馈状态条
                HStack(spacing: 6) {
                    switch feedbackState {
                    case .correct:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 16, weight: .bold))
                        Text("完全正确！")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.green)
                    case .incorrect:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 16, weight: .bold))
                        Text("输入不匹配，请核对后再试")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                    case .hidden:
                        Text(" ")
                            .font(.system(size: 15))
                    }
                }
                .frame(height: 28)
                .animation(.easeInOut(duration: 0.25), value: feedbackState)

                // 3. 双输入框区域
                VStack(spacing: 14) {
                    // 平假名输入框
                    HStack {
                        TextField("输入假名读音", text: $kanaInput)
                            .focused($focusedField, equals: .kana)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .kanji
                            }
                            .onChange(of: kanaInput) { _, _ in
                                if feedbackState == .incorrect {
                                    feedbackState = .hidden
                                }
                            }

                        if !kanaInput.isEmpty {
                            Button {
                                kanaInput = ""
                                if feedbackState == .incorrect {
                                    feedbackState = .hidden
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(focusedField == .kana ? Color.blue : Color.primary.opacity(0.1), lineWidth: 1.5)
                    )

                    // 汉字写法输入框
                    HStack {
                        TextField("输入汉字写法", text: $kanjiInput)
                            .focused($focusedField, equals: .kanji)
                            .submitLabel(.done)
                            .onSubmit {
                                validateInputs()
                            }
                            .onChange(of: kanjiInput) { _, _ in
                                if feedbackState == .incorrect {
                                    feedbackState = .hidden
                                }
                            }

                        if !kanjiInput.isEmpty {
                            Button {
                                kanjiInput = ""
                                if feedbackState == .incorrect {
                                    feedbackState = .hidden
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(focusedField == .kanji ? Color.blue : Color.primary.opacity(0.1), lineWidth: 1.5)
                    )
                }

                Spacer()

                // 4. 底部行动按钮
                Button {
                    validateInputs()
                } label: {
                    Text("核对确认")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(feedbackState == .correct)
            }
            .padding(20)
            .navigationTitle("跟打练习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                focusedField = .kana
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func validateInputs() {
        focusedField = nil
        let trimmedKana = kanaInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKanji = kanjiInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedKana == word.hiragana && trimmedKanji == word.japanese {
            feedbackState = .correct
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                dismiss()
            }
        } else {
            feedbackState = .incorrect
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            #endif
        }
    }
}
