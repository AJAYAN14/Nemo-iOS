//
//  LearningHomeView.swift
//  Nemo
//

import SwiftUI

/// 学习中心主视图
///
/// 承载每日学习打卡状态、核心指标便当盒看板（Bento Grid）以及多维日语学习资源入口。
public struct LearningHomeView: View {
    @State private var store = LearningHomeStore()

    // 监听持久化设置项
    @AppStorage("settings_daily_word_goal") private var storedWordGoal: Int = 20
    @AppStorage("settings_daily_grammar_goal") private var storedGrammarGoal: Int = 10
    @AppStorage("settings_learning_day_reset_hour") private var storedResetHour: Int = 4

    @State private var username: String = "Nemo"
    @State private var navigateToSession: Bool = false

    public init() {}

    /// 根据当前时段动态生成的副标题问候语
    private var subGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...10:
            return "清晨的微风，伴你开启今日学习"
        case 11...17:
            return "午后阳光正好，静心积累每一个新词"
        case 18...23:
            return "夜幕低垂，今日的复习准备好了吗"
        default:
            return "夜深了，学完这一组早点休息哦"
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 顶部问候栏与头像
                greetingHeaderSection

                // 2. 便当盒核心指标布局区
                bentoGridSection

                // 3. 学习资源区块
                learningResourcesSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.nemoGroupedBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            store.syncSettings(
                wordGoal: storedWordGoal,
                grammarGoal: storedGrammarGoal,
                resetHour: storedResetHour
            )
            await store.refreshStats()
        }
        .onChange(of: storedWordGoal) { _, newValue in
            store.dailyWordGoal = newValue
        }
        .onChange(of: storedGrammarGoal) { _, newValue in
            store.dailyGrammarGoal = newValue
        }
        .onChange(of: storedResetHour) { _, newValue in
            store.resetHour = newValue
            Task { await store.refreshStats() }
        }
        .onAppear {
            Task {
                await store.refreshStats()
            }
        }
        .navigationDestination(isPresented: $navigateToSession) {
            LearningSessionView(
                mode: store.learningMode,
                dailyGoal: store.currentGoal
            )
        }
    }

    // MARK: - 顶部问候栏
    private var greetingHeaderSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(username) さん")
                    .font(.system(.title2, design: .serif, weight: .heavy))
                    .foregroundStyle(.primary)

                Text(subGreeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 用户头像
            ZStack {
                Circle()
                    .fill(store.primaryModeColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(store.primaryModeColor)
            }
            .overlay(
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 2)
    }

    // MARK: - 核心便当盒网格看板
    private var bentoGridSection: some View {
        VStack(spacing: 12) {
            // 控制卡片：连续打卡徽章与模式分段切换
            NemoCard(cornerRadius: 20, padding: 12) {
                HStack {
                    // 打卡天数徽章
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                        Text("\(store.dailyStreak) 天")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    // 单词 / 语法分段选择器
                    Picker("模式", selection: $store.learningMode) {
                        ForEach(LearningHomeStore.LearningMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }

            // 中部核心指标网格：左侧环形进度仪表与右侧统计双卡片
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    // 今日新学进度卡片
                    NemoCard(cornerRadius: 20, padding: 16) {
                        VStack(spacing: 0) {
                            Text("今日新学进度")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Spacer(minLength: 8)

                            // 环形进度指示器（采用 Apple 原生 Gauge 控件）
                            Gauge(value: store.progressFraction, in: 0...1) {
                                Text("今日新学进度")
                            } currentValueLabel: {
                                Text("\(store.currentProgress)")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                            .gaugeStyle(.accessoryCircularCapacity)
                            .tint(store.primaryModeColor)
                            .scaleEffect(1.6)
                            .frame(width: 92, height: 92)

                            Spacer(minLength: 8)

                            Text("新学目标 \(store.currentGoal)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxHeight: .infinity)

                    // 右侧上下排列的两张统计卡片
                    VStack(spacing: 12) {
                        // 复习进度卡片
                        NemoCard(cornerRadius: 20, padding: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.orange.opacity(0.12))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption.bold())
                                        .foregroundStyle(.orange)
                                }

                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text("\(store.reviewedToday)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text("/\(store.totalReviewItems)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }

                                Text("复习进度")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // 学习达成率卡片
                        NemoCard(cornerRadius: 20, padding: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.green.opacity(0.12))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }

                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text("\(store.dailyCompletionRate)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text("%")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }

                                Text("学习达成率")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // 底部主行动胶囊按钮
            Button {
                navigateToSession = true
            } label: {
                HStack(spacing: 6) {
                    Text(store.isLearned ? "继续学习" : "立即开始")
                        .font(.headline.weight(.bold))
                        .lineLimit(1)

                    Image(systemName: store.isLearned ? "arrow.right" : "play.fill")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity, minHeight: 38)
            }
            .nemoPrimaryActionButtonStyle()
            .nemoCapsuleButtonBorderShape()
            .controlSize(.large)
            .tint(store.primaryModeColor)
        }
    }

    // MARK: - 学习资源推荐区
    private var learningResourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            NemoSectionHeader("学习资源")
                .padding(.horizontal, 4)

            // 全宽卡片：学习足迹热力图
            Button {
                // 热力图详情页入口
            } label: {
                NemoCard(cornerRadius: 20, padding: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.purple.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("热力图")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text("记录每日学习足迹")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.nemoPressable)

            // 均分小卡片第 1 组：五十音图 + 动词活用
            HStack(spacing: 12) {
                resourceMiniCard(
                    title: "五十音图",
                    subtitle: "平假名与片假名",
                    icon: "character.book.closed.fill",
                    tint: .blue
                )

                resourceMiniCard(
                    title: "动词活用",
                    subtitle: "13种变形速查",
                    icon: "arrow.triangle.2.circlepath",
                    tint: .indigo
                )
            }

            // 均分小卡片第 2 组：AI 工坊 + AI 阅读
            HStack(spacing: 12) {
                resourceMiniCard(
                    title: "AI 工坊",
                    subtitle: "造句与翻译实时批改",
                    icon: "sparkles",
                    tint: .purple
                )

                resourceMiniCard(
                    title: "AI 阅读",
                    subtitle: "分级智能短文",
                    icon: "book.pages.fill",
                    tint: .teal
                )
            }
        }
    }

    private func resourceMiniCard(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            NemoCard(cornerRadius: 20, padding: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(tint.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: icon)
                                .font(.subheadline.bold())
                                .foregroundStyle(tint)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.bold())
                            .foregroundStyle(.tertiary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(.nemoPressable)
    }
}

#Preview {
    NavigationStack {
        LearningHomeView()
    }
}
