import Foundation
import Combine

/// 应用启动数据初始化与词库同步调度器
@MainActor
public final class AppStartupManager: ObservableObject {
    public static let shared = AppStartupManager()

    @Published public private(set) var isStartupSyncing: Bool = false
    @Published public private(set) var isDictionaryReady: Bool = false
    @Published public private(set) var lastSyncResult: DictionarySyncResult? = nil
    @Published public private(set) var lastError: Error? = nil

    private let syncManager: DictionarySyncManager
    private let localStorage: DictionaryLocalStorage

    public init(
        syncManager: DictionarySyncManager = .shared,
        localStorage: DictionaryLocalStorage = .shared
    ) {
        self.syncManager = syncManager
        self.localStorage = localStorage
    }

    /// 应用启动时非阻塞异步触发词库同步与本地预热
    public func performStartupSync() {
        Task(priority: .userInitiated) { [weak self] in
            await self?.executeStartupSync()
        }
    }

    /// 核心同步执行逻辑（支持直接异步调用）
    public func executeStartupSync() async {
        guard !isStartupSyncing else { return }

        isStartupSyncing = true
        lastError = nil
        defer {
            isStartupSyncing = false
        }

        // 1. 本地沙盒预热与数量快照核验
        let localWordCount = await localStorage.getWordCount()
        let localGrammarCount = await localStorage.getGrammarCount()
        if localWordCount > 0 && localGrammarCount > 0 {
            isDictionaryReady = true
        }

        // 2. 触发云端版本核对与增量/全量同步
        do {
            let result = try await syncManager.performDictionarySync(forceFullSync: false)
            lastSyncResult = result
            isDictionaryReady = true
        } catch {
            // 3. 离线弱网静默降级：捕获暂态网络异常，保护本地离线可用性
            lastError = error
            let ready = await syncManager.isDictionaryReady()
            isDictionaryReady = ready || (localWordCount > 0)
        }
    }

    /// 重新核验本地词库就绪状态
    public func refreshReadiness() async {
        let ready = await syncManager.isDictionaryReady()
        let wordCount = await localStorage.getWordCount()
        isDictionaryReady = ready || (wordCount > 0)
    }
}
