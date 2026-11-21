//
//  NemoCard.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// 跨平台语义颜色兼容扩展，确保无论在 iOS 设备还是 Mac 目标下均零报错编译
public extension Color {
    static var nemoGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }

    static var nemoSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.white
        #endif
    }

    static var nemoTertiaryGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .underPageBackgroundColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
}

/// Nemo 标准卡片容器
/// 遵循 Apple HIG 规范，采用 G2 连续平滑曲率与系统二级分组背景语义色
public struct NemoCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: EdgeInsets
    private let content: Content

    public init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        self.content = content()
    }

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
