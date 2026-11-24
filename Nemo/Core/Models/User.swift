import Foundation

/// 用户领域实体模型
public struct User: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var username: String
    public var email: String?
    public var avatarUrl: String?
    public var sessionToken: String
    public var hasGoogleLinked: Bool
    public var isOnlyGoogleIdentity: Bool
    public var isNewUser: Bool

    public init(
        id: String,
        username: String,
        email: String? = nil,
        avatarUrl: String? = nil,
        sessionToken: String = "",
        hasGoogleLinked: Bool = false,
        isOnlyGoogleIdentity: Bool = false,
        isNewUser: Bool = false
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarUrl = avatarUrl
        self.sessionToken = sessionToken
        self.hasGoogleLinked = hasGoogleLinked
        self.isOnlyGoogleIdentity = isOnlyGoogleIdentity
        self.isNewUser = isNewUser
    }
}
