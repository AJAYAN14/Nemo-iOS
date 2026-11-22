//
//  NemoCard.swift
//  Nemo
//

import SwiftUI

/// 全局统一卡片容器视图
///
/// 遵循 Apple 现代人机界面指南（HIG），采用连续平滑曲率（G2 Continuous Corner Radius）与系统二级分组语义背景色。
public struct NemoCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: EdgeInsets
    private let content: Content

    /// 使用统一内边距初始化卡片容器
    /// - Parameters:
    ///   - cornerRadius: 卡片外周的连续平滑曲率圆角半径，默认值为 16 pt
    ///   - padding: 卡片内部所有方向的统一内边距，默认值为 16 pt
    ///   - content: 卡片内部承载的子视图构建器闭包
    public init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        self.content = content()
    }

    /// 使用自定义外间距与内边距初始化卡片容器
    /// - Parameters:
    ///   - cornerRadius: 卡片外周的连续平滑曲率圆角半径，默认值为 16 pt
    ///   - insets: 包含各边缘细节定制的自定义内边距
    ///   - content: 卡片内部承载的子视图构建器闭包
    public init(
        cornerRadius: CGFloat = 16,
        insets: EdgeInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = insets
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.nemoSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color.nemoGroupedBackground
            .ignoresSafeArea()

        NemoCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("卡片标题")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("这是 NemoCard 标准容器卡片内容预览。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
