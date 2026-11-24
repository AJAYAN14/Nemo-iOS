import Foundation

/// 用户认证状态与会话本地持久化管理器
public actor AuthLocalStorage {
    public static let shared = AuthLocalStorage()

    private let fileManager = FileManager.default
    private var cachedSession: AuthSession?

    private var storageDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("NemoAuth", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var sessionFileURL: URL {
        storageDirectory.appendingPathComponent("session_credentials.json")
    }

    public init() {}

    /// 保存会话凭据至持久化存储
    public func saveSession(_ session: AuthSession) throws {
        self.cachedSession = session
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(session)
        try data.write(to: sessionFileURL, options: .atomic)
    }

    /// 读取持久化保存的会话
    public func loadSession() -> AuthSession? {
        if let session = cachedSession {
            return session
        }

        guard fileManager.fileExists(atPath: sessionFileURL.path),
              let data = try? Data(contentsOf: sessionFileURL) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let session = try? decoder.decode(AuthSession.self, from: data) {
            self.cachedSession = session
            return session
        }
        return nil
    }

    /// 清空本地持久化凭据与内存缓存
    public func clearSession() throws {
        self.cachedSession = nil
        if fileManager.fileExists(atPath: sessionFileURL.path) {
            try fileManager.removeItem(at: sessionFileURL)
        }
    }

    /// 检查本地是否存在有效会话
    public func hasValidSession() -> Bool {
        guard let session = loadSession() else { return false }
        return !session.isExpired
    }

    /// 更新本地缓存中的当前用户信息
    public func updateCurrentUser(_ user: User) throws {
        guard var session = loadSession() else { return }
        session.user = user
        try saveSession(session)
    }
}
