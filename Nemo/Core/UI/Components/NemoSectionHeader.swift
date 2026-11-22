//
//  NemoSectionHeader.swift
//  Nemo
//

import SwiftUI

/// 全局统一卡片分区大标题视图
///
/// 遵循 Apple HIG 规范：Headline 17 pt 粗体，自适应深浅色主色调，禁用小写自动转换。
public struct NemoSectionHeader: View {
    private let title: String
    private let subtitle: String?

    /// 初始化分区大标题视图
    /// - Parameters:
    ///   - title: 分区主标题文本
    ///   - subtitle: 可选的分区副标题说明文本，默认值为 nil
    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .textCase(nil)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        NemoSectionHeader("账户与同步")
        NemoSectionHeader("学习设置", subtitle: "每日目标与记忆算法配置")
    }
    .padding()
}
