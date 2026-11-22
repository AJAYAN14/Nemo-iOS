//
//  NemoItemPickerSheet.swift
//  Nemo
//
//  Created by Nemo Team on 2026-11-22.
//

import SwiftUI

/// 抽屉单选面板通用数据项协议
public protocol NemoPickerItem: Identifiable {
    /// 唯一标识
    var id: String { get }
    /// 主标题文本
    var title: String { get }
    /// 副标题描述文本（可选）
    var subtitle: String? { get }
    /// 标签徽章文本（可选）
    var badge: String? { get }
}

/// 通用原生抽屉单选面板
///
/// 遵循 iOS 原生视觉规范，具备以下核心交互特性：
/// 1. 左侧 24x24pt 绝对占位状态槽：未选中项透明占位对齐，当前选中项展示系统主题色加粗 checkmark；
/// 2. 中间信息区：选项主标题（选中项 semibold 加粗）+ 微胶囊徽章 + 辅助描述副文本；
/// 3. 右侧独立操作槽：支持外挂 44x44pt 独立无冲突操作按钮（如行内试听播放按钮）；
/// 4. 纯血苹果原生 Inset Grouped List 布局与标准导航栏系统呈现。
public struct NemoItemPickerSheet<Item: NemoPickerItem, TrailingAction: View>: View {
    private let title: String
    private let items: [Item]
    private let selectedID: String
    private let onSelect: (Item) -> Void
    private let onClose: () -> Void
    private let trailingAction: ((Item) -> TrailingAction)?

    /// 初始化通用单选抽屉
    /// - Parameters:
    ///   - title: 抽屉内联标题
    ///   - items: 候选数据列表
    ///   - selectedID: 当前选中项的唯一标识
    ///   - onSelect: 选中项变化时的回调
    ///   - onClose: 关闭抽屉时的回调
    ///   - trailingAction: 右侧自定义操作视图构建器（可选）
    public init(
        title: String,
        items: [Item],
        selectedID: String,
        onSelect: @escaping (Item) -> Void,
        onClose: @escaping () -> Void,
        @ViewBuilder trailingAction: @escaping (Item) -> TrailingAction
    ) {
        self.title = title
        self.items = items
        self.selectedID = selectedID
        self.onSelect = onSelect
        self.onClose = onClose
        self.trailingAction = trailingAction
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(items, id: \.id) { item in
                        row(for: item)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .nemoConfigurationFormSpacing()
            .navigationTitle(title)
            .nemoInlinePageTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    NemoSheetCloseButton(dismiss: onClose)
                }
            }
        }
        .nemoModalPresentation(.page)
        .nemoSheetSurface()
    }

    // MARK: - 列表单行排版

    @ViewBuilder
    private func row(for item: Item) -> some View {
        let isCurrent = item.id == selectedID

        HStack(alignment: .center, spacing: 0) {
            // 1. 左侧选择区域：点击触发选中
            Button {
                onSelect(item)
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    // 状态槽 (24x24pt 绝对占位保持所有文本行垂直对齐)
                    statusSlot(isCurrent: isCurrent)

                    // 中间名称与副标题
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(item.title)
                                .font(.body.weight(isCurrent ? .semibold : .regular))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if let badge = item.badge, !badge.isEmpty {
                                Text(badge)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color(uiColor: .tertiarySystemFill))
                                    )
                            }
                        }

                        if let subtitle = item.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 2. 右侧操作区：独立操作按钮（如试听按钮）
            if let trailingAction {
                trailingAction(item)
            }
        }
    }

    // MARK: - 状态槽

    @ViewBuilder
    private func statusSlot(isCurrent: Bool) -> some View {
        Group {
            if isCurrent {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            } else {
                Color.clear
            }
        }
        .frame(width: 24, height: 24)
    }
}

public extension NemoItemPickerSheet where TrailingAction == EmptyView {
    /// 初始化无右侧操作槽的纯净单选抽屉
    init(
        title: String,
        items: [Item],
        selectedID: String,
        onSelect: @escaping (Item) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.init(
            title: title,
            items: items,
            selectedID: selectedID,
            onSelect: onSelect,
            onClose: onClose,
            trailingAction: { _ in EmptyView() }
        )
    }
}
