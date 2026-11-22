//
//  ProgressHomeView.swift
//  Nemo
//

import SwiftUI

/// 学习进度仪表盘主视图
///
/// 汇总展示艾宾浩斯复习曲线、学习轨迹统计、核心词库入口与难点突破专项。
public struct ProgressHomeView: View {
    @State private var totalProgressFraction: Double = 0.65
    @State private var totalMastered: Int = 780
    @State private var totalWords: Int = 1200
    @State private var todayLearned: Int = 20
    @State private var dailyGoal: Int = 20
    @State private var dailyStreak: Int = 12
    @State private var totalDue: Int = 14
    @State private var totalStudyDays: Int = 45
    @State private var weekStudyDays: Int = 6

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 学习摘要便当盒轮播卡片
                learningSummarySection

                // 2. 统计与分析 分区
                statsAnalysisSection

                // 3. 资料与词库 分区
                materialsSection

                // 4. 强化与突破 分区
                reinforceSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.nemoGroupedBackground)
        .navigationTitle("进度")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 学习摘要卡片
    private var learningSummarySection: some View {
        LearningSummaryCarouselCard(
            progress: totalProgressFraction,
            masteredCount: totalMastered,
            totalWords: totalWords,
            todayLearned: todayLearned,
            dailyGoal: dailyGoal,
            unmasteredCount: max(0, totalWords - totalMastered),
            studyStreak: dailyStreak,
            dueCount: totalDue,
            totalStudyDays: totalStudyDays,
            weekStudyDays: weekStudyDays
        )
    }

    // MARK: - 统计与分析 分区
    private var statsAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("统计与分析")

            NemoCard(cornerRadius: 20, padding: 8) {
                VStack(spacing: 0) {
                    dashboardItemRow(
                        icon: "chart.bar.xaxis",
                        tint: .red,
                        title: "今日统计",
                        subtitle: "今日学习词汇与语法概览",
                        showDivider: true
                    )

                    dashboardItemRow(
                        icon: "clock.arrow.circlepath",
                        tint: .purple,
                        title: "历史统计",
                        subtitle: "查看历史学习趋势与记录",
                        showDivider: true
                    )

                    dashboardItemRow(
                        icon: "waveform.path.ecg",
                        tint: .green,
                        title: "遗忘曲线",
                        subtitle: "查看艾宾浩斯记忆模型分析",
                        showDivider: true
                    )

                    dashboardItemRow(
                        icon: "calendar",
                        tint: .blue,
                        title: "学习日历",
                        subtitle: "按月查看每日学习轨迹",
                        showDivider: false
                    )
                }
            }
        }
    }

    // MARK: - 资料与词库 分区
    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("资料与词库")

            NemoCard(cornerRadius: 20, padding: 8) {
                VStack(spacing: 0) {
                    dashboardItemRow(
                        icon: "textformat.abc",
                        tint: .orange,
                        title: "单词列表",
                        subtitle: "浏览所有已录入单词",
                        showDivider: true
                    )

                    dashboardItemRow(
                        icon: "book.pages.fill",
                        tint: .indigo,
                        title: "语法列表",
                        subtitle: "浏览所有日语语法条目",
                        showDivider: true
                    )

                    dashboardItemRow(
                        icon: "square.grid.2x2.fill",
                        tint: .teal,
                        title: "分类词汇",
                        subtitle: "按场景分类的实用词汇库",
                        showDivider: true
                    )

                    dashboardItemRow(
                        icon: "sparkles",
                        tint: .mint,
                        title: "地道表达",
                        subtitle: "精选地道日语表达库",
                        showDivider: false
                    )
                }
            }
        }
    }

    // MARK: - 强化与突破 分区
    private var reinforceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("强化与突破")

            NemoCard(cornerRadius: 20, padding: 8) {
                VStack(spacing: 0) {
                    dashboardItemRow(
                        icon: "gamecontroller.fill",
                        tint: .cyan,
                        title: "分类练习",
                        subtitle: "针对特定场景的强化专项",
                        showDivider: true
                    )

                    dashboardItemRow(
                        icon: "flame.circle.fill",
                        tint: .red,
                        title: "难点攻坚",
                        subtitle: "针对易错与记忆顽疾项突破",
                        showDivider: false
                    )
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        NemoSectionHeader(title)
            .padding(.horizontal, 4)
    }

    private func dashboardItemRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        showDivider: Bool,
        action: @escaping () -> Void = {}
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    // 图标徽章：29x29 pt，G2 连续平滑圆角 9 pt
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 29, height: 29)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(tint)
                        )

                    // 标题与副标题排版：17 pt 标题搭配 13 pt 脚注说明
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.body)
                            .foregroundStyle(.primary)

                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    // 右侧导航展开箭头
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(minHeight: 63)
            }
            .buttonStyle(.nemoPressable)

            if showDivider {
                // 8(边距) + 29(图标宽) + 12(间距) = 49 pt，精确对齐文字左侧边缘
                Divider()
                    .padding(.leading, 49)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProgressHomeView()
    }
}
