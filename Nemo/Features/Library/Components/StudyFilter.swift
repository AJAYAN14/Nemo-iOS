import SwiftUI

/// 词库学习状态过滤枚举（对齐 Android Nemo StudyFilter）。
public enum StudyFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case learned = "LEARNED"
    case unlearned = "UNLEARNED"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all:
            return "全部"
        case .learned:
            return "已掌握"
        case .unlearned:
            return "待学习"
        }
    }

    public var iconName: String {
        switch self {
        case .all:
            return "book.pages"
        case .learned:
            return "checkmark.circle.fill"
        case .unlearned:
            return "hourglass"
        }
    }

    public var activeColor: Color {
        switch self {
        case .all:
            return .indigo
        case .learned:
            return .green
        case .unlearned:
            return .orange
        }
    }
}
