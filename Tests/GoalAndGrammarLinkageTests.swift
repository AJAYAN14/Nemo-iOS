import Foundation

// =====================================================================
// Nemo iOS: 每日单词目标、语法目标与持久化全流程单元测试套件
// =====================================================================

public final class GoalTestSandbox: @unchecked Sendable {
    public let sandboxURL: URL
    private let fileManager = FileManager.default

    public init(prefix: String = "GoalTest_") {
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

public struct GoalAssertionFailure: Error, CustomStringConvertible {
    public let message: String
    public let file: String
    public let line: Int

    public var description: String {
        return "❌ 断言失败 [\(URL(fileURLWithPath: file).lastPathComponent):\(line)]: \(message)"
    }
}

public func gAssert(_ condition: @autoclosure () -> Bool, _ message: String = "", file: String = #file, line: Int = #line) throws {
    if !condition() {
        throw GoalAssertionFailure(message: message.isEmpty ? "预期为 true，但实际为 false" : message, file: file, line: line)
    }
}

public func gAssertEqual<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: @autoclosure () -> T, _ message: String = "", file: String = #file, line: Int = #line) throws {
    let act = actual()
    let exp = expected()
    if act != exp {
        throw GoalAssertionFailure(message: "\(message) [期望: <\(exp)>, 实际: <\(act)>]", file: file, line: line)
    }
}

public final class GoalAndGrammarLinkageTests: @unchecked Sendable {

    // G01: StudyDailyRecord 语法字段与无损向后兼容
    public static func testRecordGrammarSerialization() throws {
        var record = StudyDailyRecord(date: 20000, learnedWords: 10, reviewedWords: 15, learnedGrammars: 5, reviewedGrammars: 8)
        try gAssertEqual(record.totalWords, 25, "单词总数计算错误")
        try gAssertEqual(record.totalGrammars, 13, "语法总数计算错误")
        try gAssertEqual(record.totalCount, 38, "总活动数计算错误")

        let encoder = JSONEncoder()
        let data = try encoder.encode(record)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StudyDailyRecord.self, from: data)

        try gAssertEqual(decoded.learnedGrammars, 5, "语法新学数解码失败")
        try gAssertEqual(decoded.reviewedGrammars, 8, "语法复习数解码失败")

        // 测试旧版本 JSON（无语法字段）的向后兼容解码
        let legacyJson = """
        {"date": 19500, "learnedWords": 20, "reviewedWords": 10}
        """.data(using: .utf8)!
        let legacyDecoded = try decoder.decode(StudyDailyRecord.self, from: legacyJson)
        try gAssertEqual(legacyDecoded.learnedWords, 20, "旧版本单词解析错误")
        try gAssertEqual(legacyDecoded.learnedGrammars, 0, "旧版本语法新学应默认0")
        try gAssertEqual(legacyDecoded.reviewedGrammars, 0, "旧版本语法复习应默认0")
    }

    // G02: GrammarStudyState 构造与 update
    public static func testGrammarStudyStateUpdate() throws {
        var state = GrammarStudyState.newCard(grammarId: 501)
        try gAssertEqual(state.grammarId, 501, "语法ID不匹配")
        try gAssertEqual(state.type, 0, "初始状态类型应为0(new)")

        let updateResult = SrsUpdateResult(
            repetitionCount: 1,
            stability: 2.5,
            difficulty: 4.8,
            interval: 3,
            nextReviewDate: 20003,
            lastReviewedDate: 20000,
            firstLearnedDate: 20000,
            type: 2
        )
        state.update(with: updateResult)

        try gAssertEqual(state.repetitionCount, 1, "复习次数更新错误")
        try gAssertEqual(state.interval, 3, "间隔天数更新错误")
        try gAssertEqual(state.nextReviewDate, 20003, "下次复习绝对日期更新错误")
        try gAssertEqual(state.type, 2, "状态类型更新错误")
    }

    // G03: 逻辑学习日推算（对比凌晨与白天）
    public static func testLearningDayCalculation() throws {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        // 构造一个当天的上午 10:00 (大于 4:00 重置时间)
        var compDay = DateComponents()
        compDay.year = 2026
        compDay.month = 11
        compDay.day = 23
        compDay.hour = 10
        let dateDay = calendar.date(from: compDay)!
        let epochDay1 = LearningLocalStorage.getLearningDay(from: dateDay, resetHour: 4)

        // 构造一个当天的凌晨 02:00 (小于 4:00 重置时间，应算作前一天)
        var compNight = DateComponents()
        compNight.year = 2026
        compNight.month = 11
        compNight.day = 23
        compNight.hour = 2
        let dateNight = calendar.date(from: compNight)!
        let epochDay2 = LearningLocalStorage.getLearningDay(from: dateNight, resetHour: 4)

        try gAssertEqual(epochDay1 - epochDay2, 1, "凌晨2点应归入前一个逻辑学习日，与上午10点差1天")
    }

    // G04 & G05: 语法卡片持久化保存与批量查询
    public static func testGrammarPersistence() async throws {
        let sandbox = GoalTestSandbox()
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)

        let g1 = GrammarStudyState(grammarId: 101, repetitionCount: 2, stability: 3.0, difficulty: 5.0, interval: 4, nextReviewDate: 20004, type: 2)
        let g2 = GrammarStudyState(grammarId: 102, repetitionCount: 1, stability: 1.5, difficulty: 6.0, interval: 1, nextReviewDate: 20001, type: 1)

        try await storage.saveGrammarStudyState(g1)
        let fetched = try await storage.getGrammarStudyState(grammarId: 101)
        try gAssert(fetched != nil, "查询语法卡片失败")
        try gAssertEqual(fetched?.interval, 4, "保存语法间隔不一致")

        try await storage.saveGrammarStudyStates([g1, g2])
        let all = try await storage.getAllGrammarStudyStates()
        try gAssertEqual(all.count, 2, "批量获取语法数量不正确")
    }

    // G06: getDueGrammarStudyStates 准确性
    public static func testDueGrammarsQuery() async throws {
        let sandbox = GoalTestSandbox()
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)

        let dueG = GrammarStudyState(grammarId: 201, nextReviewDate: 20000, type: 2)
        let futureG = GrammarStudyState(grammarId: 202, nextReviewDate: 20005, type: 2)
        let newG = GrammarStudyState(grammarId: 203, nextReviewDate: 0, type: 0)

        try await storage.saveGrammarStudyStates([dueG, futureG, newG])
        let dueList = try await storage.getDueGrammarStudyStates(today: 20000)

        try gAssertEqual(dueList.count, 1, "待复习语法筛选数量应为1")
        try gAssertEqual(dueList.first?.grammarId, 201, "待复习语法ID不匹配")
    }

    // G07: 多模式打卡数据增量隔离与累计
    public static func testMultiModeDailyRecord() async throws {
        let sandbox = GoalTestSandbox()
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)

        let today = 20000
        try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 5, date: today)
        try await storage.recordDailyGrammarStudy(learnedIncrement: 3, reviewedIncrement: 2, date: today)

        let record = try await storage.getTodayRecord(today: today)
        try gAssert(record != nil, "今日记录不存在")
        try gAssertEqual(record?.learnedWords, 10, "单词新学数错误")
        try gAssertEqual(record?.reviewedWords, 5, "单词复习数错误")
        try gAssertEqual(record?.learnedGrammars, 3, "语法新学数错误")
        try gAssertEqual(record?.reviewedGrammars, 2, "语法复习数错误")
        try gAssertEqual(record?.totalCount, 20, "总活动数应为 10+5+3+2=20")
    }

    // G08: 仅学语法也能打卡并累加 Streak
    public static func testGrammarStreak() async throws {
        let sandbox = GoalTestSandbox()
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)

        // 模拟连续 3 天只有语法学习
        try await storage.recordDailyGrammarStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 19998)
        try await storage.recordDailyGrammarStudy(learnedIncrement: 0, reviewedIncrement: 4, date: 19999)
        try await storage.recordDailyGrammarStudy(learnedIncrement: 2, reviewedIncrement: 2, date: 20000)

        let streak = try await storage.calculateCurrentStreak(today: 20000)
        try gAssertEqual(streak, 3, "语法学习也应正确维持3天Streak")
    }

    // G09: 单词与语法交替打卡
    public static func testMixedStreak() async throws {
        let sandbox = GoalTestSandbox()
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)

        // 第1天学单词，第2天学语法，第3天双学
        try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 19998)
        try await storage.recordDailyGrammarStudy(learnedIncrement: 3, reviewedIncrement: 0, date: 19999)
        try await storage.recordDailyStudy(learnedWordsIncrement: 5, reviewedWordsIncrement: 2, learnedGrammarsIncrement: 2, reviewedGrammarsIncrement: 1, date: 20000)

        let streak = try await storage.calculateCurrentStreak(today: 20000)
        try gAssertEqual(streak, 3, "混合模式学习应正确维持3天Streak")
    }

    // G10: 宽限期与断签
    public static func testStreakGracePeriod() async throws {
        let sandbox = GoalTestSandbox()
        let storage = LearningLocalStorage(storageDirectory: sandbox.sandboxURL)

        try await storage.recordDailyGrammarStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 19999)
        // 今天 (20000) 尚未打卡，但昨天已打卡，宽限期维持 1
        let streakGrace = try await storage.calculateCurrentStreak(today: 20000)
        try gAssertEqual(streakGrace, 1, "今日未学但昨日已学时宽限期Streak应为1")

        // 超过一天未打卡 (断签)
        let streakBroken = try await storage.calculateCurrentStreak(today: 20002)
        try gAssertEqual(streakBroken, 0, "断签应归零")
    }
}

@main
struct GoalTestRunner {
    static func main() async {
        print("==================================================================")
        print("🚀 Nemo iOS: 每日目标与语法闭环自动化单测套件")
        print("==================================================================")

        var total = 0
        var passed = 0

        func runTest(_ name: String, block: () async throws -> Void) async {
            total += 1
            let start = Date()
            do {
                try await block()
                let elapsed = Date().timeIntervalSince(start) * 1000
                print(String(format: "  ✅ [PASS] %@ (%.2fms)", name, elapsed))
                passed += 1
            } catch {
                print("  ❌ [FAIL] \(name): \(error)")
            }
        }

        await runTest("G01: StudyDailyRecord 语法字段与无损向后兼容") {
            try GoalAndGrammarLinkageTests.testRecordGrammarSerialization()
        }
        await runTest("G02: GrammarStudyState 构造与状态推演更新") {
            try GoalAndGrammarLinkageTests.testGrammarStudyStateUpdate()
        }
        await runTest("G03: 逻辑学习日推算与重置时间判定") {
            try GoalAndGrammarLinkageTests.testLearningDayCalculation()
        }
        await runTest("G04 & G05: 语法卡片持久化保存与批量获取") {
            try await GoalAndGrammarLinkageTests.testGrammarPersistence()
        }
        await runTest("G06: 待复习语法 getDueGrammarStudyStates 精准筛选") {
            try await GoalAndGrammarLinkageTests.testDueGrammarsQuery()
        }
        await runTest("G07: 多模式打卡数据增量隔离与累计") {
            try await GoalAndGrammarLinkageTests.testMultiModeDailyRecord()
        }
        await runTest("G08: 仅学语法也能打卡并累加 Streak") {
            try await GoalAndGrammarLinkageTests.testGrammarStreak()
        }
        await runTest("G09: 单词与语法交替打卡连续天数连贯") {
            try await GoalAndGrammarLinkageTests.testMixedStreak()
        }
        await runTest("G10: 宽限期与断签 Streak 状态准确推算") {
            try await GoalAndGrammarLinkageTests.testStreakGracePeriod()
        }

        print("==================================================================")
        print("🎯 目标联动与语法闭环单测总结: 总用例 \(total) | 通过: \(passed) | 失败: \(total - passed)")
        print("==================================================================")

        if passed == total {
            print("🎉 恭喜！全部 10 项目标联动与语法闭环单测 100% 绿灯通过！")
            exit(0)
        } else {
            print("❌ 存在失败用例，请排查！")
            exit(1)
        }
    }
}
