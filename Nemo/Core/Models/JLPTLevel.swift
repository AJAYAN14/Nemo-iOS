import SwiftUI

/// 日本语能力测试（JLPT）分级枚举。
public enum JLPTLevel: String, CaseIterable, Codable, Sendable, Identifiable, Comparable {
    case all = "ALL"
    case n1 = "N1"
    case n2 = "N2"
    case n3 = "N3"
    case n4 = "N4"
    case n5 = "N5"

    public var id: String { rawValue }

    /// 学习难度进阶升序权重（N5 为初级优先排期，ALL 为未分级）
    public var sortOrder: Int {
        switch self {
        case .n5:
            return 1
        case .n4:
            return 2
        case .n3:
            return 3
        case .n2:
            return 4
        case .n1:
            return 5
        case .all:
            return 99
        }
    }

    public static func < (lhs: JLPTLevel, rhs: JLPTLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    /// 标准等级升序进阶序列
    public static let ascendingStudyLevels: [JLPTLevel] = [.n5, .n4, .n3, .n2, .n1]

    /// 用户界面展示文本
    public var title: String {
        switch self {
        case .all:
            return "全部"
        case .n1:
            return "N1"
        case .n2:
            return "N2"
        case .n3:
            return "N3"
        case .n4:
            return "N4"
        case .n5:
            return "N5"
        }
    }

    /// 各等级标准语义主题色彩（遵循 Apple HIG 调色盘）
    public var accentColor: Color {
        switch self {
        case .all:
            return .secondary
        case .n1:
            return .purple
        case .n2:
            return .indigo
        case .n3:
            return .blue
        case .n4:
            return .teal
        case .n5:
            return .green
        }
    }
}
