import Foundation

public struct Tier3_IntegrationTests {
    public static func registerAll() {
        registerScene1()
        registerScene2()
        registerScene3()
        registerScene4()
        registerScene5()
        registerScene6()
        registerScene7()
        registerScene8()
        registerScene9()
        registerScene10()
    }
    
    // MARK: - 场景 1: 算法到持久化管道集成
    private static func registerScene1() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_01", name: "INT_01_算法计算结果到持久化管道无损传递", tier: "Tier3") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            let calc = SrsCalculatorImpl()
            
            let initial = WordStudyState(wordId: 1001, repetitionCount: 2, stability: 5.0, difficulty: 5.5, interval: 5, nextReviewDate: 100, lastReviewedDate: 95, firstLearnedDate: 90, type: 2)
            let result = calc.calculate(item: initial, quality: 4, today: 100, itemId: 1001)
            
            let updated = WordStudyState(
                wordId: 1001,
                repetitionCount: result.repetitionCount,
                stability: result.stability,
                difficulty: result.difficulty,
                interval: result.interval,
                nextReviewDate: result.nextReviewDate,
                lastReviewedDate: result.lastReviewedDate,
                firstLearnedDate: result.firstLearnedDate,
                type: result.type
            )
            try await storage.saveStudyState(updated)
            
            let loaded = try await storage.getStudyState(wordId: 1001)
            expectNotNil(loaded)
            expectEqual(loaded?.repetitionCount, 3)
            expectApproxEqual(loaded?.stability ?? 0, result.stability, accuracy: 0.0001)
            expectApproxEqual(loaded?.difficulty ?? 0, result.difficulty, accuracy: 0.0001)
            expectEqual(loaded?.interval, result.interval)
            expectEqual(loaded?.nextReviewDate, result.nextReviewDate)
        })
    }
    
    // MARK: - 场景 2: 词库抽样到切片打包集成
    private static func registerScene2() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_02", name: "INT_02_词库抽样到四级切片与三明治组包", tier: "Tier3") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            // 构造已学与待复习数据
            // p0State: elapsed=12, stability=10.0 -> R ~ 0.887 (P0 临界急救)
            let p0State = WordStudyState(wordId: 1, repetitionCount: 2, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 88, firstLearnedDate: 50, type: 2)
            // p1State: elapsed=90, stability=1.0 -> R ~ 0.50 (P1 深度逾期, R < 0.6)
            let p1State = WordStudyState(wordId: 2, repetitionCount: 2, stability: 1.0, difficulty: 5.0, interval: 1, nextReviewDate: 11, lastReviewedDate: 10, firstLearnedDate: 0, type: 2)
            
            let reviewSliced = LearningSessionPolicy.sliceReviewCards(states: [p0State, p1State], today: 100)
            let reviewIds = Set(reviewSliced.map { $0.state.wordId })
            let reviewWordMap = try await dictStorage.getWords(by: reviewIds)
            
            let newWords = try await dictStorage.sampleNewWords(count: 5, excludingLearnedIds: [1, 2], level: "N1")
            
            let p0Words = reviewSliced.filter { $0.priority == .p0Emergency }.compactMap { reviewWordMap[$0.state.wordId] }
            let otherRevWords = reviewSliced.filter { $0.priority != .p0Emergency }.compactMap { reviewWordMap[$0.state.wordId] }
            
            let finalQueue = LearningSessionPolicy.sandwichMix(p0Cards: p0Words, reviewCards: otherRevWords, newCards: newWords)
            
            expectEqual(finalQueue.count, 7, "P0(1) + P1(1) + New(5) 组合总数为 7")
            expectEqual(finalQueue.first?.id, 1, "队列第一张卡必须是 P0 抢救词")
        })
    }
    
    // MARK: - 场景 3: 会话作答到打卡天数联动集成
    private static func registerScene3() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_03", name: "INT_03_会话作答完成触发打卡与Streak联动", tier: "Tier3") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            // 昨日打卡
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 99)
            let yesterdayStreak = await storage.calculateCurrentStreak(today: 99)
            expectEqual(yesterdayStreak, 1)
            
            // 今日学习并完成
            try await storage.recordDailyStudy(learnedIncrement: 15, reviewedIncrement: 10, date: 100)
            let todayStreak = await storage.calculateCurrentStreak(today: 100)
            expectEqual(todayStreak, 2, "今日打卡后连续天数应累加为 2")
            
            let todayRec = await storage.getTodayRecord(today: 100)
            expectEqual(todayRec?.learnedCount, 15)
            expectEqual(todayRec?.reviewedCount, 10)
        })
    }
    
    // MARK: - 场景 4: 错题重学队列与状态机生命周期集成
    private static func registerScene4() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_04", name: "INT_04_错题重学队列生命周期转换闭环", tier: "Tier3") {
            let calc = SrsCalculatorImpl()
            var state = WordStudyState(wordId: 301, repetitionCount: 3, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 90, firstLearnedDate: 50, type: 2)
            
            // 1. 复习时答错 (Again, quality = 1)
            let failResult = calc.calculate(item: state, quality: 1, today: 100)
            expectEqual(failResult.type, 3, "复习卡答错后应进入 Relearning (3)")
            state = WordStudyState(wordId: 301, repetitionCount: failResult.repetitionCount, stability: failResult.stability, difficulty: failResult.difficulty, interval: failResult.interval, nextReviewDate: failResult.nextReviewDate, lastReviewedDate: failResult.lastReviewedDate, firstLearnedDate: failResult.firstLearnedDate, type: failResult.type)
            
            // 2. 尾部重学时答对 (Good, quality = 4)
            let successResult = calc.calculate(item: state, quality: 4, today: 100)
            expectEqual(successResult.type, 2, "重学卡通过后重新转为 Review (2)")
            expectTrue(successResult.interval > 0)
        })
    }
    
    // MARK: - 场景 5: 预测间隔与实际作答结果严格一致性集成
    private static func registerScene5() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_05", name: "INT_05_预测间隔预览与实际作答天数完全匹配", tier: "Tier3") {
            let calc = SrsCalculatorImpl()
            let item = WordStudyState(wordId: 501, repetitionCount: 2, stability: 4.0, difficulty: 5.0, interval: 4, nextReviewDate: 100, lastReviewedDate: 96, firstLearnedDate: 80, type: 2)
            
            let previews = calc.predictNextIntervals(item: item, today: 100)
            let goodActual = calc.calculate(item: item, quality: 4, today: 100)
            
            let expectedGoodStr = (goodActual.interval <= 1) ? "1d" : "\(goodActual.interval)d"
            expectEqual(previews[.good], expectedGoodStr, "预测的好评间隔应与实际计算的 interval 天数字符串完全匹配")
        })
    }
    
    // MARK: - 场景 6: 多 JLPT 等级动态抽样与隔离持久化集成
    private static func registerScene6() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_06", name: "INT_06_不同等级抽样与持久化互不干扰", tier: "Tier3") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let learningStorage = MockLearningLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            // 抽取 N5 并学习
            let n5Words = try await dictStorage.sampleNewWords(count: 10, excludingLearnedIds: [], level: "N5")
            for w in n5Words {
                try await learningStorage.saveStudyState(WordStudyState(wordId: w.id, repetitionCount: 1, stability: 2.0, difficulty: 5.0, interval: 2, nextReviewDate: 102, lastReviewedDate: 100, firstLearnedDate: 100, type: 2))
            }
            
            let allStates = try await learningStorage.getAllStudyStates()
            let learnedIds = Set(allStates.keys)
            
            // 抽取 N1
            let n1Words = try await dictStorage.sampleNewWords(count: 10, excludingLearnedIds: learnedIds, level: "N1")
            expectEqual(n1Words.count, 10)
            for w in n1Words {
                expectEqual(w.level, "N1")
                expectFalse(learnedIds.contains(w.id), "新抽取的 N1 词条不能与之前已学的 N5 冲突")
            }
        })
    }
    
    // MARK: - 场景 7: 长期逾期卡片抽样与 P0 优先级抢救集成
    private static func registerScene7() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_07", name: "INT_07_逾期切片P0临界急救卡优先排序", tier: "Tier3") {
            var states: [WordStudyState] = []
            // 构造 5 张 P0 (0.6 <= R < 0.9) 与 5 张 P2 (R >= 0.9)
            for i in 1...5 {
                // P0
                states.append(WordStudyState(wordId: i, repetitionCount: 2, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 88, firstLearnedDate: 50, type: 2))
                // P2
                states.append(WordStudyState(wordId: i + 10, repetitionCount: 2, stability: 50.0, difficulty: 3.0, interval: 50, nextReviewDate: 100, lastReviewedDate: 98, firstLearnedDate: 50, type: 2))
            }
            
            let sliced = LearningSessionPolicy.sliceReviewCards(states: states, today: 100)
            let p0Count = sliced.filter { $0.priority == .p0Emergency }.count
            expectEqual(p0Count, 5)
            // 前 5 张必须全是 P0
            for i in 0..<5 {
                expectEqual(sliced[i].priority, .p0Emergency)
            }
        })
    }
    
    // MARK: - 场景 8: 会话取消与重新加载
    private static func registerScene8() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_08", name: "INT_08_半途退出新会话精准排除已学词", tier: "Tier3") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let learningStorage = MockLearningLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            let planned = try await dictStorage.sampleNewWords(count: 10, excludingLearnedIds: [])
            // 答了前 3 词
            for w in planned.prefix(3) {
                try await learningStorage.saveStudyState(WordStudyState(wordId: w.id, repetitionCount: 1))
            }
            
            // 模拟意外退出后新开会话
            let learned = Set((try await learningStorage.getAllStudyStates()).keys)
            let newBatch = try await dictStorage.sampleNewWords(count: 10, excludingLearnedIds: learned)
            
            for w in planned.prefix(3) {
                expectFalse(newBatch.contains { $0.id == w.id }, "已持久化的前3词不得出现在新抽样批次中")
            }
        })
    }
    
    // MARK: - 场景 9: 批量持久化原子性与并发竞争写入集成
    private static func registerScene9() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_09", name: "INT_09_高并发批量写入持久化无撕裂", tier: "Tier3") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            await withTaskGroup(of: Void.self) { group in
                for i in 1...30 {
                    group.addTask {
                        let state = WordStudyState(wordId: i, repetitionCount: 1, stability: Double(i), difficulty: 5.0, interval: i, nextReviewDate: 100 + i, lastReviewedDate: 100, firstLearnedDate: 100, type: 2)
                        try? await storage.saveStudyState(state)
                    }
                }
            }
            let all = try await storage.getAllStudyStates()
            expectEqual(all.count, 30, "30个并发写入必须全部成功留存")
        })
    }
    
    // MARK: - 场景 10: 真实规模 9,876 词库全流程数据流转压测
    private static func registerScene10() {
        TestRegistry.shared.register(TestCase(id: "T3_INT_10", name: "INT_10_全量9876词库全生命周期数据流转秒级压测", tier: "Tier3") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let learningStorage = MockLearningLocalStorage(sandbox: sandbox)
            let calc = SrsCalculatorImpl()
            
            let startTime = Date()
            
            // 1. 初始化 9876 词库
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            let preloaded = try await dictStorage.preloadWordsIfNeeded()
            expectEqual(preloaded.count, 9876)
            
            // 2. 模拟用户已学 100 词
            var initialStates: [WordStudyState] = []
            for i in 1...100 {
                initialStates.append(WordStudyState(wordId: i, repetitionCount: 2, stability: 5.0, difficulty: 5.0, interval: 5, nextReviewDate: 100, lastReviewedDate: 95, firstLearnedDate: 90, type: 2))
            }
            try await learningStorage.saveStudyStates(initialStates)
            
            // 3. 动态切片与抽样
            let allStates = try await learningStorage.getAllStudyStates()
            let learnedIds = Set(allStates.keys)
            let reviewSliced = LearningSessionPolicy.sliceReviewCards(states: Array(allStates.values), today: 100)
            let newWords = try await dictStorage.sampleNewWords(count: 15, excludingLearnedIds: learnedIds)
            expectEqual(newWords.count, 15)
            
            // 4. 模拟会话作答 30 次
            var updatedStates: [WordStudyState] = []
            for w in newWords {
                let res = calc.calculate(item: WordStudyState(wordId: w.id), quality: 4, today: 100)
                updatedStates.append(WordStudyState(wordId: w.id, repetitionCount: res.repetitionCount, stability: res.stability, difficulty: res.difficulty, interval: res.interval, nextReviewDate: res.nextReviewDate, lastReviewedDate: res.lastReviewedDate, firstLearnedDate: res.firstLearnedDate, type: res.type))
            }
            try await learningStorage.saveStudyStates(updatedStates)
            try await learningStorage.recordDailyStudy(learnedIncrement: 15, reviewedIncrement: reviewSliced.count, date: 100)
            
            let streak = await learningStorage.calculateCurrentStreak(today: 100)
            expectEqual(streak, 1)
            
            let elapsed = Date().timeIntervalSince(startTime)
            expectTrue(elapsed < 2.0, "9876全量流转应在 2 秒内极速完成，当前耗时: \(elapsed)s")
        })
    }
}
