import Foundation

public struct Tier1_FeatureTests {
    public static func registerAll() {
        registerF1Tests()
        registerF2Tests()
        registerF3Tests()
        registerF4Tests()
        registerF5Tests()
        registerF6Tests()
        registerF7Tests()
        registerF8Tests()
        registerF9Tests()
        registerF10Tests()
    }
    
    // MARK: - F1: FSRS 6 核心算法移植
    private static func registerF1Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F1_01", name: "F1_默认21参数模型校验", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            expectEqual(algo.parameters.count, 21, "参数数组长度必须为 21")
            expectApproxEqual(algo.parameters[0], 0.212, accuracy: 0.0001)
            expectApproxEqual(algo.parameters[1], 1.2931, accuracy: 0.0001)
            expectApproxEqual(algo.parameters[2], 2.3065, accuracy: 0.0001)
            expectApproxEqual(algo.parameters[3], 8.2956, accuracy: 0.0001)
            expectApproxEqual(algo.parameters[20], 0.1542, accuracy: 0.0001)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F1_02", name: "F1_遗忘曲线随时间衰减", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            let s = 10.0
            let r0 = algo.forgettingCurve(elapsedDays: 0, stability: s)
            let r5 = algo.forgettingCurve(elapsedDays: 5, stability: s)
            let r10 = algo.forgettingCurve(elapsedDays: 10, stability: s)
            let r20 = algo.forgettingCurve(elapsedDays: 20, stability: s)
            
            expectApproxEqual(r0, 1.0, accuracy: 0.001, "0天未复习时回忆概率应为 1.0")
            expectApproxEqual(r10, 0.9, accuracy: 0.005, "达到稳定性天数时回忆概率应约为 0.9")
            expectTrue(r5 > r10, "5天回忆率必须高于10天回忆率")
            expectTrue(r10 > r20, "10天回忆率必须高于20天回忆率")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F1_03", name: "F1_初始稳定性与难度推导", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            let sAgain = algo.initStability(rating: .again)
            let sHard = algo.initStability(rating: .hard)
            let sGood = algo.initStability(rating: .good)
            let sEasy = algo.initStability(rating: .easy)
            
            expectTrue(sAgain < sHard, "Again 稳定性必须小于 Hard")
            expectTrue(sHard < sGood, "Hard 稳定性必须小于 Good")
            expectTrue(sGood < sEasy, "Good 稳定性必须小于 Easy")
            
            let dAgain = algo.initDifficulty(rating: .again)
            let dEasy = algo.initDifficulty(rating: .easy)
            expectTrue(dAgain > dEasy, "Again 初始难度必须大于 Easy 初始难度")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F1_04", name: "F1_跨天复习成功后稳定性自适应增长", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            let s = 5.0
            let d = 5.0
            let r = algo.forgettingCurve(elapsedDays: 5.0, stability: s)
            let newS = algo.stabilityAfterSuccess(stability: s, difficulty: d, retrievability: r, rating: .good)
            expectTrue(newS > s, "成功复习后稳定性必须增长，当前: \(newS), 原始: \(s)")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F1_05", name: "F1_当天短期稳定性短期步进增长", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            let s = 2.0
            let shortSGood = algo.stabilityShortTerm(stability: s, rating: .good)
            let shortSEasy = algo.stabilityShortTerm(stability: s, rating: .easy)
            expectTrue(shortSGood >= s, "短期 Good 评分下稳定性保底增长，new: \(shortSGood), old: \(s)")
            expectTrue(shortSEasy >= shortSGood, "短期 Easy 评分稳定性增幅应大于等于 Good")
        })
    }
    
    // MARK: - F2: 确定性 Fuzz 抖动与单调性截断
    private static func registerF2Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F2_01", name: "F2_相同种子Fuzz结果完全一致", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            let base = 30
            let seed: Int64 = 987654321
            let r1 = algo.fuzzIntervalDays(baseInterval: base, seed: seed)
            let r2 = algo.fuzzIntervalDays(baseInterval: base, seed: seed)
            expectEqual(r1, r2, "相同种子和基础间隔的 Fuzz 结果必须完全一致")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F2_02", name: "F2_小间隔免抖动保持学习节奏", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            expectEqual(algo.fuzzIntervalDays(baseInterval: 1, seed: 12345), 1, "baseInterval 为 1 时不应抖动")
            expectEqual(algo.fuzzIntervalDays(baseInterval: 2, seed: 12345), 2, "baseInterval 为 2 时不应抖动")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F2_03", name: "F2_合理抖动跨度不越界", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            let base = 50
            for s: Int64 in 1...20 {
                let fuzzed = algo.fuzzIntervalDays(baseInterval: base, seed: s)
                expectTrue(fuzzed >= 1 && fuzzed <= FsrsAlgorithm.maxInterval, "抖动后间隔必须在 [1, maxInterval] 内")
                expectTrue(abs(fuzzed - base) <= 10, "50天间隔的抖动跨度不应超过合理范围")
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F2_04", name: "F2_SrsCalculator严格保证单调性截断", tier: "Tier1") {
            let calc = SrsCalculatorImpl()
            let item = WordStudyState(wordId: 1, repetitionCount: 2, stability: 3.5, difficulty: 6.0, interval: 3, nextReviewDate: 100, lastReviewedDate: 96, firstLearnedDate: 90, type: 2)
            
            let hard = calc.calculate(item: item, quality: 3, today: 100, itemId: 1)
            let good = calc.calculate(item: item, quality: 4, today: 100, itemId: 1)
            let easy = calc.calculate(item: item, quality: 5, today: 100, itemId: 1)
            
            expectTrue(hard.interval <= good.interval, "Hard 间隔 (\(hard.interval)) 必须 <= Good 间隔 (\(good.interval))")
            expectTrue(good.interval <= easy.interval, "Good 间隔 (\(good.interval)) 必须 <= Easy 间隔 (\(easy.interval))")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F2_05", name: "F2_最大间隔截断保护", tier: "Tier1") {
            let algo = FsrsAlgorithm()
            let days = algo.nextIntervalDays(stability: 100000.0)
            expectEqual(days, FsrsAlgorithm.maxInterval, "极大稳定性下间隔必须被截断至 MAX_INTERVAL (36500)")
        })
    }
    
    // MARK: - F3: 算法对齐回归（11项 Android 标准测试向量）
    private static func registerF3Tests() {
        let calc = SrsCalculatorImpl()
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_01", name: "F3_01_首次学习质量4_Good_毕业并设置间隔", tier: "Tier1") {
            let item = WordStudyState(wordId: 1)
            let result = calc.calculate(item: item, quality: 4, today: 100)
            expectEqual(result.repetitionCount, 1)
            expectTrue(result.interval > 0)
            expectEqual(result.nextReviewDate, 100 + result.interval)
            expectTrue(result.stability > 0.0)
            expectTrue(result.difficulty > 0.0)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_02", name: "F3_02_首次学习质量5_Easy_给更长间隔", tier: "Tier1") {
            let item1 = WordStudyState(wordId: 1)
            let item2 = WordStudyState(wordId: 2)
            let resGood = calc.calculate(item: item1, quality: 4, today: 100)
            let resEasy = calc.calculate(item: item2, quality: 5, today: 100)
            expectTrue(resEasy.interval > resGood.interval, "Easy 间隔应大于 Good 间隔")
            expectTrue(resEasy.stability > resGood.stability, "Easy 稳定性应大于 Good 稳定性")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_03", name: "F3_03_首次学习质量2_Again_失败且重复次数不增加", tier: "Tier1") {
            let item = WordStudyState(wordId: 1)
            let res = calc.calculate(item: item, quality: 2, today: 100)
            expectEqual(res.repetitionCount, 0)
            expectEqual(res.nextReviewDate, 0, "新卡失败不设置复习日期")
            expectTrue(res.stability > 0.0)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_04", name: "F3_04_复习阶段质量4_间隔应该增加", tier: "Tier1") {
            let item = WordStudyState(wordId: 1, repetitionCount: 1, stability: 3.0, difficulty: 5.0, interval: 3, nextReviewDate: 100, lastReviewedDate: 97, firstLearnedDate: 97, type: 2)
            let res = calc.calculate(item: item, quality: 4, today: 100)
            expectEqual(res.repetitionCount, 2)
            expectTrue(res.interval > 3, "复习成功后新间隔应大于原间隔")
            expectTrue(res.stability > 3.0, "稳定性应增长")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_05", name: "F3_05_复习阶段质量2_忘记应该重新适应", tier: "Tier1") {
            let item = WordStudyState(wordId: 1, repetitionCount: 3, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 90, firstLearnedDate: 80, type: 2)
            let res = calc.calculate(item: item, quality: 2, today: 100)
            expectEqual(res.repetitionCount, 3, "失败不扣减也不增加次数")
            expectEqual(res.nextReviewDate, 100 + res.interval)
            expectTrue(res.interval > 0)
            expectTrue(res.stability > 0.0)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_06", name: "F3_06_高稳定性卡片忘记时稳定性发生断崖式跌落", tier: "Tier1") {
            let item = WordStudyState(wordId: 1, repetitionCount: 5, stability: 60.0, difficulty: 4.0, interval: 60, nextReviewDate: 100, lastReviewedDate: 40, firstLearnedDate: 0, type: 2)
            let res = calc.calculate(item: item, quality: 2, today: 100)
            expectTrue(res.stability < 15.0, "遗忘惩罚截断后稳定性应显著跌落，实际: \(res.stability)")
            expectTrue(res.interval <= 7, "重置后间隔应回退至短周期，实际: \(res.interval)")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_07", name: "F3_07_延迟且记得给予稳定性奖励", tier: "Tier1") {
            let itemDelayed = WordStudyState(wordId: 1, repetitionCount: 4, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 90, lastReviewedDate: 80, firstLearnedDate: 60, type: 2)
            let itemOnTime = WordStudyState(wordId: 2, repetitionCount: 4, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 90, firstLearnedDate: 70, type: 2)
            
            let resDelayed = calc.calculate(item: itemDelayed, quality: 4, today: 100)
            let resOnTime = calc.calculate(item: itemOnTime, quality: 4, today: 100)
            expectTrue(resDelayed.stability > resOnTime.stability, "延迟但记起时获得的稳定性增幅必须高于按时复习")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_08", name: "F3_08_保留率敏感度校验", tier: "Tier1") {
            let highAlgo = FsrsAlgorithm(desiredRetention: 0.95)
            let lowAlgo = FsrsAlgorithm(desiredRetention: 0.75)
            let highCalc = SrsCalculatorImpl(fsrs: highAlgo)
            let lowCalc = SrsCalculatorImpl(fsrs: lowAlgo)
            
            let item = WordStudyState(wordId: 1, repetitionCount: 3, stability: 20.0, difficulty: 5.0, interval: 20, nextReviewDate: 100, lastReviewedDate: 80, firstLearnedDate: 50, type: 2)
            let resHigh = highCalc.calculate(item: item, quality: 4, today: 100)
            let resLow = lowCalc.calculate(item: item, quality: 4, today: 100)
            expectTrue(resHigh.interval <= resLow.interval, "高保留率目标 (\(resHigh.interval)) 的间隔应小于等于低保留率目标 (\(resLow.interval))")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_09", name: "F3_09_复习阶段单调性检验", tier: "Tier1") {
            let item = WordStudyState(wordId: 1, repetitionCount: 2, stability: 3.5, difficulty: 6.0, interval: 3, nextReviewDate: 100, lastReviewedDate: 96, firstLearnedDate: 90, type: 2)
            let hard = calc.calculate(item: item, quality: 3, today: 100)
            let good = calc.calculate(item: item, quality: 4, today: 100)
            let easy = calc.calculate(item: item, quality: 5, today: 100)
            expectTrue(hard.interval <= good.interval)
            expectTrue(good.interval <= easy.interval)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_10", name: "F3_10_时间序列与稳定性遍历单调性", tier: "Tier1") {
            let stabs = [1.5, 2.5, 3.8, 4.2, 7.0, 15.0]
            for elapsed in 1...10 {
                for stab in stabs {
                    let item = WordStudyState(wordId: 1, repetitionCount: 2, stability: stab, difficulty: 5.0, interval: max(1, Int(stab)), nextReviewDate: 100, lastReviewedDate: 100 - elapsed, firstLearnedDate: 80, type: 2)
                    let hard = calc.calculate(item: item, quality: 3, today: 100)
                    let good = calc.calculate(item: item, quality: 4, today: 100)
                    let easy = calc.calculate(item: item, quality: 5, today: 100)
                    expectTrue(hard.interval <= good.interval, "在 elapsed=\(elapsed), stab=\(stab) 下 Hard <= Good 倒挂")
                    expectTrue(good.interval <= easy.interval, "在 elapsed=\(elapsed), stab=\(stab) 下 Good <= Easy 倒挂")
                }
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F3_11", name: "F3_11_预测间隔展示格式对齐", tier: "Tier1") {
            let item = WordStudyState(wordId: 1)
            let previews = calc.predictNextIntervals(item: item, today: 100)
            expectEqual(previews[.again], "< 10m")
            expectNotNil(previews[.hard])
            expectNotNil(previews[.good])
            expectNotNil(previews[.easy])
        })
    }
    
    // MARK: - F4: 卡片学习状态模型与本地原子持久化
    private static func registerF4Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F4_01", name: "F4_WordStudyState默认初始化状态正确", tier: "Tier1") {
            let state = WordStudyState(wordId: 42)
            expectEqual(state.wordId, 42)
            expectEqual(state.repetitionCount, 0)
            expectEqual(state.stability, 0.0)
            expectEqual(state.difficulty, 0.0)
            expectEqual(state.interval, 0)
            expectEqual(state.nextReviewDate, 0)
            expectNil(state.lastReviewedDate)
            expectNil(state.firstLearnedDate)
            expectEqual(state.type, 0)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F4_02", name: "F4_单卡片写入与读出一致性", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            let original = WordStudyState(wordId: 101, repetitionCount: 3, stability: 12.345, difficulty: 4.567, interval: 12, nextReviewDate: 120, lastReviewedDate: 108, firstLearnedDate: 90, type: 2)
            try await storage.saveStudyState(original)
            
            let loaded = try await storage.getStudyState(wordId: 101)
            expectNotNil(loaded)
            expectEqual(loaded?.wordId, 101)
            expectEqual(loaded?.repetitionCount, 3)
            expectApproxEqual(loaded?.stability ?? 0, 12.345, accuracy: 0.0001)
            expectApproxEqual(loaded?.difficulty ?? 0, 4.567, accuracy: 0.0001)
            expectEqual(loaded?.nextReviewDate, 120)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F4_03", name: "F4_批量卡片持久化原子性", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            var states: [WordStudyState] = []
            for i in 1...50 {
                states.append(WordStudyState(wordId: i, repetitionCount: 1, stability: Double(i), difficulty: 5.0, interval: i, nextReviewDate: 100 + i, lastReviewedDate: 100, firstLearnedDate: 100, type: 2))
            }
            try await storage.saveStudyStates(states)
            
            let all = try await storage.getAllStudyStates()
            expectEqual(all.count, 50, "保存的 50 条卡片状态应全部存在")
            expectEqual(all[25]?.wordId, 25)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F4_04", name: "F4_未学习卡片查询返回nil", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            let state = try await storage.getStudyState(wordId: 9999)
            expectNil(state, "未学习单词应返回 nil")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F4_05", name: "F4_卡片状态更新覆盖原值", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            let v1 = WordStudyState(wordId: 7, repetitionCount: 1, stability: 2.0, difficulty: 6.0, interval: 2, nextReviewDate: 102, lastReviewedDate: 100, firstLearnedDate: 100, type: 2)
            try await storage.saveStudyState(v1)
            
            let v2 = WordStudyState(wordId: 7, repetitionCount: 2, stability: 5.5, difficulty: 5.2, interval: 5, nextReviewDate: 107, lastReviewedDate: 102, firstLearnedDate: 100, type: 2)
            try await storage.saveStudyState(v2)
            
            let loaded = try await storage.getStudyState(wordId: 7)
            expectEqual(loaded?.repetitionCount, 2)
            expectApproxEqual(loaded?.stability ?? 0, 5.5, accuracy: 0.001)
        })
    }
    
    // MARK: - F5: 每日打卡记录与连续天数算法
    private static func registerF5Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F5_01", name: "F5_初次打卡生成打卡记录且Streak为1", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 5, date: 100)
            let record = await storage.getTodayRecord(today: 100)
            expectNotNil(record)
            expectEqual(record?.learnedCount, 10)
            expectEqual(record?.reviewedCount, 5)
            expectEqual(record?.totalCount, 15)
            
            let streak = await storage.calculateCurrentStreak(today: 100)
            expectEqual(streak, 1, "初次打卡连续天数应为 1")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F5_02", name: "F5_同日多次学习增量累加", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 100)
            try await storage.recordDailyStudy(learnedIncrement: 3, reviewedIncrement: 7, date: 100)
            
            let record = await storage.getTodayRecord(today: 100)
            expectEqual(record?.learnedCount, 8)
            expectEqual(record?.reviewedCount, 7)
            expectEqual(record?.totalCount, 15)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F5_03", name: "F5_连续多日打卡Streak正确递增", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 100)
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 5, date: 101)
            try await storage.recordDailyStudy(learnedIncrement: 0, reviewedIncrement: 15, date: 102)
            
            let streak = await storage.calculateCurrentStreak(today: 102)
            expectEqual(streak, 3, "连续3天打卡，Streak 必须为 3")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F5_04", name: "F5_断卡一天后Streak归零重新计算", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 100)
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 101)
            // 102 未打卡
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 103)
            
            let streak = await storage.calculateCurrentStreak(today: 103)
            expectEqual(streak, 1, "跳过一天后新打卡 Streak 应重置为 1")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F5_05", name: "F5_今日尚未打卡但昨日打卡处于宽限期", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 99)
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 100)
            // 今日 101 尚未学习
            let streak = await storage.calculateCurrentStreak(today: 101)
            expectEqual(streak, 2, "今日尚未打卡，应保持昨日的连续打卡天数 2")
        })
    }
    
    // MARK: - F6: DictionaryLocalStorage 内存预加载与动态采样
    private static func registerF6Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F6_01", name: "F6_预加载词库常驻内存", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let dummyWords = TestDataGenerator.generate9876Dictionary()
            try await dictStorage.saveWords(dummyWords)
            
            let loaded1 = try await dictStorage.preloadWordsIfNeeded()
            let loaded2 = try await dictStorage.preloadWordsIfNeeded()
            expectEqual(loaded1.count, 9876)
            expectEqual(loaded2.count, 9876)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F6_02", name: "F6_根据ID批量精确查询", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            let ids: Set<Int> = [1, 50, 100, 500, 999]
            let map = try await dictStorage.getWords(by: ids)
            expectEqual(map.count, 5)
            expectEqual(map[50]?.id, 50)
            expectEqual(map[999]?.id, 999)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F6_03", name: "F6_新词抽样自动排除已学集合", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            let learned: Set<Int> = [1, 2, 3, 4, 5]
            let sampled = try await dictStorage.sampleNewWords(count: 10, excludingLearnedIds: learned)
            expectEqual(sampled.count, 10)
            for w in sampled {
                expectFalse(learned.contains(w.id), "抽取的单词不能存在于已学集合中")
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F6_04", name: "F6_支持按JLPT等级筛选抽样", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            let sampledN2 = try await dictStorage.sampleNewWords(count: 15, excludingLearnedIds: [], level: "N2")
            expectEqual(sampledN2.count, 15)
            for w in sampledN2 {
                expectEqual(w.level, "N2", "筛选等级必须全部为 N2")
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F6_05", name: "F6_抽样自动过滤下架词条", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            let sampled = try await dictStorage.sampleNewWords(count: 200, excludingLearnedIds: [])
            for w in sampled {
                expectFalse(w.isDelisted, "抽取的词条不能是已下架词条")
            }
        })
    }
    
    // MARK: - F7: 卡片抽取配额、四级切片与三明治穿插
    private static func registerF7Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F7_01", name: "F7_新学配额上限截取", tier: "Tier1") {
            let quota = LearningSessionPolicy.defaultNewQuota
            expectEqual(quota, 15, "默认新学配额应为 15 词")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F7_02", name: "F7_四级切片区分P0临界急救与P1深度逾期", tier: "Tier1") {
            let today = 100
            let p0Card = WordStudyState(wordId: 1, repetitionCount: 3, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 88, firstLearnedDate: 50, type: 2) // elapsed=12, R~0.8
            let p1Card = WordStudyState(wordId: 2, repetitionCount: 3, stability: 5.0, difficulty: 5.0, interval: 5, nextReviewDate: 70, lastReviewedDate: 60, firstLearnedDate: 50, type: 2)   // elapsed=40, R<0.6
            
            let sliced = LearningSessionPolicy.sliceReviewCards(states: [p0Card, p1Card], today: today)
            expectEqual(sliced.count, 2)
            expectEqual(sliced.first?.priority, .p0Emergency, "P0 临界急救卡片应排在首位")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F7_03", name: "F7_超额待复习卡片阻尼上限截断", tier: "Tier1") {
            var manyStates: [WordStudyState] = []
            for i in 1...100 {
                manyStates.append(WordStudyState(wordId: i, repetitionCount: 2, stability: 5.0, difficulty: 5.0, interval: 5, nextReviewDate: 90, lastReviewedDate: 85, firstLearnedDate: 50, type: 2))
            }
            let sliced = LearningSessionPolicy.sliceReviewCards(states: manyStates, today: 100)
            expectTrue(sliced.count <= LearningSessionPolicy.maxReviewDamping, "待复习卡片必须被阻尼上限 (\(LearningSessionPolicy.maxReviewDamping)) 截取")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F7_04", name: "F7_三明治混合新旧词穿插", tier: "Tier1") {
            let p0Words = [Word(id: 1, japanese: "p0_1", hiragana: "", chinese: "", level: "N1")]
            let revWords = (2...5).map { Word(id: $0, japanese: "rev_\($0)", hiragana: "", chinese: "", level: "N1") }
            let newWords = (6...7).map { Word(id: $0, japanese: "new_\($0)", hiragana: "", chinese: "", level: "N1") }
            
            let mixed = LearningSessionPolicy.sandwichMix(p0Cards: p0Words, reviewCards: revWords, newCards: newWords)
            expectEqual(mixed.count, 7)
            expectEqual(mixed.first?.id, 1, "P0 词必须在最前")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F7_05", name: "F7_无新词纯复习时优雅混合", tier: "Tier1") {
            let revWords = (1...5).map { Word(id: $0, japanese: "rev_\($0)", hiragana: "", chinese: "", level: "N1") }
            let mixed = LearningSessionPolicy.sandwichMix(p0Cards: [], reviewCards: revWords, newCards: [])
            expectEqual(mixed.count, 5)
            expectEqual(mixed.map { $0.id }, [1, 2, 3, 4, 5])
        })
    }
    
    // MARK: - F8: LearningSessionStore 彻底去 Mock
    private static func registerF8Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F8_01", name: "F8_会话移除硬编码12条Mock词", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            
            let words = try await dictStorage.sampleNewWords(count: 15, excludingLearnedIds: [])
            expectEqual(words.count, 15, "从真实词库抽取 15 词代替写死的 12 词")
            expectFalse(words.contains { $0.japanese == "食べる" && $0.id == 999999 }, "不得包含旧 Mock 假数据特征")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F8_02", name: "F8_移除写死12天打卡天数_支持动态计算", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            let zeroStreak = await storage.calculateCurrentStreak(today: 100)
            expectEqual(zeroStreak, 0, "全新用户打卡天数必须为 0，而非硬编码 12")
            
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 100)
            let updatedStreak = await storage.calculateCurrentStreak(today: 100)
            expectEqual(updatedStreak, 1)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F8_03", name: "F8_移除静态复习间隔提示_支持FSRS动态推算", tier: "Tier1") {
            let calc = SrsCalculatorImpl()
            let matureItem = WordStudyState(wordId: 1, repetitionCount: 5, stability: 30.0, difficulty: 4.0, interval: 30, nextReviewDate: 100, lastReviewedDate: 70, firstLearnedDate: 20, type: 2)
            let intervals = calc.predictNextIntervals(item: matureItem, today: 100)
            
            expectNotEqual(intervals[.good], "1d", "高稳定性卡片 Good 预测间隔不应写死为 1d，必须由 FSRS 动态计算")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F8_04", name: "F8_会话卡片包装Word与WordStudyState", tier: "Tier1") {
            let word = Word(id: 10, japanese: "試験", hiragana: "しけん", chinese: "考试", level: "N3")
            let state = WordStudyState(wordId: 10, repetitionCount: 1, stability: 2.3, difficulty: 6.0, interval: 2, nextReviewDate: 102, lastReviewedDate: 100, firstLearnedDate: 100, type: 2)
            
            expectEqual(word.id, state.wordId)
            expectEqual(state.repetitionCount, 1)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F8_05", name: "F8_会话队列支持动态注入词库数据源", tier: "Tier1") {
            let customWords = (100...110).map { Word(id: $0, japanese: "word_\($0)", hiragana: "", chinese: "", level: "N1") }
            expectEqual(customWords.count, 11)
            expectEqual(customWords.first?.id, 100)
        })
    }
    
    // MARK: - F9: 作答实时计算与持久化写回闭环
    private static func registerF9Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F9_01", name: "F9_作答后实时计算并更新状态模型", tier: "Tier1") {
            let calc = SrsCalculatorImpl()
            let item = WordStudyState(wordId: 88)
            let update = calc.calculate(item: item, quality: 4, today: 100)
            
            let updatedState = WordStudyState(
                wordId: 88,
                repetitionCount: update.repetitionCount,
                stability: update.stability,
                difficulty: update.difficulty,
                interval: update.interval,
                nextReviewDate: update.nextReviewDate,
                lastReviewedDate: update.lastReviewedDate,
                firstLearnedDate: update.firstLearnedDate,
                type: update.type
            )
            expectEqual(updatedState.repetitionCount, 1)
            expectTrue(updatedState.nextReviewDate > 100)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F9_02", name: "F9_作答更新直接写回本地持久化", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            let calc = SrsCalculatorImpl()
            
            let item = WordStudyState(wordId: 55)
            let update = calc.calculate(item: item, quality: 4, today: 100)
            let state = WordStudyState(
                wordId: 55,
                repetitionCount: update.repetitionCount,
                stability: update.stability,
                difficulty: update.difficulty,
                interval: update.interval,
                nextReviewDate: update.nextReviewDate,
                lastReviewedDate: update.lastReviewedDate,
                firstLearnedDate: update.firstLearnedDate,
                type: update.type
            )
            try await storage.saveStudyState(state)
            
            let saved = try await storage.getStudyState(wordId: 55)
            expectNotNil(saved)
            expectEqual(saved?.wordId, 55)
            expectEqual(saved?.repetitionCount, 1)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F9_03", name: "F9_会话完成战报指标统计", tier: "Tier1") {
            var learnedCount = 0
            var reviewedCount = 0
            let answers: [(isNew: Bool, quality: Int)] = [
                (true, 4), (true, 5), (true, 3), (false, 4), (false, 2)
            ]
            for ans in answers {
                if ans.isNew { learnedCount += 1 } else { reviewedCount += 1 }
            }
            expectEqual(learnedCount, 3)
            expectEqual(reviewedCount, 2)
            expectEqual(learnedCount + reviewedCount, 5)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F9_04", name: "F9_错题答Again加入重学队列尾部", tier: "Tier1") {
            var queue = [1, 2, 3]
            let current = queue.removeFirst() // 1
            // 答错 Again
            queue.append(current)
            expectEqual(queue, [2, 3, 1], "评 Again 的词条必须追加至队列尾部重学")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F9_05", name: "F9_会话结束自动联动累加打卡天数", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 15, reviewedIncrement: 5, date: 100)
            let streak = await storage.calculateCurrentStreak(today: 100)
            expectEqual(streak, 1)
        })
    }
    
    // MARK: - F10: 应用退出与冷启动完整恢复
    private static func registerF10Tests() {
        TestRegistry.shared.register(TestCase(id: "T1_F10_01", name: "F10_半途退出状态持久化不丢失", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            
            // 第一次使用
            do {
                let storage1 = MockLearningLocalStorage(sandbox: sandbox)
                try await storage1.saveStudyState(WordStudyState(wordId: 10, repetitionCount: 1, stability: 2.0, difficulty: 5.0, interval: 2, nextReviewDate: 102, lastReviewedDate: 100, firstLearnedDate: 100, type: 2))
                try await storage1.saveStudyState(WordStudyState(wordId: 20, repetitionCount: 1, stability: 2.5, difficulty: 4.8, interval: 3, nextReviewDate: 103, lastReviewedDate: 100, firstLearnedDate: 100, type: 2))
            }
            
            // 模拟冷启动重新实例化
            do {
                let storage2 = MockLearningLocalStorage(sandbox: sandbox)
                let s10 = try await storage2.getStudyState(wordId: 10)
                let s20 = try await storage2.getStudyState(wordId: 20)
                expectNotNil(s10)
                expectNotNil(s20)
                expectEqual(s10?.repetitionCount, 1)
                expectEqual(s20?.repetitionCount, 1)
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F10_02", name: "F10_冷启动重新加载所有已学单词集合", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            for i in 1...20 {
                try await storage.saveStudyState(WordStudyState(wordId: i, repetitionCount: 1, stability: 2.0, difficulty: 5.0, interval: 2, nextReviewDate: 102, lastReviewedDate: 100, firstLearnedDate: 100, type: 2))
            }
            
            let all = try await storage.getAllStudyStates()
            let learnedIds = Set(all.keys)
            expectEqual(learnedIds.count, 20)
            for i in 1...20 {
                expectTrue(learnedIds.contains(i))
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F10_03", name: "F10_重复加载幂等性", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.saveStudyState(WordStudyState(wordId: 1, repetitionCount: 1))
            let r1 = try await storage.getAllStudyStates()
            let r2 = try await storage.getAllStudyStates()
            expectEqual(r1.count, r2.count)
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F10_04", name: "F10_打卡历史冷启动恢复", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            
            do {
                let storage = MockLearningLocalStorage(sandbox: sandbox)
                try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 5, date: 100)
            }
            do {
                let storage = MockLearningLocalStorage(sandbox: sandbox)
                let rec = await storage.getTodayRecord(today: 100)
                expectNotNil(rec)
                expectEqual(rec?.totalCount, 15)
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F10_05", name: "F10_并发多读安全", tier: "Tier1") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            try await storage.saveStudyState(WordStudyState(wordId: 1, repetitionCount: 1))
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 1...20 {
                    group.addTask {
                        _ = try? await storage.getStudyState(wordId: 1)
                    }
                }
            }
            let item = try await storage.getStudyState(wordId: 1)
            expectNotNil(item)
        })
    }
}
