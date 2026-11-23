import SwiftUI

/// SRS 评价底部操作栏（支持“显示答案”与 4 档评分平滑过渡）
public struct LearningSRSActionBar: View {
    public let isFlipped: Bool
    public let ratingIntervals: [SRSRatingQuality: String]
    public let delayRemainingSeconds: Int
    public let onShowAnswer: () -> Void
    public let onRating: (SRSRatingQuality) -> Void

    public init(
        isFlipped: Bool,
        ratingIntervals: [SRSRatingQuality: String],
        delayRemainingSeconds: Int = 0,
        onShowAnswer: @escaping () -> Void,
        onRating: @escaping (SRSRatingQuality) -> Void
    ) {
        self.isFlipped = isFlipped
        self.ratingIntervals = ratingIntervals
        self.delayRemainingSeconds = delayRemainingSeconds
        self.onShowAnswer = onShowAnswer
        self.onRating = onRating
    }

    public var body: some View {
        ZStack {
            if !isFlipped {
                // 1. 未翻面：全宽“显示答案”大胶囊按钮 (支持等待倒计时)
                Button {
                    if delayRemainingSeconds == 0 {
                        onShowAnswer()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: delayRemainingSeconds > 0 ? "clock" : "sparkles")
                            .font(.system(size: 16, weight: .bold))

                        Text(delayRemainingSeconds > 0 ? "显示答案 (\(delayRemainingSeconds)s)" : "显示答案")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .nemoPrimaryActionButtonStyle()
                .nemoCapsuleButtonBorderShape()
                .tint(delayRemainingSeconds > 0 ? Color.secondary : Color.accentColor)
                .disabled(delayRemainingSeconds > 0)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // 2. 翻面：4 档评分按钮网格
                HStack(spacing: 8) {
                    ForEach(SRSRatingQuality.allCases) { quality in
                        let interval = ratingIntervals[quality] ?? "--"
                        LearningSRSRatingButton(
                            quality: quality,
                            intervalText: interval,
                            onClick: { onRating(quality) }
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFlipped)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview("SRS Action Bar - Unflipped") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        VStack {
            Spacer()
            LearningSRSActionBar(
                isFlipped: false,
                ratingIntervals: LearningMockData.mockRatingIntervals,
                onShowAnswer: {},
                onRating: { _ in }
            )
        }
    }
}

#Preview("SRS Action Bar - Flipped") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        VStack {
            Spacer()
            LearningSRSActionBar(
                isFlipped: true,
                ratingIntervals: LearningMockData.mockRatingIntervals,
                onShowAnswer: {},
                onRating: { _ in }
            )
        }
    }
}
