//
//  NemoSectionHeader.swift
//  Nemo
//
//  Created by AJIAN on 2026/11/22.
//

import SwiftUI

/// Nemo 全局统一卡片分区大标题组件
/// 严格遵循 Apple HIG 规范：Headline 17pt 粗体，自适应深浅色 Primary 主色调
public struct NemoSectionHeader: View {
    private let title: String
    private let subtitle: String?

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
