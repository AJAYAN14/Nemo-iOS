import Foundation
#if canImport(XCTest)
import XCTest
#endif

// =====================================================================
// Nemo iOS M2: 本地学习进度与卡片状态持久化层 (F4 & F5) 单元测试套件
// 支持 XCTest 与 CLI 独立秒级命令行执行
// =====================================================================

// MARK: - 测试沙盒辅助类 (保证每个测试用例完全隔离)
public final class TestSandbox: @unchecked Sendable {
    public let sandboxURL: URL
    private let fileManager = FileManager.default
    
    public init(prefix: String = "M2_Test_") {
        let tempDir = fileManager.temporaryDirectory
        self.sandboxURL = tempDir.appendingPathComponent("\(prefix)\(UUID().uuidString)", isDirectory: true)
        try? fileManager.createDirectory(at: sandboxURL, withIntermediateDirectories: true)
    }
    
    public func cleanUp() {
        try? fileManager.removeItem(at: sandboxURL)
    }
    
    deinit {
        cleanUp()
    }
}

// MARK: - 测试断言辅助工具
public struct TestAssertionFailure: Error, CustomStringConvertible {
    public let message: String
    public let file: String
    public let line: Int
    
    public var description: String {
        return "❌ 断言失败 [\(URL(fileURLWithPath: file).lastPathComponent):\(line)]: \(message)"
    }
}

public func assertCondition(_ condition: @autoclosure () -> Bool, _ message: String = "", file: String = #file, line: Int = #line) throws {
    if !condition() {
        throw TestAssertionFailure(message: message.isEmpty ? "预期为 true，但实际为 false" : message, file: file, line: line)
    }
}

public func assertEqual<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: @autoclosure () -> T, _ message: String = "", file: String = #file, line: Int = #line) throws {
    let act = actual()
    let exp = expected()
    if act != exp {
        throw TestAssertionFailure(message: "\(message) [期望: <\(exp)>, 实际: <\(act)>]", file: file, line: line)
    }
}

public func assertApproxEqual(_ actual: Double, _ expected: Double, accuracy: Double = 0.001, _ message: String = "", file: String = #file, line: Int = #line) throws {
    let diff = abs(actual - expected)
    if diff > accuracy {
        throw TestAssertionFailure(message: "\(message) [期望: <\(expected)>, 实际: <\(actual)>, 误差: <\(diff)> > <\(accuracy)>]", file: file, line: line)
    }
}

public func assertNotNil<T>(_ value: @autoclosure () -> T?, _ message: String = "", file: String = #file, line: Int = #line) throws {
    if value() == nil {
        throw TestAssertionFailure(message: message.isEmpty ? "预期对象不为 nil，但实际为 nil" : message, file: file, line: line)
    }
}

public func assertNil<T>(_ value: @autoclosure () -> T?, _ message: String = "", file: String = #file, line: Int = #line) throws {
    if let v = value() {
        throw TestAssertionFailure(message: message.isEmpty ? "预期为 nil，但实际有值: \(v)" : message, file: file, line: line)
    }
}

// MARK: - M2 单元测试套件实现
public final class LearningPersistenceTestSuite: Sendable {
    public init() {}
    
    // MARK: [Suite 1: 模型与契约测试]
    
    /// P01: WordStudyState 默认构造与工厂方法 newCard 字段正确性
    public func testWordStudyStateDefaultsAndFactory() throws {
        let state = WordStudyState(wordId: 42)
        try assertEqual(state.wordId, 42)
        try assertEqual(state.repetitionCount, 0)
        try assertApproxEqual(state.stability, 0.0)
        try assertApproxEqual(state.difficulty, 0.0)
        try assertEqual(state.interval, 0)
        try assertEqual(state.nextReviewDate, 0)
        try assertNil(state.lastReviewedDate)
        try assertNil(state.firstLearnedDate)
        try assertEqual(state.type, 0)
        try assertCondition(!state.isFavorite, "默认未收藏")
        try assertCondition(!state.isSkipped, "默认未跳过")
        
        let newCard = WordStudyState.newCard(wordId: 1001)
        try assertEqual(newCard.wordId, 1001)
        try assertEqual(newCard.type, 0)
    }
    
    /// P02: WordStudyState 原地更新 update(with:) 各字段精确同步
    public func testWordStudyStateMutatingUpdate() throws {
        var card = WordStudyState.newCard(wordId: 7)
        let srsResult1 = SrsUpdateResult(
            repetitionCount: 1,
            stability: 2.3065,
            difficulty: 5.5,
            interval: 2,
            nextReviewDate: 102,
            lastReviewedDate: 100,
            firstLearnedDate: 100,
            type: 2
        )
        card.update(with: srsResult1)
        try assertEqual(card.repetitionCount, 1)
        try assertApproxEqual(card.stability, 2.3065)
        try assertApproxEqual(card.difficulty, 5.5)
        try assertEqual(card.interval, 2)
        try assertEqual(card.nextReviewDate, 102)
        try assertEqual(card.lastReviewedDate, 100)
        try assertEqual(card.firstLearnedDate, 100)
        try assertEqual(card.type, 2)
        
        // 再次复习，首学时间 firstLearnedDate 必须保持不变，不被重写
        let srsResult2 = SrsUpdateResult(
            repetitionCount: 2,
            stability: 5.678,
            difficulty: 5.2,
            interval: 5,
            nextReviewDate: 107,
            lastReviewedDate: 102,
            firstLearnedDate: 102, // 模拟计算器返回的新时间，但在 update 内部应保留原 firstLearnedDate
            type: 2
        )
        card.update(with: srsResult2)
        try assertEqual(card.repetitionCount, 2)
        try assertEqual(card.lastReviewedDate, 102)
        try assertEqual(card.firstLearnedDate, 100, "首次学习时间应始终保持首日，不被后续复习覆盖")
    }
    
    /// P03: StudyDailyRecord 增量累计与别名属性一致性
    public func testStudyDailyRecordPropertiesAndAliases() throws {
        var record = StudyDailyRecord(date: 100, learnedWords: 10, reviewedWords: 5)
        try assertEqual(record.date, 100)
        try assertEqual(record.learnedWords, 10)
        try assertEqual(record.reviewedWords, 5)
        try assertEqual(record.learnedCount, 10)
        try assertEqual(record.reviewedCount, 5)
        try assertEqual(record.totalCount, 15)
        
        record.learnedCount += 3
        record.reviewedCount += 7
        try assertEqual(record.learnedWords, 13)
        try assertEqual(record.reviewedWords, 12)
        try assertEqual(record.totalCount, 25)
    }
    
    /// P04: 模型 JSON 序列化与反序列化无损往返
    public func testModelCodableRoundTrip() throws {
        let state = WordStudyState(
            wordId: 888,
            repetitionCount: 4,
            stability: 15.6789,
            difficulty: 4.321,
            interval: 15,
            nextReviewDate: 115,
            lastReviewedDate: 100,
            firstLearnedDate: 80,
            type: 2,
            isFavorite: true,
            isSkipped: false
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WordStudyState.self, from: data)
        
        try assertEqual(decoded.wordId, state.wordId)
        try assertEqual(decoded.repetitionCount, state.repetitionCount)
        try assertApproxEqual(decoded.stability, state.stability)
        try assertApproxEqual(decoded.difficulty, state.difficulty)
        try assertEqual(decoded.nextReviewDate, state.nextReviewDate)
        try assertEqual(decoded.isFavorite, true)
    }
    
    // MARK: [Suite 2: 持久化存储基础操作]
    
    /// P05: 单卡片写入并查询一致性
    public func testSingleCardSaveAndGet() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let card = WordStudyState(
            wordId: 101,
            repetitionCount: 2,
            stability: 6.5,
            difficulty: 5.0,
            interval: 6,
            nextReviewDate: 106,
            lastReviewedDate: 100,
            firstLearnedDate: 94,
            type: 2
        )
        try await storage.saveStudyState(card)
        
        let loaded = try await storage.getStudyState(wordId: 101)
        try assertNotNil(loaded)
        try assertEqual(loaded?.wordId, 101)
        try assertEqual(loaded?.repetitionCount, 2)
        try assertApproxEqual(loaded?.stability ?? 0, 6.5)
        try assertEqual(loaded?.nextReviewDate, 106)
    }
    
    /// P06: 批量卡片写入 saveStudyStates 与全量获取
    public func testBatchCardsSaveAndGetAll() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        var cards: [WordStudyState] = []
        for i in 1...50 {
            cards.append(WordStudyState(wordId: i, repetitionCount: 1, stability: Double(i), difficulty: 5.0, interval: i, nextReviewDate: 100 + i, lastReviewedDate: 100, firstLearnedDate: 100, type: 2))
        }
        try await storage.saveStudyStates(cards)
        
        let all = try await storage.getAllStudyStates()
        try assertEqual(all.count, 50)
        try assertEqual(all[25]?.wordId, 25)
    }
    
    /// P07: 状态查询未收录 wordId 准确返回 nil
    public func testUnlearnedWordReturnsNil() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let state = try await storage.getStudyState(wordId: 99999)
        try assertNil(state)
    }
    
    /// P08: 同一卡片重复写入原地覆盖更新
    public func testOverwritingExistingState() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let v1 = WordStudyState(wordId: 77, repetitionCount: 1, stability: 2.0)
        try await storage.saveStudyState(v1)
        let v2 = WordStudyState(wordId: 77, repetitionCount: 2, stability: 5.0)
        try await storage.saveStudyState(v2)
        
        let all = try await storage.getAllStudyStates()
        try assertEqual(all.count, 1, "相同 wordId 覆盖写入后条数必须为 1")
        let loaded = try await storage.getStudyState(wordId: 77)
        try assertEqual(loaded?.repetitionCount, 2)
        try assertApproxEqual(loaded?.stability ?? 0, 5.0)
    }
    
    // MARK: [Suite 3: 到期卡片筛选专项]
    
    /// P09: getDueStudyStates 准确筛选 nextReviewDate <= today 的卡片
    public func testDueStudyStatesFiltering() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let today = 100
        let overdueCard = WordStudyState(wordId: 1, repetitionCount: 1, interval: 5, nextReviewDate: 95, type: 2)
        let dueTodayCard = WordStudyState(wordId: 2, repetitionCount: 1, interval: 5, nextReviewDate: 100, type: 2)
        let futureCard = WordStudyState(wordId: 3, repetitionCount: 1, interval: 5, nextReviewDate: 105, type: 2)
        
        try await storage.saveStudyStates([overdueCard, dueTodayCard, futureCard])
        
        let dueCards = try await storage.getDueStudyStates(today: today)
        try assertEqual(dueCards.count, 2, "今日及过期卡片共 2 张")
        let dueIds = Set(dueCards.map { $0.wordId })
        try assertCondition(dueIds.contains(1))
        try assertCondition(dueIds.contains(2))
        try assertCondition(!dueIds.contains(3))
    }
    
    /// P10: getDueStudyStates 排除未到期卡片
    public func testDueStudyStatesExcludesFuture() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let future1 = WordStudyState(wordId: 10, nextReviewDate: 110, type: 2)
        let future2 = WordStudyState(wordId: 11, nextReviewDate: 120, type: 2)
        try await storage.saveStudyStates([future1, future2])
        
        let due = try await storage.getDueStudyStates(today: 100)
        try assertCondition(due.isEmpty, "所有卡片未到期时返回空集合")
    }
    
    /// P11: getDueStudyStates 对新卡 (type 0) 或无复习日期的边界处理
    public func testDueStudyStatesNewCardsHandling() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let newCard = WordStudyState(wordId: 20, repetitionCount: 0, nextReviewDate: 0, type: 0)
        try await storage.saveStudyState(newCard)
        
        let due = try await storage.getDueStudyStates(today: 100)
        try assertCondition(due.isEmpty, "未学习新卡 (nextReviewDate=0 或 type=0) 不应被列入常规待复习队列")
    }
    
    // MARK: [Suite 4: 原子写入与冷启动恢复专项]
    
    /// P12: 原子文件覆盖写入验证
    public func testAtomicFileWriteBehavior() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        // 连续进行 10 次写入
        for i in 1...10 {
            try await storage.saveStudyState(WordStudyState(wordId: i, repetitionCount: 1))
        }
        let statesFile = sandbox.sandboxURL.appendingPathComponent("study_states.json")
        try assertCondition(FileManager.default.fileExists(atPath: statesFile.path), "持久化物理文件必须存在")
        let data = try Data(contentsOf: statesFile)
        try assertCondition(data.count > 0, "物理文件不应为空")
    }
    
    /// P13: 冷启动仿真：多实例接力加载一致性
    public func testColdStartInstanceReload() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        
        // 实例 1 写入
        let storage1 = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        var originalStates: [WordStudyState] = []
        for i in 1...20 {
            originalStates.append(WordStudyState(wordId: i, repetitionCount: 2, stability: Double(i) * 1.5, nextReviewDate: 100 + i))
        }
        try await storage1.saveStudyStates(originalStates)
        try await storage1.recordDailyStudy(learnedIncrement: 15, reviewedIncrement: 5, date: 100)
        
        // 销毁实例 1，使用相同目录实例化全新的 storage2（模拟冷启动）
        let storage2 = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        let restoredStates = try await storage2.getAllStudyStates()
        try assertEqual(restoredStates.count, 20, "冷启动后状态条目必须完全恢复")
        try assertEqual(restoredStates[10]?.repetitionCount, 2)
        try assertApproxEqual(restoredStates[10]?.stability ?? 0, 15.0)
        
        let streak = try await storage2.calculateCurrentStreak(today: 100)
        try assertEqual(streak, 1, "冷启动后打卡连续天数完整恢复")
        let todayRec = try await storage2.getTodayRecord(today: 100)
        try assertEqual(todayRec?.totalCount, 20)
    }
    
    /// P14: 磁盘持久化文件初次缺失时自愈
    public func testMissingFileGracefulInit() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let states = try await storage.getAllStudyStates()
        try assertCondition(states.isEmpty)
        let records = try await storage.getAllRecords()
        try assertCondition(records.isEmpty)
    }
    
    /// P15: clearAllData 彻底清空内存缓存与磁盘物理文件
    public func testClearAllData() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        try await storage.saveStudyState(WordStudyState(wordId: 1))
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 5, date: 100)
        
        try await storage.clearAllData()
        let states = try await storage.getAllStudyStates()
        let records = try await storage.getAllRecords()
        try assertCondition(states.isEmpty, "清空后内存状态必须为空")
        try assertCondition(records.isEmpty, "清空后内存打卡必须为空")
    }
    
    // MARK: [Suite 5: 并发读写与线程安全专项]
    
    /// P16: 100 个并发 Task 密集竞争写入不同卡片
    public func testConcurrentMultiTaskWrites() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...100 {
                group.addTask {
                    try? await storage.saveStudyState(WordStudyState(wordId: i, repetitionCount: 1))
                }
            }
        }
        
        let all = try await storage.getAllStudyStates()
        try assertEqual(all.count, 100, "100 个并发写入必须无一丢失全部落盘")
    }
    
    /// P17: 读写并发交替混合操作一致性
    public func testConcurrentMixedReadWrites() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...50 {
                group.addTask {
                    try? await storage.saveStudyState(WordStudyState(wordId: i, repetitionCount: 1))
                }
                group.addTask {
                    _ = try? await storage.getStudyState(wordId: i)
                }
            }
        }
        let all = try await storage.getAllStudyStates()
        try assertEqual(all.count, 50)
    }
    
    /// P18: 并发打卡增量累加数据无丢失
    public func testConcurrentDailyStudyIncrements() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let date = 200
        await withTaskGroup(of: Void.self) { group in
            for _ in 1...50 {
                group.addTask {
                    try? await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 1, date: date)
                }
            }
        }
        let record = try await storage.getTodayRecord(today: date)
        try assertEqual(record?.learnedWords, 50, "并发50次递增，新学总数必须精确为 50")
        try assertEqual(record?.reviewedWords, 50, "并发50次递增，复习总数必须精确为 50")
        try assertEqual(record?.totalCount, 100)
    }
    
    // MARK: [Suite 6: 连续打卡 (Streak) 算法全边界验证专项]
    
    /// P19: 零打卡基准 (Streak = 0)
    public func testZeroStudyStreak() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        let streak = try await storage.calculateCurrentStreak(today: 100)
        try assertEqual(streak, 0, "从未打卡 Streak 为 0")
    }
    
    /// P20: 首日单次与同日多次打卡累加 (Streak = 1)
    public func testSameDayMultipleStudiesStreak() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 100)
        try await storage.recordDailyStudy(learnedIncrement: 0, reviewedIncrement: 5, date: 100)
        
        let streak = try await storage.calculateCurrentStreak(today: 100)
        try assertEqual(streak, 1, "同日多次打卡 Streak 保持为 1")
    }
    
    /// P21: 连续打卡 7 天与连续打卡 365 天无缝递增
    public func testContinuousStreakIncrement() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        // 连续 7 天
        for d in 101...107 {
            try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 5, date: d)
        }
        let streak7 = try await storage.calculateCurrentStreak(today: 107)
        try assertEqual(streak7, 7, "连续 7 天打卡 Streak 必须为 7")
        
        // 扩展至 365 天长周期
        for d in 108...465 {
            try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 0, date: d)
        }
        let streak365 = try await storage.calculateCurrentStreak(today: 465)
        try assertEqual(streak365, 365, "连续 365 天打卡 Streak 必须为 365")
    }
    
    /// P22: 今日未打卡但昨日已打卡的宽限期机制
    public func testGracePeriodYesterdayStreak() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        // 第 98, 99, 100 天打卡
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 98)
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 99)
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 100)
        
        // 第 101 天（今日）尚未打卡
        let streak101 = try await storage.calculateCurrentStreak(today: 101)
        try assertEqual(streak101, 3, "今日尚未打卡，处于宽限期，Streak 必须继承昨日连续打卡天数 3")
    }
    
    /// P23: 断签 1 天即中断归零，重新打卡从 1 起步
    public func testBrokenStreakReset() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        // 98, 99 打卡
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 98)
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 99)
        // 100 未打卡，今日为 101 也未打卡 -> 彻底断签
        let streakZero = try await storage.calculateCurrentStreak(today: 101)
        try assertEqual(streakZero, 0, "断签且宽限期已过，Streak 归 0")
        
        // 101 补打卡
        try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 101)
        let streakReset = try await storage.calculateCurrentStreak(today: 101)
        try assertEqual(streakReset, 1, "断签后重新打卡 Streak 重置为 1")
    }
    
    /// P24: 跨闰年与跨年 EpochDay 连续天数计算正确性
    public func testLeapYearAndNegativeEpochDayStreak() async throws {
        let sandbox = TestSandbox()
        defer { sandbox.cleanUp() }
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)
        
        // 2024 闰年 2月28(19781), 2月29(19782), 3月1日(19783)
        try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 0, date: 19781)
        try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 0, date: 19782)
        try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 0, date: 19783)
        let leapStreak = try await storage.calculateCurrentStreak(today: 19783)
        try assertEqual(leapStreak, 3, "闰年 2/28~3/1 基于 EpochDay 整数自增，连续打卡必须为 3")
        
        // EpochDay 负数边界
        try await storage.recordDailyStudy(learnedIncrement: 2, reviewedIncrement: 0, date: -1)
        try await storage.recordDailyStudy(learnedIncrement: 2, reviewedIncrement: 0, date: 0)
        let zeroStreak = try await storage.calculateCurrentStreak(today: 0)
        try assertEqual(zeroStreak, 2, "负 EpochDay 跨越至 0 连续打卡必须为 2")
    }
}

// MARK: - CLI 命令行独立运行入口
@main
public struct LearningPersistenceTestsRunner {
    public static func main() async {
        print("==================================================================")
        print("🚀 Nemo iOS M2: 本地学习进度与卡片持久化层自动化单测套件")
        print("==================================================================")
        
        let suite = LearningPersistenceTestSuite()
        let startTime = Date()
        var passedCount = 0
        var failedCount = 0
        
        typealias TestEntry = (id: String, name: String, block: () async throws -> Void)
        let tests: [TestEntry] = [
            ("P01", "WordStudyState 默认构造与工厂方法 newCard 字段正确性", { try suite.testWordStudyStateDefaultsAndFactory() }),
            ("P02", "WordStudyState 原地更新 update(with:) 各字段精确同步", { try suite.testWordStudyStateMutatingUpdate() }),
            ("P03", "StudyDailyRecord 增量累计与别名属性一致性", { try suite.testStudyDailyRecordPropertiesAndAliases() }),
            ("P04", "模型 JSON 序列化与反序列化无损往返", { try suite.testModelCodableRoundTrip() }),
            ("P05", "单卡片写入并查询一致性", { try await suite.testSingleCardSaveAndGet() }),
            ("P06", "批量卡片写入 saveStudyStates 与全量获取", { try await suite.testBatchCardsSaveAndGetAll() }),
            ("P07", "状态查询未收录 wordId 准确返回 nil", { try await suite.testUnlearnedWordReturnsNil() }),
            ("P08", "同一卡片重复写入原地覆盖更新", { try await suite.testOverwritingExistingState() }),
            ("P09", "getDueStudyStates 准确筛选 nextReviewDate <= today 的卡片", { try await suite.testDueStudyStatesFiltering() }),
            ("P10", "getDueStudyStates 排除未到期卡片", { try await suite.testDueStudyStatesExcludesFuture() }),
            ("P11", "getDueStudyStates 对新卡 (type 0) 或无复习日期的边界处理", { try await suite.testDueStudyStatesNewCardsHandling() }),
            ("P12", "原子文件覆盖写入验证", { try await suite.testAtomicFileWriteBehavior() }),
            ("P13", "冷启动仿真：多实例接力加载一致性", { try await suite.testColdStartInstanceReload() }),
            ("P14", "磁盘持久化文件初次缺失时自愈", { try await suite.testMissingFileGracefulInit() }),
            ("P15", "clearAllData 彻底清空内存缓存与磁盘物理文件", { try await suite.testClearAllData() }),
            ("P16", "100 个并发 Task 密集竞争写入不同卡片", { try await suite.testConcurrentMultiTaskWrites() }),
            ("P17", "读写并发交替混合操作一致性", { try await suite.testConcurrentMixedReadWrites() }),
            ("P18", "并发打卡增量累加数据无丢失", { try await suite.testConcurrentDailyStudyIncrements() }),
            ("P19", "零打卡基准 (Streak = 0)", { try await suite.testZeroStudyStreak() }),
            ("P20", "首日单次与同日多次打卡累加 (Streak = 1)", { try await suite.testSameDayMultipleStudiesStreak() }),
            ("P21", "连续打卡 7 天与连续打卡 365 天无缝递增", { try await suite.testContinuousStreakIncrement() }),
            ("P22", "今日未打卡但昨日已打卡的宽限期机制", { try await suite.testGracePeriodYesterdayStreak() }),
            ("P23", "断签 1 天即中断归零，重新打卡从 1 起步", { try await suite.testBrokenStreakReset() }),
            ("P24", "跨闰年与跨年 EpochDay 连续天数计算正确性", { try await suite.testLeapYearAndNegativeEpochDayStreak() })
        ]
        
        for t in tests {
            let caseStart = Date()
            do {
                try await t.block()
                let ms = String(format: "%.2fms", Date().timeIntervalSince(caseStart) * 1000.0)
                print("  ✅ [PASS] \(t.id): \(t.name) (\(ms))")
                passedCount += 1
            } catch {
                print("  ❌ [FAIL] \(t.id): \(t.name)")
                print("       ↳ \(error)")
                failedCount += 1
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        print("\n==================================================================")
        print("🎯 M2 单元测试总结: 总用例 \(tests.count) | 通过: \(passedCount) | 失败: \(failedCount)")
        print("⏱️ 总执行耗时: \(String(format: "%.3fs", totalDuration))")
        print("==================================================================")
        
        if failedCount == 0 {
            print("\n🎉 恭喜！全部 \(tests.count) 项 M2 持久化与 Streak 单测 100% 绿灯通过！\n")
            exit(0)
        } else {
            print("\n💥 警告：存在 \(failedCount) 项测试未通过，请检查实现！\n")
            exit(1)
        }
    }
}
