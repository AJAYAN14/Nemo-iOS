import Foundation

/// 每日学习打卡统计模型（基于逻辑 EpochDay 记录当日新学与复习量）
public struct StudyDailyRecord: Codable, Sendable, Identifiable, Hashable, Equatable {
    public var id: Int { date }
    /// 逻辑纪元天数（EpochDay，自 1970-01-01 起的天数）
    public let date: Int
    /// 当日新学单词数
    public var learnedWords: Int
    /// 当日复习单词数
    public var reviewedWords: Int
    /// 当日新学语法数
    public var learnedGrammars: Int
    /// 当日复习语法数
    public var reviewedGrammars: Int
    /// 记录最后更新时间
    public var updatedAt: Date

    // MARK: - 兼容属性与聚合计算
    public var learnedCount: Int {
        get { learnedWords }
        set { learnedWords = newValue }
    }

    public var reviewedCount: Int {
        get { reviewedWords }
        set { reviewedWords = newValue }
    }

    /// 当日总单词活动数
    public var totalWords: Int {
        learnedWords + reviewedWords
    }

    /// 当日总语法活动数
    public var totalGrammars: Int {
        learnedGrammars + reviewedGrammars
    }

    /// 当日总活动数（单词 + 语法）
    public var totalCount: Int {
        totalWords + totalGrammars
    }

    // MARK: - 构造器
    public init(
        date: Int,
        learnedWords: Int = 0,
        reviewedWords: Int = 0,
        learnedGrammars: Int = 0,
        reviewedGrammars: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.date = date
        self.learnedWords = learnedWords
        self.reviewedWords = reviewedWords
        self.learnedGrammars = learnedGrammars
        self.reviewedGrammars = reviewedGrammars
        self.updatedAt = updatedAt
    }

    public init(
        date: Int,
        learnedCount: Int,
        reviewedCount: Int,
        updatedAt: Date = Date()
    ) {
        self.date = date
        self.learnedWords = learnedCount
        self.reviewedWords = reviewedCount
        self.learnedGrammars = 0
        self.reviewedGrammars = 0
        self.updatedAt = updatedAt
    }

    // MARK: - Codable 编码与无损向后兼容解码
    private enum CodingKeys: String, CodingKey {
        case date
        case learnedWords
        case reviewedWords
        case learnedGrammars
        case reviewedGrammars
        case learnedCount
        case reviewedCount
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try container.decode(Int.self, forKey: .date)

        if let lw = try container.decodeIfPresent(Int.self, forKey: .learnedWords) {
            self.learnedWords = lw
        } else if let lc = try container.decodeIfPresent(Int.self, forKey: .learnedCount) {
            self.learnedWords = lc
        } else {
            self.learnedWords = 0
        }

        if let rw = try container.decodeIfPresent(Int.self, forKey: .reviewedWords) {
            self.reviewedWords = rw
        } else if let rc = try container.decodeIfPresent(Int.self, forKey: .reviewedCount) {
            self.reviewedWords = rc
        } else {
            self.reviewedWords = 0
        }

        self.learnedGrammars = try container.decodeIfPresent(Int.self, forKey: .learnedGrammars) ?? 0
        self.reviewedGrammars = try container.decodeIfPresent(Int.self, forKey: .reviewedGrammars) ?? 0
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(learnedWords, forKey: .learnedWords)
        try container.encode(reviewedWords, forKey: .reviewedWords)
        try container.encode(learnedGrammars, forKey: .learnedGrammars)
        try container.encode(reviewedGrammars, forKey: .reviewedGrammars)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
