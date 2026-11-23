import Foundation

/// 词库同步元信息模型。
public struct SyncMeta: Codable, Sendable {
    public let id: Int
    public let minCompatibleVersion: Int
    public let contentVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case minCompatibleVersion = "min_compatible_version"
        case contentVersion = "content_version"
    }
}
