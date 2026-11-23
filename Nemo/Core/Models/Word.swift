import Foundation

/// 日语单词实体数据模型。
public struct Word: Identifiable, Codable, Sendable, Hashable {
    public let id: Int
    public let rawId: String?
    public let japanese: String
    public let hiragana: String
    public let chinese: String
    public let level: String
    public let pos: String?
    public let example1: String?
    public let gloss1: String?
    public let example2: String?
    public let gloss2: String?
    public let example3: String?
    public let gloss3: String?
    public let isDelisted: Bool
    public let updatedAt: String?

    public init(
        id: Int,
        rawId: String? = nil,
        japanese: String,
        hiragana: String,
        chinese: String,
        level: String,
        pos: String? = nil,
        example1: String? = nil,
        gloss1: String? = nil,
        example2: String? = nil,
        gloss2: String? = nil,
        example3: String? = nil,
        gloss3: String? = nil,
        isDelisted: Bool = false,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.rawId = rawId
        self.japanese = japanese
        self.hiragana = hiragana
        self.chinese = chinese
        self.level = level
        self.pos = pos
        self.example1 = example1
        self.gloss1 = gloss1
        self.example2 = example2
        self.gloss2 = gloss2
        self.example3 = example3
        self.gloss3 = gloss3
        self.isDelisted = isDelisted
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case rawId = "raw_id"
        case japanese
        case hiragana
        case chinese
        case level
        case pos
        case example1 = "example_1"
        case gloss1 = "gloss_1"
        case example2 = "example_2"
        case gloss2 = "gloss_2"
        case example3 = "example_3"
        case gloss3 = "gloss_3"
        case isDelisted = "is_delisted"
        case updatedAt = "updated_at"
    }

    /// 映射对应的 JLPT 等级枚举
    public var jlptLevel: JLPTLevel {
        JLPTLevel(rawValue: level.uppercased()) ?? .all
    }

    /// 本地多维模糊搜索匹配
    public func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return japanese.localizedCaseInsensitiveContains(trimmed) ||
            hiragana.localizedCaseInsensitiveContains(trimmed) ||
            chinese.localizedCaseInsensitiveContains(trimmed)
    }
}
