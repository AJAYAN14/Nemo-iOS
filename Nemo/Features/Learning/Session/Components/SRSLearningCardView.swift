//
//  SRSLearningCardView.swift
//  Nemo
//

import SwiftUI

/// 学习状态卡片徽章类型枚举
public enum CardBadgeType: String, Sendable {
    case new = "新学"
    case learning = "在学"
    case review = "复习"
    case relearn = "重学"

    public var tintColor: Color {
        switch self {
        case .new:
            return Color.blue
        case .learning:
            return Color.cyan
        case .review:
            return Color.green
        case .relearn:
            return Color.orange
        }
    }
}

/// 细腻点阵背景绘制视图（中央圆形呼吸避让）
public struct DotMatrixBackgroundView: View {
    public let dotSpacing: CGFloat
    public let dotRadius: CGFloat
    public let clearRadius: CGFloat

    public init(
        dotSpacing: CGFloat = 18.0,
        dotRadius: CGFloat = 1.3,
        clearRadius: CGFloat = 80.0
    ) {
        self.dotSpacing = dotSpacing
        self.dotRadius = dotRadius
        self.clearRadius = clearRadius
    }

    public var body: some View {
        Canvas { context, size in
            let midX = size.width / 2.0
            let midY = size.height / 2.0

            let cols = Int(size.width / dotSpacing) + 1
            let rows = Int(size.height / dotSpacing) + 1

            let startX = (size.width - CGFloat(cols - 1) * dotSpacing) / 2.0
            let startY = (size.height - CGFloat(rows - 1) * dotSpacing) / 2.0

            for col in 0..<cols {
                for row in 0..<rows {
                    let x = startX + CGFloat(col) * dotSpacing
                    let y = startY + CGFloat(row) * dotSpacing

                    let dx = x - midX
                    let dy = y - midY
                    let distance = sqrt(dx * dx + dy * dy)
                    let ratio = distance / clearRadius

                    // 中央正圆避让与渐变过渡
                    if ratio >= 0.85 {
                        let alpha = min(max((ratio - 0.85) / 0.5, 0.0), 1.0) * 0.12
                        let dotRect = CGRect(
                            x: x - dotRadius,
                            y: y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2
                        )
                        context.fill(Path(ellipseIn: dotRect), with: .color(Color.primary.opacity(alpha)))
                    }
                }
            }
        }
    }
}

/// SRS 核心学习卡片视图
///
/// 严格对齐 Android 端 `SRSLearningCard` 架构：
/// 1. 顶部问题卡片（Question Area）：JLPT 徽章、400米跑道进度条、状态徽章、48pt 衬线体汉字大字与读音思考提示；
/// 2. 中部思考占位区（Think Area）：点阵呼吸网格与灵感灯泡图标；
/// 3. 下部答案详情区（Answer Area）：点击显示答案后垂直平滑展开词性、释义、发音与双语例句。
public struct SRSLearningCardView: View {
    public let word: Word
    public let isAnswerShown: Bool
    public let badgeType: CardBadgeType
    public let progress: Double
    public let queueCounts: QueueCountState
    public let onRevealAnswer: () -> Void
    public let onSpeakWord: () -> Void
    public let onSpeakText: (String) -> Void
    public let isPlayingAudio: Bool
    public let playingText: String?
    public var onTrackClick: (() -> Void)?

    public init(
        word: Word,
        isAnswerShown: Bool,
        badgeType: CardBadgeType = .new,
        progress: Double = 0.0,
        queueCounts: QueueCountState = QueueCountState(),
        onRevealAnswer: @escaping () -> Void,
        onSpeakWord: @escaping () -> Void,
        onSpeakText: @escaping (String) -> Void = { _ in },
        isPlayingAudio: Bool = false,
        playingText: String? = nil,
        onTrackClick: (() -> Void)? = nil
    ) {
        self.word = word
        self.isAnswerShown = isAnswerShown
        self.badgeType = badgeType
        self.progress = progress
        self.queueCounts = queueCounts
        self.onRevealAnswer = onRevealAnswer
        self.onSpeakWord = onSpeakWord
        self.onSpeakText = onSpeakText
        self.isPlayingAudio = isPlayingAudio
        self.playingText = playingText
        self.onTrackClick = onTrackClick
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. 上部【问题卡片】(Question Area)
                questionCardSection

                // 2. 中部【思考占位卡片】或【答案详情卡片】(Sticker / Answer Area)
                if !isAnswerShown {
                    thinkPlaceholderSection
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    answerDetailsSection
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 20)),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 110) // 预留底部操作栏避让安全距离
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAnswerShown)
    }

    // MARK: - 1. 问题卡片 (Question Area)
    private var questionCardSection: some View {
        VStack(spacing: 20) {
            // 顶栏三段式：JLPT 徽章 (左) + 跑道进度条 (中) + 状态徽章 (右)
            HStack(alignment: .center) {
                // 左侧 JLPT 徽章 (高 34pt)
                Text(word.level.uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(word.jlptLevel.accentColor)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(word.jlptLevel.accentColor.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                // 中间 400米跑道进度指示条
                LearningTrackProgressIndicator(
                    progress: progress,
                    queueCounts: queueCounts,
                    onTrackClick: onTrackClick
                )

                Spacer()

                // 右侧状态徽章 (高 34pt)
                Text(badgeType.rawValue)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(badgeType.tintColor)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(badgeType.tintColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // 中央日文大字 (48pt Heavy 衬线体)
            VStack(spacing: 8) {
                Text(word.japanese)
                    .font(.system(size: 48, weight: .heavy, design: .serif))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                    .padding(.horizontal, 12)

                // 答案展开态显示蓝色平假名，未展开态显示思考提示
                if isAnswerShown {
                    Text(word.hiragana)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundStyle(Color.blue)
                        .transition(.opacity)
                } else {
                    Text("回想单词发音")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.7))
                        .padding(.top, 2)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 16)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.nemoSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    // MARK: - 2. 思考占位卡片 (Think Area)
    private var thinkPlaceholderSection: some View {
        Button {
            onRevealAnswer()
        } label: {
            ZStack {
                // 点阵背景与呼吸正圆
                DotMatrixBackgroundView(dotSpacing: 18, dotRadius: 1.3, clearRadius: 80)

                // 中央灵感灯泡图标
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 78))
                        .foregroundStyle(Color.orange.opacity(0.85))
                        .shadow(color: Color.orange.opacity(0.2), radius: 16, x: 0, y: 6)

                    Text("轻触查看答案")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            .background(Color.nemoSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. 答案详情卡片 (Answer Area)
    private var answerDetailsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 顶栏：词性徽章与发音按钮
            HStack(alignment: .center) {
                // 词性徽章
                if let pos = word.pos, !pos.isEmpty {
                    Text(pos)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.blue)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                // 单词朗读按钮 (44×44pt)
                Button {
                    onSpeakWord()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: isPlayingAudio && playingText == word.japanese ? "waveform" : "speaker.wave.2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.blue)
                            .symbolEffect(.pulse, isActive: isPlayingAudio && playingText == word.japanese)
                    }
                }
                .buttonStyle(.plain)
            }

            Divider()

            // 中文释义区块
            VStack(alignment: .leading, spacing: 6) {
                Text("释义")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                Text(word.chinese)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
            }

            // 双语精选例句区块 (最多 3 组)
            let examples = collectExamples()
            if !examples.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("例句")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)

                    ForEach(examples.indices, id: \.self) { idx in
                        let item = examples[idx]
                        exampleSentenceRow(sentence: item.sentence, gloss: item.gloss)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nemoSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
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

    /// 单条例句视图
    private func exampleSentenceRow(sentence: String, gloss: String?) -> some View {
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
                onSpeakText(sentence)
            } label: {
                Image(systemName: isPlayingAudio && playingText == sentence ? "waveform" : "speaker.wave.1.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview("SRS Card - Question & Think") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        SRSLearningCardView(
            word: LearningMockData.sampleWord,
            isAnswerShown: false,
            badgeType: .new,
            progress: 0.35,
            queueCounts: QueueCountState(newCount: 8, learningCount: 2, reviewCount: 4, relearnCount: 1),
            onRevealAnswer: {},
            onSpeakWord: {}
        )
    }
}

#Preview("SRS Card - Answer Revealed") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        SRSLearningCardView(
            word: LearningMockData.sampleWord,
            isAnswerShown: true,
            badgeType: .learning,
            progress: 0.65,
            queueCounts: QueueCountState(newCount: 4, learningCount: 5, reviewCount: 6, relearnCount: 0),
            onRevealAnswer: {},
            onSpeakWord: {}
        )
    }
}
