import Foundation

/// 语法卡片学习状态与 FSRS 记忆指标模型
public struct GrammarStudyState: SrsItem, Codable, Sendable, Identifiable, Hashable, Equatable {
    public var id: Int { grammarId }
    public let grammarId: Int
    public var repetitionCount: Int
    public var stability: Double
    public var difficulty: Double
    public var interval: Int
    /// 下次复习绝对日期（EpochDay，自 1970-01-01 起的天数，0 表示未排期）
    public var nextReviewDate: Int
    /// 上次复习绝对日期（EpochDay）
    public var lastReviewedDate: Int?
    /// 首次学习绝对日期（EpochDay）
    public var firstLearnedDate: Int?
    /// 当前卡片类型（0: new, 1: learning, 2: review, 3: relearning）
    public var type: Int
    /// 用户是否收藏
    public var isFavorite: Bool
    /// 用户是否跳过
    public var isSkipped: Bool

    public init(
        grammarId: Int,
        repetitionCount: Int = 0,
        stability: Double = 0.0,
        difficulty: Double = 0.0,
        interval: Int = 0,
        nextReviewDate: Int = 0,
        lastReviewedDate: Int? = nil,
        firstLearnedDate: Int? = nil,
        type: Int = 0,
        isFavorite: Bool = false,
        isSkipped: Bool = false
    ) {
        self.grammarId = grammarId
        self.repetitionCount = repetitionCount
        self.stability = stability
        self.difficulty = difficulty
        self.interval = interval
        self.nextReviewDate = nextReviewDate
        self.lastReviewedDate = lastReviewedDate
        self.firstLearnedDate = firstLearnedDate
        self.type = type
        self.isFavorite = isFavorite
        self.isSkipped = isSkipped
    }

    /// 创建全新语法卡片的默认初始状态
    public static func newCard(grammarId: Int) -> GrammarStudyState {
        GrammarStudyState(
            grammarId: grammarId,
            repetitionCount: 0,
            stability: 0.0,
            difficulty: 0.0,
            interval: 0,
            nextReviewDate: 0,
            lastReviewedDate: nil,
            firstLearnedDate: nil,
            type: 0,
            isFavorite: false,
            isSkipped: false
        )
    }

    /// 根据算法推演更新结果原地同步各核心字段
    public mutating func update(with result: SrsUpdateResult) {
        self.repetitionCount = result.repetitionCount
        self.stability = result.stability
        self.difficulty = result.difficulty
        self.interval = result.interval
        self.nextReviewDate = result.nextReviewDate
        self.lastReviewedDate = result.lastReviewedDate
        if self.firstLearnedDate == nil {
            self.firstLearnedDate = result.firstLearnedDate
        }
        self.type = result.type
    }
}
