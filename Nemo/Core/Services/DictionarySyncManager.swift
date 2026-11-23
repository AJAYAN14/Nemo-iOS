//
//  DictionarySyncManager.swift
//  Nemo
//

import Foundation
import Combine

/// 词库同步执行结果
public struct DictionarySyncResult: Sendable {
    public let updatedWords: Int
    public let updatedGrammars: Int
    public let isFullSync: Bool
    public let localVersion: Int
    public let remoteVersion: Int

    public init(
        updatedWords: Int = 0,
        updatedGrammars: Int = 0,
        isFullSync: Bool = false,
        localVersion: Int = 0,
        remoteVersion: Int = 0
    ) {
        self.updatedWords = updatedWords
        self.updatedGrammars = updatedGrammars
        self.isFullSync = isFullSync
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
    }
}

/// 词库云端同步中枢（1:1 对齐 Android 端 DictionarySyncManagerImpl 架构与 +1ms 防重算法）
@MainActor
public final class DictionarySyncManager: ObservableObject {
    public static let shared = DictionarySyncManager()

    @Published public private(set) var isSyncing: Bool = false
    @Published public private(set) var syncProgress: Float = 0.0
    @Published public private(set) var lastSyncError: String? = nil
    @Published public private(set) var lastSyncResult: DictionarySyncResult? = nil

    private let supabaseService: SupabaseDictionaryService
    private let localStorage: DictionaryLocalStorage

    // MARK: - UserDefaults 键名（与 Android 保持语义对齐）
    private static let keyLastContentVersion = "settings_last_content_version"
    private static let keyLastDictionarySyncTimestamp = "settings_last_dictionary_sync_timestamp"
    private static let keyLastWordSyncTimestamp = "settings_last_word_sync_timestamp"
    private static let keyLastGrammarSyncTimestamp = "settings_last_grammar_sync_timestamp"

    public init(
        supabaseService: SupabaseDictionaryService = .shared,
        localStorage: DictionaryLocalStorage = .shared
    ) {
        self.supabaseService = supabaseService
        self.localStorage = localStorage
    }

    /// 检查本地词库是否满足最低可用门槛
    public func isDictionaryReady() async -> Bool {
        guard !isSyncing else { return false }
        let wordCount = await localStorage.getWordCount()
        let grammarCount = await localStorage.getGrammarCount()
        return wordCount >= 1000 && grammarCount >= 200
    }

    /// 执行云端词库同步（供后续登录界面回调或手动下拉刷新单行异步调用）
    /// - Parameter forceFullSync: 是否强制全量覆盖同步
    @discardableResult
    public func performDictionarySync(forceFullSync: Bool = false) async throws -> DictionarySyncResult {
        guard !isSyncing else {
            if let existing = lastSyncResult { return existing }
            return DictionarySyncResult()
        }

        isSyncing = true
        syncProgress = 0.0
        lastSyncError = nil
        defer {
            isSyncing = false
        }

        do {
            let remoteMeta = try await supabaseService.fetchSyncMeta()
            let remoteVersion = remoteMeta?.contentVersion
            let lastVersion = UserDefaults.standard.integer(forKey: Self.keyLastContentVersion)

            let lastWordSyncTimestamp = forceFullSync ? 0 : Int64(UserDefaults.standard.double(forKey: Self.keyLastWordSyncTimestamp))
            let lastGrammarSyncTimestamp = forceFullSync ? 0 : Int64(UserDefaults.standard.double(forKey: Self.keyLastGrammarSyncTimestamp))

            let wordCount = await localStorage.getWordCount()
            let grammarCount = await localStorage.getGrammarCount()
            let isDatabaseEmpty = wordCount == 0 || grammarCount == 0
            let isAnySyncRequired = lastWordSyncTimestamp == 0 || lastGrammarSyncTimestamp == 0

            let isFullSync = forceFullSync || isDatabaseEmpty || (lastWordSyncTimestamp == 0 && lastGrammarSyncTimestamp == 0)

            let needsUpdate = forceFullSync ||
                (remoteVersion != nil && (remoteVersion! > lastVersion || isDatabaseEmpty || isAnySyncRequired))

            guard needsUpdate else {
                let result = DictionarySyncResult(
                    updatedWords: 0,
                    updatedGrammars: 0,
                    isFullSync: false,
                    localVersion: lastVersion,
                    remoteVersion: remoteVersion ?? lastVersion
                )
                self.lastSyncResult = result
                return result
            }

            var allWords: [Word] = []
            var allGrammars: [Grammar] = []

            if isFullSync {
                async let fetchedWords = supabaseService.fetchAllWords { [weak self] current, total in
                    Task { @MainActor [weak self] in
                        guard let self = self, total > 0 else { return }
                        self.syncProgress = Float(current) / Float(total) * 0.7
                    }
                }
                async let fetchedGrammars = supabaseService.fetchAllGrammars { [weak self] current, total in
                    Task { @MainActor [weak self] in
                        guard let self = self, total > 0 else { return }
                        self.syncProgress = 0.7 + Float(current) / Float(total) * 0.3
                    }
                }

                allWords = try await fetchedWords
                allGrammars = try await fetchedGrammars

                if !allWords.isEmpty {
                    try await localStorage.saveWords(allWords)
                }
                if !allGrammars.isEmpty {
                    try await localStorage.saveGrammars(allGrammars)
                }
            } else {
                let wordTimestampDate = Date(timeIntervalSince1970: Double(lastWordSyncTimestamp) / 1000.0)
                let grammarTimestampDate = Date(timeIntervalSince1970: Double(lastGrammarSyncTimestamp) / 1000.0)

                let wordTimestampStr = Self.formatIso8601(wordTimestampDate)
                let grammarTimestampStr = Self.formatIso8601(grammarTimestampDate)

                async let fetchedWords = supabaseService.fetchWordsModifiedSince(timestamp: wordTimestampStr)
                async let fetchedGrammars = supabaseService.fetchGrammarsModifiedSince(timestamp: grammarTimestampStr)

                allWords = try await fetchedWords
                allGrammars = try await fetchedGrammars

                if !allWords.isEmpty {
                    try await localStorage.upsertWords(allWords)
                }
                if !allGrammars.isEmpty {
                    try await localStorage.upsertGrammars(allGrammars)
                }
            }

            // 更新同步锚点时间戳（移植 Android +1ms 防重算法，避免微秒精度丢失引发无限匹配）
            let maxWordTimestamp = allWords.compactMap { Self.parseIso8601($0.updatedAt) }
                .map { Int64($0.timeIntervalSince1970 * 1000.0) }
                .max()
                .map { $0 + 1 } ?? 0

            let maxGrammarTimestamp = allGrammars.compactMap { Self.parseIso8601($0.updatedAt) }
                .map { Int64($0.timeIntervalSince1970 * 1000.0) }
                .max()
                .map { $0 + 1 } ?? 0

            var newWordSyncTimestamp = max(lastWordSyncTimestamp, maxWordTimestamp)
            if isFullSync && newWordSyncTimestamp == 0 {
                newWordSyncTimestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
            }
            if newWordSyncTimestamp > lastWordSyncTimestamp {
                UserDefaults.standard.set(Double(newWordSyncTimestamp), forKey: Self.keyLastWordSyncTimestamp)
            }

            var newGrammarSyncTimestamp = max(lastGrammarSyncTimestamp, maxGrammarTimestamp)
            if isFullSync && newGrammarSyncTimestamp == 0 {
                newGrammarSyncTimestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
            }
            if newGrammarSyncTimestamp > lastGrammarSyncTimestamp {
                UserDefaults.standard.set(Double(newGrammarSyncTimestamp), forKey: Self.keyLastGrammarSyncTimestamp)
            }

            let finalGlobalTS = max(newWordSyncTimestamp, newGrammarSyncTimestamp)
            UserDefaults.standard.set(Double(finalGlobalTS), forKey: Self.keyLastDictionarySyncTimestamp)

            if let rv = remoteVersion {
                UserDefaults.standard.set(rv, forKey: Self.keyLastContentVersion)
            }

            self.syncProgress = 1.0
            let result = DictionarySyncResult(
                updatedWords: allWords.count,
                updatedGrammars: allGrammars.count,
                isFullSync: isFullSync,
                localVersion: lastVersion,
                remoteVersion: remoteVersion ?? lastVersion
            )
            self.lastSyncResult = result
            return result
        } catch {
            self.lastSyncError = error.localizedDescription
            throw error
        }
    }

    // MARK: - ISO8601 时间戳解析与格式化辅助方法

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func parseIso8601(_ string: String?) -> Date? {
        guard let string = string, !string.isEmpty else { return nil }
        if let d = iso8601WithFractionalSeconds.date(from: string) {
            return d
        }
        return iso8601Standard.date(from: string)
    }

    private static func formatIso8601(_ date: Date) -> String {
        return iso8601WithFractionalSeconds.string(from: date)
    }
}
