import Foundation

/// 卡片学习阶段类型枚举
public enum SrsItemType: Int, Sendable, Equatable, CaseIterable {
    /// 新卡未学习
    case new = 0
    /// 学习中/初学失败
    case learning = 1
    /// 正常复习阶段
    case review = 2
    /// 遗忘后重新学习
    case relearning = 3
}

/// 间隔重复算法实体抽象契约
public protocol SrsItem: Sendable {
    var repetitionCount: Int { get }
    var stability: Double { get }
    var difficulty: Double { get }
    var interval: Int { get }
    /// 下次复习绝对日期（EpochDay，自 1970-01-01 起的天数，0 表示尚未排期）
    var nextReviewDate: Int { get }
    /// 上次复习绝对日期（EpochDay）
    var lastReviewedDate: Int? { get }
    /// 首次学习绝对日期（EpochDay）
    var firstLearnedDate: Int? { get }
    /// 当前卡片类型（对应 SrsItemType）
    var type: Int { get }
}

/// 算法状态推演更新结果
public struct SrsUpdateResult: Sendable, Equatable {
    public let repetitionCount: Int
    public let stability: Double
    public let difficulty: Double
    public let interval: Int
    public let nextReviewDate: Int
    public let lastReviewedDate: Int?
    public let firstLearnedDate: Int?
    public let type: Int

    public init(
        repetitionCount: Int,
        stability: Double,
        difficulty: Double,
        interval: Int,
        nextReviewDate: Int,
        lastReviewedDate: Int?,
        firstLearnedDate: Int?,
        type: Int
    ) {
        self.repetitionCount = repetitionCount
        self.stability = stability
        self.difficulty = difficulty
        self.interval = interval
        self.nextReviewDate = nextReviewDate
        self.lastReviewedDate = lastReviewedDate
        self.firstLearnedDate = firstLearnedDate
        self.type = type
    }
}
