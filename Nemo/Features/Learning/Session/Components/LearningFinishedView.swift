import SwiftUI

/// 学习会话完成结算战报视图
public struct LearningFinishedView: View {
    public let stats: LearningSessionStats
    public let onFinish: () -> Void
    public let onRestart: () -> Void

    public init(
        stats: LearningSessionStats,
        onFinish: @escaping () -> Void,
        onRestart: @escaping () -> Void
    ) {
        self.stats = stats
        self.onFinish = onFinish
        self.onRestart = onRestart
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. Hero 核心成就区
                heroSection

                // 2. 今日词量明细与三段比例条
                breakdownSection

                // 3. 学习战报指标 Bento Grid
                statsGridSection

                // 4. 底部行动按钮
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.nemoGroupedBackground)
    }

    // MARK: - Hero 核心成就区
    private var heroSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.green)
            }
            .padding(.bottom, 4)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(stats.totalLearnedCount)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text("词")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Text("今日目标达成！")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            // 专注度胶囊徽章
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.caption.bold())
                Text(String(format: "平均每词 %.1f 秒", stats.averageSecondsPerWord))
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.04))
            .clipShape(Capsule())
        }
        .padding(.vertical, 12)
    }

    // MARK: - 今日词量构成与三段比例条
    private var breakdownSection: some View {
        NemoCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("词量掌握构成")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("100% 达成")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }

                // 三段比例进度条
                segmentedBar

                // 三分指标列
                HStack(alignment: .center) {
                    metricItem(title: "新词拓展", count: stats.newCount, color: .blue)
                    Divider().frame(height: 28)
                    metricItem(title: "顺畅巩固", count: stats.reviewCount, color: .green)
                    Divider().frame(height: 28)
                    metricItem(title: "反复攻克", count: stats.relearnCount, color: .orange)
                }
                .padding(.top, 4)
            }
        }
    }

    /// 三段比例胶囊进度条
    private var segmentedBar: some View {
        let total = max(stats.totalLearnedCount, 1)
        let reviewFrac = CGFloat(stats.reviewCount) / CGFloat(total)
        let newFrac = CGFloat(stats.newCount) / CGFloat(total)
        let relearnFrac = CGFloat(stats.relearnCount) / CGFloat(total)

        return GeometryReader { geo in
            let w = geo.size.width
            HStack(spacing: 2) {
                if reviewFrac > 0 {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.green)
                        .frame(width: max(w * reviewFrac - 2, 4))
                }
                if newFrac > 0 {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.blue)
                        .frame(width: max(w * newFrac - 2, 4))
                }
                if relearnFrac > 0 {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.orange)
                        .frame(width: max(w * relearnFrac - 2, 4))
                }
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }

    private func metricItem(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bento Grid 战报指标
    private var statsGridSection: some View {
        HStack(spacing: 12) {
            // 最高连击
            NemoCard(cornerRadius: 20, padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "flame.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(stats.maxCombo)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("次")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("最高连击")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 专注用时
            NemoCard(cornerRadius: 20, padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "clock.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }

                    Text(stats.formattedDuration)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("专注用时")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 连续打卡
            NemoCard(cornerRadius: 20, padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "calendar")
                            .font(.caption.bold())
                            .foregroundStyle(.purple)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(stats.dailyStreak)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("天")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("连续打卡")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 底部行动按钮
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: onFinish) {
                HStack(spacing: 6) {
                    Text("完成今日学习")
                        .font(.headline.weight(.bold))
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .nemoPrimaryActionButtonStyle()
            .nemoCapsuleButtonBorderShape()
            .tint(.blue)

            Button(action: onRestart) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.bold))
                    Text("学习下一组")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .nemoCapsuleButtonBorderShape()
            .tint(.secondary)
        }
        .padding(.top, 8)
    }
}

#Preview("Learning Finished View") {
    LearningFinishedView(
        stats: LearningMockData.mockStats,
        onFinish: {},
        onRestart: {}
    )
}
