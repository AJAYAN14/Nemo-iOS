import Foundation

public struct Tier4_RealWorldScenarios {
    public static func registerAll() {
        registerS1_NewUserOnboarding()
        registerS2_OverdueRescue()
        registerS3_RelearnAndClear()
        registerS4_AppCrashRecovery()
        registerS5_MultiDayStreakEvolution()
    }
    
    // MARK: - S1: 新用户首日破冰学习会话
    private static func registerS1_NewUserOnboarding() {
        TestRegistry.shared.register(TestCase(id: "T4_S1_01", name: "S1_真实场景_新用户首日破冰学习会话", tier: "Tier4") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let learningStorage = MockLearningLocalStorage(sandbox: sandbox)
            let calc = SrsCalculatorImpl()
            let clock = MockClock(initialEpochDay: 100)
            
            // 1. 初始化 9,876 真实词库
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            // 2. 验证新用户初始状态
            let initialStreak = await learningStorage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(initialStreak, 0, "全新用户打卡天数必须为 0")
            let initialStates = try await learningStorage.getAllStudyStates()
            expectTrue(initialStates.isEmpty, "新用户初始已学卡片必须为空")
            
            // 3. 策略判定：无待复习卡片，按配额抽取 15 词新卡
            let reviewSliced = LearningSessionPolicy.sliceReviewCards(states: Array(initialStates.values), today: clock.currentEpochDay)
            expectTrue(reviewSliced.isEmpty, "新用户无待复习卡")
            
            let newWords = try await dictStorage.sampleNewWords(count: 15, excludingLearnedIds: [])
            expectEqual(newWords.count, 15, "必须成功抽取 15 张新卡")
            
            // 4. 用户开始会话作答：全部完成评分（Good / Easy 混评）
            var sessionStates: [WordStudyState] = []
            for (idx, word) in newWords.enumerated() {
                let quality = (idx % 2 == 0) ? 4 : 5 // Good or Easy
                let update = calc.calculate(item: WordStudyState(wordId: word.id), quality: quality, today: clock.currentEpochDay, itemId: word.id)
                let state = WordStudyState(
                    wordId: word.id,
                    repetitionCount: update.repetitionCount,
                    stability: update.stability,
                    difficulty: update.difficulty,
                    interval: update.interval,
                    nextReviewDate: update.nextReviewDate,
                    lastReviewedDate: update.lastReviewedDate,
                    firstLearnedDate: update.firstLearnedDate,
                    type: update.type
                )
                sessionStates.append(state)
            }
            
            // 5. 写入持久化并记录今日打卡
            try await learningStorage.saveStudyStates(sessionStates)
            try await learningStorage.recordDailyStudy(learnedIncrement: sessionStates.count, reviewedIncrement: 0, date: clock.currentEpochDay)
            
            // 6. 验证结算战报与打卡天数
            let updatedStreak = await learningStorage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(updatedStreak, 1, "首日学习完成打卡天数必须变为 1")
            
            let todayRecord = await learningStorage.getTodayRecord(today: clock.currentEpochDay)
            expectEqual(todayRecord?.learnedCount, 15)
            expectEqual(todayRecord?.reviewedCount, 0)
            expectEqual(todayRecord?.totalCount, 15)
            
            let finalStates = try await learningStorage.getAllStudyStates()
            expectEqual(finalStates.count, 15, "已学卡片必须准确持久化 15 张")
        })
    }
    
    // MARK: - S2: 长期用户多日逾期深度拯救
    private static func registerS2_OverdueRescue() {
        TestRegistry.shared.register(TestCase(id: "T4_S2_01", name: "S2_真实场景_长期用户多日逾期深度拯救", tier: "Tier4") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let learningStorage = MockLearningLocalStorage(sandbox: sandbox)
            let calc = SrsCalculatorImpl()
            let clock = MockClock(initialEpochDay: 150) // 今日为第 150 天
            
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            // 1. 模拟用户积压 120 张逾期卡片
            // 20 张 P0 临界抢救卡 (0.6 <= R < 0.9)
            // 50 张 P1 深度逾期卡 (R < 0.6)
            // 50 张 P2 常规到期卡 (R >= 0.9)
            var backlog: [WordStudyState] = []
            // P0
            for i in 1...20 {
                backlog.append(WordStudyState(wordId: i, repetitionCount: 2, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 150, lastReviewedDate: 138, firstLearnedDate: 100, type: 2))
            }
            // P1
            for i in 21...70 {
                backlog.append(WordStudyState(wordId: i, repetitionCount: 1, stability: 3.0, difficulty: 6.0, interval: 3, nextReviewDate: 100, lastReviewedDate: 90, firstLearnedDate: 80, type: 2))
            }
            // P2
            for i in 71...120 {
                backlog.append(WordStudyState(wordId: i, repetitionCount: 5, stability: 80.0, difficulty: 3.0, interval: 80, nextReviewDate: 150, lastReviewedDate: 148, firstLearnedDate: 50, type: 2))
            }
            try await learningStorage.saveStudyStates(backlog)
            
            // 2. 策略切片与阻尼截断验证
            let sliced = LearningSessionPolicy.sliceReviewCards(states: backlog, today: clock.currentEpochDay)
            expectEqual(sliced.count, LearningSessionPolicy.maxReviewDamping, "多日积压逾期卡片必须被阻尼上限截取为 40 词")
            
            // 验证切片内部优先级排序：前 20 张必须为 P0
            for i in 0..<20 {
                expectEqual(sliced[i].priority, .p0Emergency, "第 \(i) 张卡必须属于 P0 临界急救级别")
            }
            
            // 3. 三明治混排：穿插 10 词新词
            let learnedIds = Set(backlog.map { $0.wordId })
            let newWords = try await dictStorage.sampleNewWords(count: 10, excludingLearnedIds: learnedIds)
            let p0Words = sliced.filter { $0.priority == .p0Emergency }.map { Word(id: $0.state.wordId, japanese: "p0_\($0.state.wordId)", hiragana: "", chinese: "", level: "N1") }
            let otherWords = sliced.filter { $0.priority != .p0Emergency }.map { Word(id: $0.state.wordId, japanese: "other_\($0.state.wordId)", hiragana: "", chinese: "", level: "N1") }
            
            let sessionQueue = LearningSessionPolicy.sandwichMix(p0Cards: p0Words, reviewCards: otherWords, newCards: newWords)
            expectEqual(sessionQueue.count, 50, "40 复习词 + 10 新词总数为 50")
            expectEqual(sessionQueue.first?.id, p0Words.first?.id, "队首必须是危急程度最高的 P0 卡片")
            
            // 4. 用户完成复习作答并写回
            var updatedStates: [WordStudyState] = []
            for item in sliced {
                let update = calc.calculate(item: item.state, quality: 4, today: clock.currentEpochDay, itemId: item.state.wordId)
                let newState = WordStudyState(wordId: item.state.wordId, repetitionCount: update.repetitionCount, stability: update.stability, difficulty: update.difficulty, interval: update.interval, nextReviewDate: update.nextReviewDate, lastReviewedDate: update.lastReviewedDate, firstLearnedDate: update.firstLearnedDate, type: update.type)
                updatedStates.append(newState)
            }
            try await learningStorage.saveStudyStates(updatedStates)
            try await learningStorage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 40, date: clock.currentEpochDay)
            
            let todayRecord = await learningStorage.getTodayRecord(today: clock.currentEpochDay)
            expectEqual(todayRecord?.totalCount, 50)
        })
    }
    
    // MARK: - S3: 会话中反复遗忘与尾部出清
    private static func registerS3_RelearnAndClear() {
        TestRegistry.shared.register(TestCase(id: "T4_S3_01", name: "S3_真实场景_会话中反复遗忘与尾部重学出清", tier: "Tier4") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let learningStorage = MockLearningLocalStorage(sandbox: sandbox)
            let calc = SrsCalculatorImpl()
            let clock = MockClock(initialEpochDay: 100)
            
            // 初始待复习卡 A (id: 10) 与 B (id: 20)
            let cardA = WordStudyState(wordId: 10, repetitionCount: 3, stability: 15.0, difficulty: 5.0, interval: 15, nextReviewDate: 100, lastReviewedDate: 85, firstLearnedDate: 50, type: 2)
            let cardB = WordStudyState(wordId: 20, repetitionCount: 3, stability: 15.0, difficulty: 5.0, interval: 15, nextReviewDate: 100, lastReviewedDate: 85, firstLearnedDate: 50, type: 2)
            try await learningStorage.saveStudyStates([cardA, cardB])
            
            var workingQueue = [cardA, cardB]
            var relearnRoundsForA = 0
            var completedCount = 0
            
            // 模拟会话状态机运行
            while !workingQueue.isEmpty {
                let current = workingQueue.removeFirst()
                if current.wordId == 10 && relearnRoundsForA < 2 {
                    // 卡片 A 前两次均答错 Again
                    relearnRoundsForA += 1
                    let update = calc.calculate(item: current, quality: 1, today: clock.currentEpochDay, itemId: current.wordId)
                    let newState = WordStudyState(wordId: current.wordId, repetitionCount: update.repetitionCount, stability: update.stability, difficulty: update.difficulty, interval: update.interval, nextReviewDate: update.nextReviewDate, lastReviewedDate: update.lastReviewedDate, firstLearnedDate: update.firstLearnedDate, type: update.type)
                    expectEqual(newState.type, 3, "答错必须标记为 Relearning 状态")
                    // 追加到尾部
                    workingQueue.append(newState)
                } else {
                    // 卡片 B 或 卡片 A 第三次答对 Good
                    let update = calc.calculate(item: current, quality: 4, today: clock.currentEpochDay, itemId: current.wordId)
                    let newState = WordStudyState(wordId: current.wordId, repetitionCount: update.repetitionCount, stability: update.stability, difficulty: update.difficulty, interval: update.interval, nextReviewDate: update.nextReviewDate, lastReviewedDate: update.lastReviewedDate, firstLearnedDate: update.firstLearnedDate, type: update.type)
                    try await learningStorage.saveStudyState(newState)
                    completedCount += 1
                }
            }
            
            expectEqual(relearnRoundsForA, 2, "卡片 A 经历了 2 次 Again 重学循环")
            expectEqual(completedCount, 2, "全部卡片最终出清完成")
            expectTrue(workingQueue.isEmpty, "队列必须完全出清才推进结算")
            
            let finalA = try await learningStorage.getStudyState(wordId: 10)
            expectEqual(finalA?.type, 2, "重学合格后重新归为 Review 状态")
        })
    }
    
    // MARK: - S4: 会话意外退出与冷启动完整恢复
    private static func registerS4_AppCrashRecovery() {
        TestRegistry.shared.register(TestCase(id: "T4_S4_01", name: "S4_真实场景_会话意外强退与冷启动完整恢复", tier: "Tier4") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let clock = MockClock(initialEpochDay: 100)
            let calc = SrsCalculatorImpl()
            
            // 第一阶段：进行中意外退出
            do {
                let storage = MockLearningLocalStorage(sandbox: sandbox)
                // 用户计划学习 10 词，学习到第 4 词时系统崩溃或强退
                for i in 1...4 {
                    let update = calc.calculate(item: WordStudyState(wordId: i), quality: 4, today: clock.currentEpochDay, itemId: i)
                    let state = WordStudyState(wordId: i, repetitionCount: update.repetitionCount, stability: update.stability, difficulty: update.difficulty, interval: update.interval, nextReviewDate: update.nextReviewDate, lastReviewedDate: update.lastReviewedDate, firstLearnedDate: update.firstLearnedDate, type: update.type)
                    try await storage.saveStudyState(state)
                }
                try await storage.recordDailyStudy(learnedIncrement: 4, reviewedIncrement: 0, date: clock.currentEpochDay)
            }
            
            // 第二阶段：应用冷启动拉起
            do {
                let newStorage = MockLearningLocalStorage(sandbox: sandbox)
                let allStates = try await newStorage.getAllStudyStates()
                expectEqual(allStates.count, 4, "已作答的 4 词必须完好无损地持久化")
                for i in 1...4 {
                    expectNotNil(allStates[i])
                    expectEqual(allStates[i]?.repetitionCount, 1)
                }
                
                let streak = await newStorage.calculateCurrentStreak(today: clock.currentEpochDay)
                expectEqual(streak, 1, "当日打卡进度依然保持有效")
                
                // 再次开启会话时，这 4 词被成功排重
                let learnedSet = Set(allStates.keys)
                let candidateIds = (1...10)
                let filtered = candidateIds.filter { !learnedSet.contains($0) }
                expectEqual(filtered, [5, 6, 7, 8, 9, 10], "新会话必须平滑衔接未学习单词")
            }
        })
    }
    
    // MARK: - S5: 跨天跨月连续打卡天数动态演进
    private static func registerS5_MultiDayStreakEvolution() {
        TestRegistry.shared.register(TestCase(id: "T4_S5_01", name: "S5_真实场景_跨天跨月连续打卡天数动态演进", tier: "Tier4") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            let clock = MockClock(initialEpochDay: 20000) // 起始天
            
            // Day 1: 学习打卡
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: clock.currentEpochDay)
            var streak = await storage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(streak, 1)
            
            // Day 2: 推进一天并打卡
            clock.advanceDays(1)
            try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 10, date: clock.currentEpochDay)
            streak = await storage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(streak, 2)
            
            // Day 3: 跳过未打卡 (停顿一天)
            clock.advanceDays(1)
            // 今日未打卡，处于宽限期
            streak = await storage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(streak, 2, "处于宽限期内应保持 2 天")
            
            // Day 4: 再次推进一天，前天昨天均断卡
            clock.advanceDays(1)
            streak = await storage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(streak, 0, "断卡超过一天后归零")
            
            // 重新在 Day 4 学习打卡
            try await storage.recordDailyStudy(learnedIncrement: 15, reviewedIncrement: 0, date: clock.currentEpochDay)
            streak = await storage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(streak, 1, "重新打卡后 Streak 从 1 重新起算")
            
            // 持续连续打卡 5 天 (模拟跨月)
            for _ in 1...5 {
                clock.advanceDays(1)
                try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 5, date: clock.currentEpochDay)
            }
            streak = await storage.calculateCurrentStreak(today: clock.currentEpochDay)
            expectEqual(streak, 6, "连续打卡 5 天后 Streak 必须累加至 6")
        })
    }
}
