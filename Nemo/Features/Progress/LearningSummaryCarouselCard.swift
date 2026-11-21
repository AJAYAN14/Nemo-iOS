//
//  LearningSummaryCarouselCard.swift
//  Nemo
//
//  Created by Antigravity on 2026/11/21.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 视觉微缩指示类型（对应 Android BentoVisualType）
private enum BentoVisualType {
    case progress
    case dots
    case bars
}

/// Bento 统计单项数据模型
private struct BentoMetric {
    let label: String
    let value: String
    let unit: String
}

/// Bento 页面配置模型
private struct BentoPageModel {
    let title: String
    let systemIcon: String
    let accentColor: Color
    let main: BentoMetric
    let topRight: BentoMetric
    let bottomRight: BentoMetric
    let visualType: BentoVisualType
}

/// 学习摘要卡片（3页 Bento Grid 轮播卡片，100% 对齐 Android LearningSummaryCard）
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
            // 页 1: 日间概览 (Daily Overview)
            BentoPageModel(
                title: "日间概览",
                systemIcon: "calendar.badge.clock",
                accentColor: .blue,
                main: BentoMetric(label: "今日已学", value: "\(todayLearned)", unit: "项"),
                topRight: BentoMetric(label: "待复习", value: "\(dueCount)", unit: "项"),
                bottomRight: BentoMetric(label: "目标完成度", value: "\(todayProgress)", unit: "%"),
                visualType: .progress
            ),
            // 页 2: 学习轨迹 (Learning Track)
            BentoPageModel(
                title: "学习轨迹",
                systemIcon: "chart.xyaxis.line",
                accentColor: .green,
                main: BentoMetric(label: "连续学习", value: "\(studyStreak)", unit: "天"),
                topRight: BentoMetric(label: "累计掌握", value: "\(masteredCount)", unit: "项"),
                bottomRight: BentoMetric(label: "待学习", value: "\(unmasteredCount)", unit: "项"),
                visualType: .dots
            ),
            // 页 3: 成长总览 (Growth Overview)
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
            // 轮播容器（高度固定 172pt）
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    bentoGrid(for: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 172)

            // 动态滑动点阵指示器（跟随激活页主题色）
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

    // MARK: - Bento 栅格布局 (主卡 1.45 : 副卡 1.0)
    private func bentoGrid(for model: BentoPageModel) -> some View {
        HStack(spacing: 10) {
            // 左侧大卡 (占比约 1.45)
            mainTile(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 右侧上下堆叠副卡组 (占比约 1.0)
            VStack(spacing: 10) {
                subTile(metric: model.topRight)
                subTile(metric: model.bottomRight)
            }
            .frame(width: 135)
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - 左侧主卡 (Main Tile)
    private func mainTile(model: BentoPageModel) -> some View {
        ZStack(alignment: .bottomLeading) {
            // 背景底色与 G2 连续圆角
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(model.accentColor)

            // 右上角背景半透明水印大图标
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

            // 底部内容区
            VStack(alignment: .leading, spacing: 6) {
                // 顶部微缩图形
                visualHint(type: model.visualType)

                // 标签文案
                Text(model.main.label)
                    .font(.caption2.bold())
                    .tracking(0.5)
                    .foregroundStyle(Color.white.opacity(0.85))

                // 数值与单位
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

    // MARK: - 右侧副卡 (Sub Tile)
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

    // MARK: - 3 种微缩图形指示
    @ViewBuilder
    private func visualHint(type: BentoVisualType) -> some View {
        switch type {
        case .progress:
            // 苹果官方原生微缩线性进度条 (Apple HIG 原生标准控件)
            ProgressView(value: 0.7)
                .progressViewStyle(.linear)
                .tint(.white)
                .background(Color.white.opacity(0.24))
                .clipShape(Capsule())
                .frame(height: 4)
                .padding(.bottom, 2)

        case .dots:
            // 7 日点阵指示
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
            // 4 柱微型趋势条
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

    // MARK: - 动态指示器
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
