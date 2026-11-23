import SwiftUI

import SwiftUI

/// 单词卡片正面视图
public struct WordCardFrontView: View {
    public let word: Word
    public let onSpeak: () -> Void
    public var onFlip: (() -> Void)? = nil
    public let isPlaying: Bool

    public init(
        word: Word,
        onSpeak: @escaping () -> Void,
        onFlip: (() -> Void)? = nil,
        isPlaying: Bool = false
    ) {
        self.word = word
        self.onSpeak = onSpeak
        self.onFlip = onFlip
        self.isPlaying = isPlaying
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // JLPT 等级药丸
                HStack {
                    Text(word.level.uppercased())
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(word.jlptLevel.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(word.jlptLevel.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                // 日文大字标题（Serif 衬线体）
                Text(word.japanese)
                    .font(.system(size: 48, weight: .heavy, design: .serif))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                    .padding(.horizontal, 16)

                // 读音平假名
                if word.hiragana != word.japanese {
                    Text(word.hiragana)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                }

                // 磨砂圆形发音按钮
                Button {
                    onSpeak()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(width: 48, height: 48)

                        Image(systemName: isPlaying ? "waveform" : "speaker.wave.2.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .symbolEffect(.pulse, isActive: isPlaying)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }

            Spacer()

            // 底部轻按翻转提示
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2.bold())
                Text("轻触卡片翻转")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.tertiary)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nemoSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture {
            onFlip?()
        }
    }
}

/// 单词卡片反面视图
public struct WordCardBackView: View {
    public let word: Word
    public let onSpeak: (String) -> Void
    public let isPlaying: Bool
    public let playingText: String?

    public init(
        word: Word,
        onSpeak: @escaping (String) -> Void,
        isPlaying: Bool = false,
        playingText: String? = nil
    ) {
        self.word = word
        self.onSpeak = onSpeak
        self.isPlaying = isPlaying
        self.playingText = playingText
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部词性与等级标签
                HStack(alignment: .center, spacing: 8) {
                    if let pos = word.pos, !pos.isEmpty {
                        Text(pos)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(word.level.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(word.jlptLevel.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(word.jlptLevel.accentColor.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    // 卡片反面快速发音按钮
                    Button {
                        onSpeak(word.japanese)
                    } label: {
                        Image(systemName: isPlaying && playingText == word.japanese ? "waveform" : "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 36, height: 36)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // 单词标题与假名
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.japanese)
                        .font(.system(size: 28, weight: .heavy, design: .serif))
                        .foregroundStyle(.primary)

                    if word.hiragana != word.japanese {
                        Text(word.hiragana)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .padding(.vertical, 2)

                // 中文释义区
                VStack(alignment: .leading, spacing: 6) {
                    Text("释义")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(word.chinese)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                }

                // 例句区（最多 3 组）
                let examples = collectExamples()
                if !examples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("例句")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        ForEach(examples.indices, id: \.self) { idx in
                            let item = examples[idx]
                            exampleRow(sentence: item.sentence, gloss: item.gloss)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nemoSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }

    /// 提取有效例句列表
    private func collectExamples() -> [(sentence: String, gloss: String?)] {
        var result: [(sentence: String, gloss: String?)] = []
        if let ex1 = word.example1, !ex1.isEmpty {
            result.append((ex1, word.gloss1))
        }
        if let ex2 = word.example2, !ex2.isEmpty {
            result.append((ex2, word.gloss2))
        }
        if let ex3 = word.example3, !ex3.isEmpty {
            result.append((ex3, word.gloss3))
        }
        return result
    }

    /// 单条例句卡片组件
    private func exampleRow(sentence: String, gloss: String?) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(sentence)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(.primary)

                if let gloss = gloss, !gloss.isEmpty {
                    Text(gloss)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onSpeak(sentence)
            } label: {
                Image(systemName: isPlaying && playingText == sentence ? "waveform" : "speaker.wave.1.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// 3D 翻转单词卡片组件
public struct LearningWordCardView: View {
    public let word: Word
    public let isFlipped: Bool
    public let onFlip: () -> Void
    public let onSpeak: (String) -> Void
    public let isPlaying: Bool
    public let playingText: String?

    public init(
        word: Word,
        isFlipped: Bool,
        onFlip: @escaping () -> Void,
        onSpeak: @escaping (String) -> Void,
        isPlaying: Bool = false,
        playingText: String? = nil
    ) {
        self.word = word
        self.isFlipped = isFlipped
        self.onFlip = onFlip
        self.onSpeak = onSpeak
        self.isPlaying = isPlaying
        self.playingText = playingText
    }

    public var body: some View {
        ZStack {
            WordCardFrontView(
                word: word,
                onSpeak: { onSpeak(word.japanese) },
                onFlip: onFlip,
                isPlaying: isPlaying && (playingText == word.japanese)
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .allowsHitTesting(!isFlipped)

            WordCardBackView(
                word: word,
                onSpeak: onSpeak,
                isPlaying: isPlaying,
                playingText: playingText
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .allowsHitTesting(isFlipped)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: isFlipped)
    }
}

#Preview("Word Card - Front") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        LearningWordCardView(
            word: LearningMockData.sampleWord,
            isFlipped: false,
            onFlip: {},
            onSpeak: { _ in }
        )
        .frame(height: 480)
        .padding(20)
    }
}

#Preview("Word Card - Back") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        LearningWordCardView(
            word: LearningMockData.sampleWord,
            isFlipped: true,
            onFlip: {},
            onSpeak: { _ in }
        )
        .frame(height: 480)
        .padding(20)
    }
}
