import SwiftUI

/// SRS 4 档评价分级枚举
public enum SRSRatingQuality: Int, CaseIterable, Identifiable, Sendable {
    /// 重来：未记住，需要重学入队
    case again = 1
    /// 困难：回忆艰难，较短间隔复习
    case hard = 3
    /// 良好：正常回忆，标准间隔复习
    case good = 4
    /// 简单：瞬间秒答，长期记忆沉淀
    case easy = 5

    public var id: Int { rawValue }

    /// 档位中文标签
    public var label: String {
        switch self {
        case .again: return "重来"
        case .hard: return "困难"
        case .good: return "良好"
        case .easy: return "简单"
        }
    }

    /// 档位主题语义色彩
    public var themeColor: Color {
        switch self {
        case .again: return .red
        case .hard: return .orange
        case .good: return .blue
        case .easy: return .green
        }
    }

    /// 按钮浅色底面背景色
    public var containerBackgroundColor: Color {
        switch self {
        case .again: return Color.red.opacity(0.12)
        case .hard: return Color.orange.opacity(0.12)
        case .good: return Color.blue.opacity(0.12)
        case .easy: return Color.green.opacity(0.12)
        }
    }
}

/// 学习队列分类
public enum LearningQueueType: String, CaseIterable, Sendable {
    /// 新词学习队列
    case new
    /// 正在掌握中队列
    case learning
    /// 到期复习队列
    case review
    /// 遗忘重学队列
    case relearn

    /// 中文分类名称
    public var title: String {
        switch self {
        case .new: return "新学"
        case .learning: return "在学"
        case .review: return "复习"
        case .relearn: return "重学"
        }
    }

    /// 队列标识语义色彩
    public var themeColor: Color {
        switch self {
        case .new: return .blue
        case .learning: return .cyan
        case .review: return .green
        case .relearn: return .orange
        }
    }
}

/// 学习队列实时状态计数
public struct QueueCountState: Equatable, Sendable {
    public var newCount: Int
    public var learningCount: Int
    public var reviewCount: Int
    public var relearnCount: Int

    public init(
        newCount: Int = 0,
        learningCount: Int = 0,
        reviewCount: Int = 0,
        relearnCount: Int = 0
    ) {
        self.newCount = newCount
        self.learningCount = learningCount
        self.reviewCount = reviewCount
        self.relearnCount = relearnCount
    }

    /// 当前队列中所有待处理卡片总数
    public var totalRemaining: Int {
        newCount + learningCount + reviewCount + relearnCount
    }
}

/// 学习会话状态机阶段枚举
public enum LearningSessionStatus: Equatable, Sendable {
    /// 数据与会话队列加载中
    case loading
    /// 正在学习单词（参数为卡片正反面翻转状态）
    case learning(isFlipped: Bool)
    /// 评分提交中，等待卡片切换过渡
    case processing
    /// 本组学习已出清并展示结算战报
    case completed(stats: LearningSessionStats)
}

/// 学习会话结算战报数据模型
public struct LearningSessionStats: Equatable, Sendable {
    /// 本次会话完成的总词数
    public let totalLearnedCount: Int
    /// 其中新词掌握数量
    public let newCount: Int
    /// 其中顺畅巩固复习数量
    public let reviewCount: Int
    /// 其中反复攻克重学数量
    public let relearnCount: Int
    /// 最高连击答对次数
    public let maxCombo: Int
    /// 专注学习总时长（单位：秒）
    public let durationSeconds: TimeInterval
    /// 连续打卡天数
    public let dailyStreak: Int

    public init(
        totalLearnedCount: Int,
        newCount: Int,
        reviewCount: Int,
        relearnCount: Int,
        maxCombo: Int,
        durationSeconds: TimeInterval,
        dailyStreak: Int
    ) {
        self.totalLearnedCount = totalLearnedCount
        self.newCount = newCount
        self.reviewCount = reviewCount
        self.relearnCount = relearnCount
        self.maxCombo = maxCombo
        self.durationSeconds = durationSeconds
        self.dailyStreak = dailyStreak
    }

    /// 格式化专注用时文本（分:秒）
    public var formattedDuration: String {
        let total = Int(durationSeconds)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return "\(minutes) 分 \(seconds) 秒"
        }
        return "\(seconds) 秒"
    }

    /// 平均每词专注秒数
    public var averageSecondsPerWord: Double {
        guard totalLearnedCount > 0 else { return 0.0 }
        return durationSeconds / Double(totalLearnedCount)
    }
}
