//
//  LearningSummaryCarouselCard.swift
//  Nemo
//

import SwiftUI

/// 视觉微缩图形指示样式类型
private enum BentoVisualType {
    /// 线性进度条
    case progress
    /// 点阵指示器
    case dots
    /// 柱状趋势图
    case bars
}

/// 便当盒单项指标数据模型
private struct BentoMetric {
    let label: String
    let value: String
    let unit: String
}

/// 便当盒轮播页配置模型
private struct BentoPageModel {
    let title: String
    let systemIcon: String
    let accentColor: Color
    let main: BentoMetric
    let topRight: BentoMetric
    let bottomRight: BentoMetric
    let visualType: BentoVisualType
}

/// 学习摘要轮播卡片视图
///
/// 采用 3 页便当盒（Bento Grid）网格设计，支持自动定时与手动滑动手势切换，直观展示日间概览、学习轨迹与成长总览。
public struct LearningSummaryCarouselCard: View {
    public let progress: Double
    public let masteredCount: Int
    public let totalWords: Int
    public let todayLearned: Int
    public let dailyGoal: Int
    public let unmasteredCount: Int
    public let studyStreak: Int
    public let dueCount: Int
    public let totalStudyDays: Int
    public let weekStudyDays: Int

    @State private var currentPage: Int = 0

    /// 初始化学习摘要轮播卡片
    /// - Parameters:
    ///   - progress: 总体学习掌握度比例（0.0 至 1.0）
    ///   - masteredCount: 已完全掌握的词汇或语法条目数
    ///   - totalWords: 当前词库条目总数
    ///   - todayLearned: 今日已完成学习的新条目数
    ///   - dailyGoal: 每日新学目标设定值
    ///   - unmasteredCount: 尚待掌握的条目总数
    ///   - studyStreak: 连续自测或打卡天数
    ///   - dueCount: 艾宾浩斯复习队列中当前待复习总数
    ///   - totalStudyDays: 历史累计学习天数
    ///   - weekStudyDays: 本周内已完成学习的天数
    public init(
        progress: Double = 0.65,
        masteredCount: Int = 780,
        totalWords: Int = 1200,
        todayLearned: Int = 20,
        dailyGoal: Int = 20,
        unmasteredCount: Int = 420,
        studyStreak: Int = 12,
        dueCount: Int = 14,
        totalStudyDays: Int = 45,
        weekStudyDays: Int = 6
    ) {
        self.progress = progress
        self.masteredCount = masteredCount
        self.totalWords = totalWords
        self.todayLearned = todayLearned
        self.dailyGoal = dailyGoal
        self.unmasteredCount = unmasteredCount
        self.studyStreak = studyStreak
        self.dueCount = dueCount
        self.totalStudyDays = totalStudyDays
        self.weekStudyDays = weekStudyDays
    }

    private var todayProgress: Int {
        guard dailyGoal > 0 else { return 0 }
        return Int((Double(todayLearned) / Double(dailyGoal)) * 100)
    }

    private var pages: [BentoPageModel] {
        [
            // 第 1 页：日间概览
            BentoPageModel(
                title: "日间概览",
                systemIcon: "calendar.badge.clock",
                accentColor: .blue,
                main: BentoMetric(label: "今日已学", value: "\(todayLearned)", unit: "项"),
                topRight: BentoMetric(label: "待复习", value: "\(dueCount)", unit: "项"),
                bottomRight: BentoMetric(label: "目标完成度", value: "\(todayProgress)", unit: "%"),
                visualType: .progress
            ),
            // 第 2 页：学习轨迹
            BentoPageModel(
                title: "学习轨迹",
                systemIcon: "chart.xyaxis.line",
                accentColor: .green,
                main: BentoMetric(label: "连续学习", value: "\(studyStreak)", unit: "天"),
                topRight: BentoMetric(label: "累计掌握", value: "\(masteredCount)", unit: "项"),
                bottomRight: BentoMetric(label: "待学习", value: "\(unmasteredCount)", unit: "项"),
                visualType: .dots
            ),
            // 第 3 页：成长总览
            BentoPageModel(
                title: "成长总览",
                systemIcon: "chart.line.uptrend.xyaxis",
                accentColor: .orange,
                main: BentoMetric(label: "总进度", value: "\(Int(progress * 100))", unit: "%"),
                topRight: BentoMetric(label: "累计学习", value: "\(totalStudyDays)", unit: "天"),
                bottomRight: BentoMetric(label: "本周学习", value: "\(weekStudyDays)", unit: "天"),
                visualType: .bars
            )
        ]
    }

    public var body: some View {
        VStack(spacing: 12) {
            // 轮播页面容器
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    bentoGrid(for: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 172)

            // 动态滑动点阵指示器
            slidingDotIndicator
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    currentPage = (currentPage + 1) % pages.count
                }
            }
        }
    }

    // MARK: - Bento 网格布局（主卡 1.45 : 副卡 1.0）
    private func bentoGrid(for model: BentoPageModel) -> some View {
        HStack(spacing: 10) {
            // 左侧大卡（主指标）
            mainTile(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 右侧上下堆叠副卡组
            VStack(spacing: 10) {
                subTile(metric: model.topRight)
                subTile(metric: model.bottomRight)
            }
            .frame(width: 135)
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - 左侧主卡
    private func mainTile(model: BentoPageModel) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(model.accentColor)

            // 右上角背景半透明水印图标
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: model.systemIcon)
                        .font(.system(size: 68, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.16))
                        .offset(x: 10, y: -6)
                }
                Spacer()
            }
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                visualHint(type: model.visualType)

                Text(model.main.label)
                    .font(.caption2.bold())
                    .tracking(0.5)
                    .foregroundStyle(Color.white.opacity(0.85))

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(model.main.value)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)

                    Text(model.main.unit)
                        .font(.callout.bold())
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - 右侧副卡
    private func subTile(metric: BentoMetric) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.nemoSecondaryGroupedBackground)

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.label)
                    .font(.caption2.bold())
                    .tracking(0.5)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(metric.value)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Text(metric.unit)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - 微缩图形指示器
    @ViewBuilder
    private func visualHint(type: BentoVisualType) -> some View {
        switch type {
        case .progress:
            ProgressView(value: 0.7)
                .progressViewStyle(.linear)
                .tint(.white)
                .background(Color.white.opacity(0.24))
                .clipShape(Capsule())
                .frame(height: 4)
                .padding(.bottom, 2)

        case .dots:
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(index < 5 ? Color.white.opacity(0.95) : Color.white.opacity(0.25))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 2)

        case .bars:
            HStack(alignment: .bottom, spacing: 4) {
                barView(height: 8, opacity: 0.28)
                barView(height: 12, opacity: 0.5)
                barView(height: 16, opacity: 1.0)
                barView(height: 10, opacity: 0.65)
            }
            .frame(height: 16)
        }
    }

    private func barView(height: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color.white.opacity(opacity))
            .frame(width: 4, height: height)
    }

    // MARK: - 动态滑动点阵指示器
    private var slidingDotIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? pages[currentPage].accentColor : Color.secondary.opacity(0.25))
                    .frame(width: index == currentPage ? 18 : 6, height: 6)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            currentPage = index
                        }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
        .padding(.top, 2)
    }
}

#Preview {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()
        LearningSummaryCarouselCard()
            .padding()
    }
}
