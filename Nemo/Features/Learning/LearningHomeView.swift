//
//  LearningHomeView.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 学习主页（100% 对齐 Android HomeScreen.kt 业务与结构）
public struct LearningHomeView: View {
    public enum LearningMode: String, CaseIterable, Identifiable {
        case word = "单词"
        case grammar = "语法"
        public var id: String { rawValue }
    }

    // 状态对齐 Android uiState
    @State private var learningMode: LearningMode = .word
    @State private var dailyStreak: Int = 12
    @State private var currentProgress: Int = 15      // 今日新学完成数
    @State private var dailyGoal: Int = 20            // 新学目标
    @State private var reviewedToday: Int = 18        // 今日已复习数
    @State private var itemsDue: Int = 14             // 待复习未完成数
    @State private var dailyCompletionRate: Int = 75  // 达成率 %
    @State private var username: String = "Nemo"
    @State private var rightColumnHeight: CGFloat = 224

    // 动态状态（遵循 Android 真实业务状态）
    private var isLearned: Bool { currentProgress > 0 }

    public init() {}

    private var totalReviewItems: Int {
        reviewedToday + itemsDue
    }

    private var progressFraction: Double {
        guard dailyGoal > 0 else { return 0.0 }
        return min(Double(currentProgress) / Double(dailyGoal), 1.0)
    }

    // 动态生成副标题问候短语（对齐 Android 时段问候）
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

    private var primaryModeColor: Color {
        learningMode == .word ? Color.orange : Color.green
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 顶部问候栏与头像
                greetingHeaderSection

                // 2. Bento Grid 核心布局区
                bentoGridSection

                // 3. 学习资源区块
                learningResourcesSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.nemoGroupedBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 1. 顶部用户欢迎栏 (对齐 Android Header)
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
                    .fill(primaryModeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(primaryModeColor)
            }
            .overlay(
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 2)
    }

    // MARK: - 2. Bento Grid 核心便当盒网格 (对齐 Android Bento 1~5)
    private var bentoGridSection: some View {
        VStack(spacing: 12) {
            // Bento 1: 顶部控制卡片 (连续打卡徽章 + 单词/语法模式切换)
            NemoCard(cornerRadius: 20, padding: 12) {
                HStack {
                    // 打卡天数徽章
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                        Text("\(dailyStreak) 天")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    // 单词 / 语法分段选择器
                    Picker("模式", selection: $learningMode) {
                        ForEach(LearningMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }

            // 中部核心指标网格: 左侧环形大卡片 + 右侧双统计卡片 (像素级严格等高)
            HStack(spacing: 12) {
                // Bento 2: 今日新学进度大卡片 (左侧，高度严格对齐右侧双卡片之和)
                NemoCard(cornerRadius: 20, padding: 16) {
                    VStack(spacing: 0) {
                        Text("今日新学进度")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 8)

                        // 环形进度指示器 (垂直绝对居中)
                        ZStack {
                            Circle()
                                .stroke(primaryModeColor.opacity(0.15), lineWidth: 8)
                                .frame(width: 92, height: 92)

                            Circle()
                                .trim(from: 0, to: progressFraction)
                                .stroke(primaryModeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 92, height: 92)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: progressFraction)

                            Text("\(currentProgress)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        .frame(height: 98)

                        Spacer(minLength: 8)

                        Text("新学目标 \(dailyGoal)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: rightColumnHeight)

                // 右侧上下排列的两张统计卡片
                VStack(spacing: 12) {
                    // Bento 3: 复习进度卡片
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
                                Text("\(reviewedToday)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text("/\(totalReviewItems)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Text("复习进度")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Bento 4: 学习达成率卡片
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
                                Text("\(dailyCompletionRate)")
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
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: RightColumnHeightPreferenceKey.self,
                            value: geo.size.height
                        )
                    }
                )
            }
            .onPreferenceChange(RightColumnHeightPreferenceKey.self) { height in
                if height > 0 && abs(rightColumnHeight - height) > 1 {
                    rightColumnHeight = height
                }
            }

            // Bento 5: 底部主行动按钮 (100% 复用 Clash-Client 官方同款：.clashPrimaryActionButtonStyle + 胶囊 + 大尺寸 50pt + 单词橙/语法绿)
            Button {
                // 点击开始学习交互占位
            } label: {
                HStack(spacing: 6) {
                    Text(isLearned ? "继续学习" : "立即开始")
                        .font(.headline.weight(.bold))
                        .lineLimit(1)

                    Image(systemName: isLearned ? "arrow.right" : "play.fill")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity, minHeight: 38)
            }
            .nemoPrimaryActionButtonStyle()
            .nemoCapsuleButtonBorderShape()
            .controlSize(.large)
            .tint(primaryModeColor)
        }
    }

    // MARK: - 3. 学习资源区块 (对齐 Android title_learning_resources)
    private var learningResourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            NemoSectionHeader("学习资源")
                .padding(.horizontal, 4)

            // 全宽卡片：热力图 (记录每日学习足迹)
            Button {
                // 跳转热力图占位
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

// 用于同步 Bento Grid 两列高度的 PreferenceKey
private struct RightColumnHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
