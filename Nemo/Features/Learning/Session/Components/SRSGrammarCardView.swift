//
//  SRSGrammarCardView.swift
//  Nemo
//

import SwiftUI

/// SRS 语法核心学习卡片视图
///
/// 严格对齐 Android 端 `SRSGrammarCard` 架构：
/// 1. 顶部问题卡片（Question Area）：JLPT 等级、跑道进度指示器、学习状态徽章以及语法句型大字；
/// 2. 中部思考占位区（Think Area）：点阵呼吸遮罩与灵感灯泡提示；
/// 3. 下部答案详情区（Answer Area）：点击显示答案后垂直展开接续形式、语法释义、例句与 TIPS。
public struct SRSGrammarCardView: View {
    public let grammar: Grammar
    public let isAnswerShown: Bool
    public let badgeType: CardBadgeType
    public let progress: Double
    public let queueCounts: QueueCountState
    public let onRevealAnswer: () -> Void
    public let onSpeakText: (String) -> Void
    public let isPlayingAudio: Bool
    public let playingText: String?
    public var onTrackClick: (() -> Void)?

    public init(
        grammar: Grammar,
        isAnswerShown: Bool,
        badgeType: CardBadgeType = .new,
        progress: Double = 0.0,
        queueCounts: QueueCountState = QueueCountState(),
        onRevealAnswer: @escaping () -> Void,
        onSpeakText: @escaping (String) -> Void = { _ in },
        isPlayingAudio: Bool = false,
        playingText: String? = nil,
        onTrackClick: (() -> Void)? = nil
    ) {
        self.grammar = grammar
        self.isAnswerShown = isAnswerShown
        self.badgeType = badgeType
        self.progress = progress
        self.queueCounts = queueCounts
        self.onRevealAnswer = onRevealAnswer
        self.onSpeakText = onSpeakText
        self.isPlayingAudio = isPlayingAudio
        self.playingText = playingText
        self.onTrackClick = onTrackClick
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // 1. 顶部语法问题主卡片
                questionCardSection

                // 2. 中部思考区与答案滑出区
                if isAnswerShown {
                    answerCardSection
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                } else {
                    thinkPlaceholderSection
                        .transition(.opacity)
                }

                // 底部留出操作栏安全间距
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
    }

    // MARK: - 1. 顶部问题卡片
    private var questionCardSection: some View {
        NemoCard(cornerRadius: 24, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                // 顶栏：JLPT 徽章 + 跑道指示条 + 状态徽章
                HStack(alignment: .center) {
                    Text(grammar.level.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    // 400米跑道进度指示器
                    LearningTrackProgressIndicator(
                        progress: progress,
                        queueCounts: queueCounts,
                        onTrackClick: onTrackClick
                    )

                    Spacer()

                    // 卡片阶段徽章
                    Text(badgeType.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(badgeType.tintColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeType.tintColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                Divider()
                    .opacity(0.5)

                // 核心语法句型
                VStack(spacing: 8) {
                    Text(grammar.title)
                        .font(.system(size: 34, weight: .heavy, design: .serif))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)

                    Text(isAnswerShown ? "句型接续与核心语义" : "仔细思考句型的接续形式与表达含义")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 2. 思考占位卡片（未显示答案时）
    private var thinkPlaceholderSection: some View {
        Button {
            onRevealAnswer()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.nemoSecondaryGroupedBackground)

                DotMatrixBackgroundView(dotSpacing: 18, dotRadius: 1.3, clearRadius: 75)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                    }

                    Text("轻触或点击下方查看语法解析")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 40)
            }
            .frame(minHeight: 220)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. 答案展开详情卡片
    private var answerCardSection: some View {
        VStack(spacing: 12) {
            // 接续形式卡片
            if !grammar.connectionText.isEmpty {
                NemoCard(cornerRadius: 20, padding: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                            Text("接续方式")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }

                        Text(grammar.connectionText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // 核心释义卡片
            NemoCard(cornerRadius: 20, padding: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        Text("含义与用法")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }

                    Text(grammar.explanationText.isEmpty ? "暂无详细释义" : grammar.explanationText)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 额外考点或说明卡片
            if let note = grammar.content?.usages?.first?.notes, !note.isEmpty {
                NemoCard(cornerRadius: 20, padding: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                            Text("注意事项 / TIPS")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                        }

                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
