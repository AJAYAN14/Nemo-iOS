import Foundation

/// 语法具体用法结构模型。
public struct GrammarUsage: Codable, Sendable, Hashable {
    public let subtype: String?
    public let connection: String?
    public let explanation: String?
    public let notes: String?

    public init(
        subtype: String? = nil,
        connection: String? = nil,
        explanation: String? = nil,
        notes: String? = nil
    ) {
        self.subtype = subtype
        self.connection = connection
        self.explanation = explanation
        self.notes = notes
    }
}

/// 语法内容包装结构模型。
public struct GrammarContent: Codable, Sendable, Hashable {
    public let usages: [GrammarUsage]?

    public init(usages: [GrammarUsage]? = nil) {
        self.usages = usages
    }
}

/// 日语语法实体数据模型。
public struct Grammar: Identifiable, Codable, Sendable, Hashable {
    public let id: Int
    public let rawId: String?
    public let level: String
    public let title: String
    public let content: GrammarContent?
    public let isDelisted: Bool
    public let updatedAt: String?

    public init(
        id: Int,
        rawId: String? = nil,
        level: String,
        title: String,
        content: GrammarContent? = nil,
        isDelisted: Bool = false,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.rawId = rawId
        self.level = level
        self.title = title
        self.content = content
        self.isDelisted = isDelisted
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case rawId = "raw_id"
        case level
        case title
        case content
        case isDelisted = "is_delisted"
        case updatedAt = "updated_at"
    }

    /// 映射对应的 JLPT 等级枚举
    public var jlptLevel: JLPTLevel {
        JLPTLevel(rawValue: level.uppercased()) ?? .all
    }

    /// 首选接续形态描述
    public var connectionText: String {
        content?.usages?.first?.connection ?? ""
    }

    /// 首选核心释义说明
    public var explanationText: String {
        content?.usages?.first?.explanation ?? ""
    }

    /// 本地多维模糊搜索匹配
    public func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return title.localizedCaseInsensitiveContains(trimmed) ||
            explanationText.localizedCaseInsensitiveContains(trimmed) ||
            connectionText.localizedCaseInsensitiveContains(trimmed)
    }
}
