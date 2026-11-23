import Foundation

/// 本地学习进度与卡片状态持久化存储管理器（线程安全 Actor）
public actor LearningLocalStorage {
    public static let shared = LearningLocalStorage()

    private let fileManager: FileManager
    private let storageDirectory: URL

    private var statesFileURL: URL {
        storageDirectory.appendingPathComponent("study_states.json")
    }

    private var grammarStatesFileURL: URL {
        storageDirectory.appendingPathComponent("grammar_states.json")
    }

    private var recordsFileURL: URL {
        storageDirectory.appendingPathComponent("daily_records.json")
    }

    // 常驻内存字典缓存，保障高频 O(1) 零 I/O 访问
    private var statesCache: [Int: WordStudyState] = [:]
    private var grammarStatesCache: [Int: GrammarStudyState] = [:]
    private var recordsCache: [Int: StudyDailyRecord] = [:]
    private var isLoaded: Bool = false

    /// 支持外部构造注入沙盒路径（主要用于单元测试完全隔离）
    public init(storageDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let customDir = storageDirectory {
            self.storageDirectory = customDir
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.storageDirectory = appSupport.appendingPathComponent("NemoLearning", isDirectory: true)
        }
    }

    // MARK: - 逻辑学习日计算器 (对齐 Android 端 DateTimeUtils)

    /// 根据重置小时推算逻辑学习日 EpochDay
    /// - Parameters:
    ///   - date: 物理时间对象
    ///   - resetHour: 每日重置小时 (0-23，默认 4)
    /// - Returns: 逻辑 EpochDay
    public static func getLearningDay(from date: Date = Date(), resetHour: Int = 4) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        var targetDate = date
        let hour = calendar.component(.hour, from: date)
        if hour < resetHour {
            targetDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        let startOfDay = calendar.startOfDay(for: targetDate)
        let seconds = startOfDay.timeIntervalSince1970
        return Int(floor(seconds / 86400.0))
    }

    // MARK: - 内部冷启动与数据加载

    private func ensureDirectoryExists() throws {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }

    private func loadIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true

        // 1. 加载单词卡片学习状态
        if fileManager.fileExists(atPath: statesFileURL.path) {
            do {
                let data = try Data(contentsOf: statesFileURL)
                let states = try JSONDecoder().decode([WordStudyState].self, from: data)
                for state in states {
                    statesCache[state.wordId] = state
                }
            } catch {
                backupCorruptedFile(at: statesFileURL)
                statesCache = [:]
            }
        }

        // 2. 加载语法卡片学习状态
        if fileManager.fileExists(atPath: grammarStatesFileURL.path) {
            do {
                let data = try Data(contentsOf: grammarStatesFileURL)
                let states = try JSONDecoder().decode([GrammarStudyState].self, from: data)
                for state in states {
                    grammarStatesCache[state.grammarId] = state
                }
            } catch {
                backupCorruptedFile(at: grammarStatesFileURL)
                grammarStatesCache = [:]
            }
        }

        // 3. 加载每日打卡记录
        if fileManager.fileExists(atPath: recordsFileURL.path) {
            do {
                let data = try Data(contentsOf: recordsFileURL)
                let records = try JSONDecoder().decode([StudyDailyRecord].self, from: data)
                for record in records {
                    recordsCache[record.date] = record
                }
            } catch {
                backupCorruptedFile(at: recordsFileURL)
                recordsCache = [:]
            }
        }
    }

    private func backupCorruptedFile(at fileURL: URL) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupURL = fileURL.deletingPathExtension().appendingPathExtension("corrupted_\(timestamp)")
        try? fileManager.moveItem(at: fileURL, to: backupURL)
    }

    private func persistStatesToDisk() throws {
        try ensureDirectoryExists()
        let statesArray = Array(statesCache.values).sorted(by: { $0.wordId < $1.wordId })
        let data = try JSONEncoder().encode(statesArray)
        try data.write(to: statesFileURL, options: [.atomic])
    }

    private func persistGrammarStatesToDisk() throws {
        try ensureDirectoryExists()
        let statesArray = Array(grammarStatesCache.values).sorted(by: { $0.grammarId < $1.grammarId })
        let data = try JSONEncoder().encode(statesArray)
        try data.write(to: grammarStatesFileURL, options: [.atomic])
    }

    private func persistRecordsToDisk() throws {
        try ensureDirectoryExists()
        let recordsArray = Array(recordsCache.values).sorted(by: { $0.date < $1.date })
        let data = try JSONEncoder().encode(recordsArray)
        try data.write(to: recordsFileURL, options: [.atomic])
    }

    // MARK: - 单词卡片状态存取公开 API

    /// 查询单个单词卡片的学习状态，若未学习则返回 nil
    public func getStudyState(wordId: Int) async throws -> WordStudyState? {
        loadIfNeeded()
        return statesCache[wordId]
    }

    /// 获取全部已收录单词卡片学习状态字典
    public func getAllStudyStates() async throws -> [Int: WordStudyState] {
        loadIfNeeded()
        return statesCache
    }

    /// 筛选获取待复习单词卡片（已到期或逾期、非新卡、未跳过）
    public func getDueStudyStates(today: Int) async throws -> [WordStudyState] {
        loadIfNeeded()
        let filtered = statesCache.values.filter { state in
            state.nextReviewDate > 0 && state.nextReviewDate <= today && state.type != 0 && !state.isSkipped
        }
        return filtered.sorted(by: { $0.nextReviewDate < $1.nextReviewDate })
    }

    /// 单个单词卡片持久化保存（原子写盘）
    public func saveStudyState(_ state: WordStudyState) async throws {
        loadIfNeeded()
        statesCache[state.wordId] = state
        try persistStatesToDisk()
    }

    /// 批量单词卡片持久化保存（原子写盘）
    public func saveStudyStates(_ states: [WordStudyState]) async throws {
        loadIfNeeded()
        for state in states {
            statesCache[state.wordId] = state
        }
        try persistStatesToDisk()
    }

    // MARK: - 语法卡片状态存取公开 API

    /// 查询单个语法卡片的学习状态，若未学习则返回 nil
    public func getGrammarStudyState(grammarId: Int) async throws -> GrammarStudyState? {
        loadIfNeeded()
        return grammarStatesCache[grammarId]
    }

    /// 获取全部已收录语法卡片学习状态字典
    public func getAllGrammarStudyStates() async throws -> [Int: GrammarStudyState] {
        loadIfNeeded()
        return grammarStatesCache
    }

    /// 筛选获取待复习语法卡片（已到期或逾期、非新卡、未跳过）
    public func getDueGrammarStudyStates(today: Int) async throws -> [GrammarStudyState] {
        loadIfNeeded()
        let filtered = grammarStatesCache.values.filter { state in
            state.nextReviewDate > 0 && state.nextReviewDate <= today && state.type != 0 && !state.isSkipped
        }
        return filtered.sorted(by: { $0.nextReviewDate < $1.nextReviewDate })
    }

    /// 单个语法卡片持久化保存（原子写盘）
    public func saveGrammarStudyState(_ state: GrammarStudyState) async throws {
        loadIfNeeded()
        grammarStatesCache[state.grammarId] = state
        try persistGrammarStatesToDisk()
    }

    /// 批量语法卡片持久化保存（原子写盘）
    public func saveGrammarStudyStates(_ states: [GrammarStudyState]) async throws {
        loadIfNeeded()
        for state in states {
            grammarStatesCache[state.grammarId] = state
        }
        try persistGrammarStatesToDisk()
    }

    // MARK: - 打卡统计与连续打卡 Streak 公开 API

    /// 记录每日学习增量并落盘（兼容旧单测调用）
    public func recordDailyStudy(learnedIncrement: Int, reviewedIncrement: Int, date: Int) async throws {
        try await recordDailyStudy(
            learnedWordsIncrement: learnedIncrement,
            reviewedWordsIncrement: reviewedIncrement,
            learnedGrammarsIncrement: 0,
            reviewedGrammarsIncrement: 0,
            date: date
        )
    }

    /// 记录每日语法学习增量并落盘
    public func recordDailyGrammarStudy(learnedIncrement: Int, reviewedIncrement: Int, date: Int) async throws {
        try await recordDailyStudy(
            learnedWordsIncrement: 0,
            reviewedWordsIncrement: 0,
            learnedGrammarsIncrement: learnedIncrement,
            reviewedGrammarsIncrement: reviewedIncrement,
            date: date
        )
    }

    /// 记录多模式每日学习综合增量并落盘
    public func recordDailyStudy(
        learnedWordsIncrement: Int,
        reviewedWordsIncrement: Int,
        learnedGrammarsIncrement: Int,
        reviewedGrammarsIncrement: Int,
        date: Int
    ) async throws {
        loadIfNeeded()
        var record = recordsCache[date] ?? StudyDailyRecord(date: date)
        record.learnedWords += learnedWordsIncrement
        record.reviewedWords += reviewedWordsIncrement
        record.learnedGrammars += learnedGrammarsIncrement
        record.reviewedGrammars += reviewedGrammarsIncrement
        record.updatedAt = Date()
        recordsCache[date] = record
        try persistRecordsToDisk()
    }

    /// 动态推算当前连续打卡天数（Streak，涵盖单词与语法总活动）
    public func calculateCurrentStreak(today: Int) async throws -> Int {
        loadIfNeeded()
        let validDates = Set(recordsCache.values.filter { $0.totalCount > 0 }.map { $0.date })
        if validDates.isEmpty {
            return 0
        }

        var cursor: Int
        if validDates.contains(today) {
            cursor = today
        } else if validDates.contains(today - 1) {
            cursor = today - 1
        } else {
            return 0
        }

        var streak = 0
        while validDates.contains(cursor) {
            streak += 1
            cursor -= 1
        }
        return streak
    }

    /// 获取指定日期的打卡记录
    public func getTodayRecord(today: Int) async throws -> StudyDailyRecord? {
        loadIfNeeded()
        return recordsCache[today]
    }

    /// 获取全部打卡记录
    public func getAllRecords() async throws -> [Int: StudyDailyRecord] {
        loadIfNeeded()
        return recordsCache
    }

    // MARK: - 清理与重置

    /// 清空所有内存缓存及磁盘持久化文件
    public func clearAllData() async throws {
        statesCache.removeAll()
        grammarStatesCache.removeAll()
        recordsCache.removeAll()
        try? fileManager.removeItem(at: statesFileURL)
        try? fileManager.removeItem(at: grammarStatesFileURL)
        try? fileManager.removeItem(at: recordsFileURL)
        isLoaded = true
    }
}
