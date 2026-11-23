import SwiftUI

/// 单个 SRS 评分胶囊按钮
public struct LearningSRSRatingButton: View {
    public let quality: SRSRatingQuality
    public let intervalText: String
    public let onClick: () -> Void

    public init(
        quality: SRSRatingQuality,
        intervalText: String,
        onClick: @escaping () -> Void
    ) {
        self.quality = quality
        self.intervalText = intervalText
        self.onClick = onClick
    }

    public var body: some View {
        Button(action: onClick) {
            VStack(spacing: 3) {
                Text(quality.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(quality.themeColor)

                Text(intervalText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(quality.themeColor.opacity(0.85))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(quality.containerBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(quality.themeColor.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("SRS Rating Buttons") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        HStack(spacing: 8) {
            LearningSRSRatingButton(quality: .again, intervalText: "< 1m", onClick: {})
            LearningSRSRatingButton(quality: .hard, intervalText: "10m", onClick: {})
            LearningSRSRatingButton(quality: .good, intervalText: "1d", onClick: {})
            LearningSRSRatingButton(quality: .easy, intervalText: "4d", onClick: {})
        }
        .padding()
    }
}
