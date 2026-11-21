//
//  TestHomeView.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 测试大厅（100% 对齐 Android TestDashboardScreen.kt 结构与文案）
public struct TestHomeView: View {
    // 状态对齐 Android uiState
    @State private var todayTestCount: Int = 20
    @State private var consecutiveTestDays: Int = 8
    @State private var todayAccuracy: Double = 0.90
    @State private var totalTestCount: Int = 180
    @State private var maxTestStreak: Int = 15
    @State private var overallAccuracy: Double = 0.88
    @State private var wrongWordsCount: Int = 12
    @State private var favoriteWordsCount: Int = 28

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 顶部战报统计卡片 (对齐 Android CompactStatsPage)
                testStatsSection

                // 2. 复习与巩固 分区 (错题集 + 收藏夹)
                reviewAndConsolidateSection

                // 3. 基础练习模式 分区 (单选、拼写、连线、排序)
                basicPracticeSection

                // 4. 其他能力强化 (能力工坊)
                workshopSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.nemoGroupedBackground)
        .navigationTitle("测试")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 1. 顶部战报统计卡片
    private var testStatsSection: some View {
        NemoCard(cornerRadius: 24, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.blue)
                            .font(.headline)
                        Text("今日战报")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Text("正确率 \(Int(todayAccuracy * 100))%")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(todayTestCount)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("今日已测题目")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .frame(height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(consecutiveTestDays)")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.orange)
                            Text("天")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text("连续自测天数")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .frame(height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(totalTestCount)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.indigo)
                        Text("累计测试总数")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - 2. 复习与巩固 (对齐 Android test_dashboard_section_review)
    private var reviewAndConsolidateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("复习与巩固")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                // 错题集
                Button {
                    // 跳转错题集占位
                } label: {
                    NemoCard(cornerRadius: 20, padding: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.red.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("错题集")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text("\(wrongWordsCount) 项待复习")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
                .buttonStyle(.nemoPressable)

                // 收藏夹
                Button {
                    // 跳转收藏夹占位
                } label: {
                    NemoCard(cornerRadius: 20, padding: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "star.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("收藏夹")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text("\(favoriteWordsCount) 项已收藏")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
                .buttonStyle(.nemoPressable)
            }
        }
    }

    // MARK: - 3. 基础练习模式 (对齐 Android test_dashboard_section_basic: 单选、拼写、连线、排序)
    private var basicPracticeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("基础练习模式")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    testModeGridItem(
                        title: "单选测试",
                        subtitle: "四选一快速辨析",
                        icon: "list.bullet.clipboard.fill",
                        color: .green
                    )

                    testModeGridItem(
                        title: "拼写测试",
                        subtitle: "键盘输入假名拼写",
                        icon: "character.textbox",
                        color: .indigo
                    )
                }

                HStack(spacing: 12) {
                    testModeGridItem(
                        title: "卡片连线",
                        subtitle: "假名与释义配对消除",
                        icon: "square.grid.2x2.fill",
                        color: .teal
                    )

                    testModeGridItem(
                        title: "语法排序",
                        subtitle: "语境词块拖拽还原",
                        icon: "arrow.up.and.down.and.arrow.left.and.right",
                        color: .purple
                    )
                }
            }
        }
    }

    private func testModeGridItem(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            NemoCard(cornerRadius: 20, padding: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(color.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: icon)
                                .font(.subheadline.bold())
                                .foregroundStyle(color)
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

    // MARK: - 4. 其他能力强化 (能力工坊)
    private var workshopSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("其他能力强化")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            Button {
                // 进入能力工坊占位
            } label: {
                NemoCard(cornerRadius: 20, padding: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "infinity")
                                .font(.title3.bold())
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("能力工坊")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text("听力辨析、动词变形与完形填空综合专项实战")
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
        }
    }
}

#Preview {
    NavigationStack {
        TestHomeView()
    }
}
