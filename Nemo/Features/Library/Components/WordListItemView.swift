import SwiftUI

/// 单词列表单元格卡片视图（100% 对齐 Android Nemo WordListItemPremium 设计规范）。
public struct WordListItemView: View {
    public let word: Word

    public init(word: Word) {
        self.word = word
    }

    /// 对齐 Android AvatarPalette 8 色调色板
    private let avatarPalette: [Color] = [
        .blue,
        .orange,
        .green,
        .indigo,
        .teal,
        .purple,
        .pink,
        .cyan
    ]

    private var avatarColor: Color {
        let index = abs(word.id.hashValue) % avatarPalette.count
        return avatarPalette[index]
    }

    private var firstCharText: String {
        String(word.japanese.first ?? "?")
    }

    private var subtitleText: String {
        if !word.hiragana.isEmpty && !word.chinese.isEmpty && word.japanese != word.hiragana {
            return "\(word.hiragana) · \(word.chinese)"
        } else if !word.chinese.isEmpty {
            return word.chinese
        } else {
            return word.hiragana
        }
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 左侧：50x50 pt 艺术字头像框（G2 连续平滑圆角 16pt，柔和半透底色）
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Text(firstCharText)
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(avatarColor)
            }

            // 中间：主单词与假名/释义双行排版
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(word.japanese)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let pos = word.pos, !pos.isEmpty {
                        Text(pos)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(avatarColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                avatarColor.opacity(0.12),
                                in: Capsule()
                            )
                    }
                }

                Text(subtitleText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // 右侧：JLPT 等级微徽章（粗黑斜体 + 连续圆角 8pt）
            if !word.level.isEmpty {
                Text(word.level.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .italic()
                    .foregroundStyle(word.jlptLevel.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        word.jlptLevel.accentColor.opacity(0.14),
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
