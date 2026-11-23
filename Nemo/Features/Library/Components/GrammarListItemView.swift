import SwiftUI

/// 语法列表单元格卡片视图（100% 对齐 Android Nemo GrammarListItemPremium 设计规范）。
public struct GrammarListItemView: View {
    public let grammar: Grammar

    public init(grammar: Grammar) {
        self.grammar = grammar
    }

    /// 对齐 Android AvatarPalette 8 色调色板
    private let avatarPalette: [Color] = [
        .indigo,
        .purple,
        .blue,
        .teal,
        .cyan,
        .mint,
        .orange,
        .pink
    ]

    private var avatarColor: Color {
        let index = abs(grammar.id.hashValue) % avatarPalette.count
        return avatarPalette[index]
    }

    private var subtitleText: String {
        if !grammar.explanationText.isEmpty {
            return grammar.explanationText
        } else {
            return grammar.connectionText
        }
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 左侧：50x50 pt 艺术字头像框（“文”字徽章，G2 连续平滑圆角 16pt，柔和半透底色）
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Text("文")
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(avatarColor)
            }

            // 中间：语法标题与接续/释义双行排版
            VStack(alignment: .leading, spacing: 4) {
                Text(grammar.title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitleText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // 右侧：JLPT 等级微徽章（粗黑斜体 + 连续圆角 8pt）
            if !grammar.level.isEmpty {
                Text(grammar.level.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .italic()
                    .foregroundStyle(grammar.jlptLevel.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        grammar.jlptLevel.accentColor.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}
