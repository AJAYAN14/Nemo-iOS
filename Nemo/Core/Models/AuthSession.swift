import Foundation

/// 用户认证会话凭据模型
public struct AuthSession: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let expiresAt: Date
    public var user: User

    public init(
        accessToken: String,
        refreshToken: String,
        tokenType: String = "bearer",
        expiresIn: Int = 3600,
        expiresAt: Date = Date().addingTimeInterval(3600),
        user: User
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.expiresAt = expiresAt
        self.user = user
    }

    /// 会话是否已经过期（预留 60 秒缓冲区）
    public var isExpired: Bool {
        Date().addingTimeInterval(60) >= expiresAt
    }
}
