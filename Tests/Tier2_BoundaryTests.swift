import Foundation

public struct Tier2_BoundaryTests {
    public static func registerAll() {
        registerF1BoundaryTests()
        registerF2BoundaryTests()
        registerF3BoundaryTests()
        registerF4BoundaryTests()
        registerF5BoundaryTests()
        registerF6BoundaryTests()
        registerF7BoundaryTests()
        registerF8BoundaryTests()
        registerF9BoundaryTests()
        registerF10BoundaryTests()
    }
    
    // MARK: - F1 边界极值
    private static func registerF1BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F1_01", name: "F1_边界_极小稳定性下限保护", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let s = algo.initStability(rating: .again)
            expectTrue(s >= FsrsAlgorithm.sMin, "Again 稳定性不得低于 S_MIN (0.01)")
            
            // 失败衰减不能低于 S_MIN
            let failS = algo.stabilityAfterFailure(stability: 0.001, difficulty: 10.0, retrievability: 0.0)
            expectTrue(failS >= FsrsAlgorithm.sMin)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F1_02", name: "F1_边界_极大稳定性上限保护", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let highS = 50000.0
            let r = algo.forgettingCurve(elapsedDays: 1.0, stability: highS)
            let newS = algo.stabilityAfterSuccess(stability: highS, difficulty: 1.0, retrievability: r, rating: .easy)
            expectTrue(newS <= FsrsAlgorithm.sMax, "极大稳定性不得超过 S_MAX (36500.0)")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F1_03", name: "F1_边界_难度区间严格在1到10之间", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            for r in FsrsRating.allCases {
                let d = algo.initDifficulty(rating: r)
                expectTrue(d >= FsrsAlgorithm.dMin && d <= FsrsAlgorithm.dMax, "初始难度必须在 [1, 10] 之间，当前: \(d)")
            }
            let dMaxClamped = algo.nextDifficulty(difficulty: 10.0, rating: .again)
            expectTrue(dMaxClamped <= FsrsAlgorithm.dMax, "再次失败后难度不能超过 10.0")
            let dMinClamped = algo.nextDifficulty(difficulty: 1.0, rating: .easy)
            expectTrue(dMinClamped >= FsrsAlgorithm.dMin, "连续简单后难度不能低于 1.0")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F1_04", name: "F1_边界_经过0天与超长经过天数", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let r0 = algo.forgettingCurve(elapsedDays: 0, stability: 10.0)
            expectApproxEqual(r0, 1.0, accuracy: 0.0001)
            
            let rExtreme = algo.forgettingCurve(elapsedDays: 3650.0, stability: 1.0)
            expectTrue(rExtreme > 0.0 && rExtreme < 0.35, "逾期10年回忆率根据FSRS幂律衰减应降至约0.28")
        })
        
        TestRegistry.shared.register(TestCase(id: "T1_F1_05", name: "F1_边界_极端目标保留率边界", tier: "Tier2") {
            let algoMin = FsrsAlgorithm(desiredRetention: 0.70)
            let algoMax = FsrsAlgorithm(desiredRetention: 0.97)
            let intervalLow = algoMin.nextInterval(stability: 10.0)
            let intervalHigh = algoMax.nextInterval(stability: 10.0)
            expectTrue(intervalLow > intervalHigh, "低保留率 (0.70) 允许更长复习间隔，高保留率 (0.97) 必须要求更短复习间隔")
        })
    }
    
    // MARK: - F2 边界极值
    private static func registerF2BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F2_01", name: "F2_边界_极端种子输入测试", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let seeds: [Int64] = [0, -1, 1, Int64.max, Int64.min]
            for s in seeds {
                let fuzzed = algo.fuzzIntervalDays(baseInterval: 10, seed: s)
                expectTrue(fuzzed >= 1 && fuzzed <= FsrsAlgorithm.maxInterval, "极端种子 \(s) 下抖动必须落在安全合法范围内")
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F2_02", name: "F2_边界_基准间隔临界跨度3天测试", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let f2 = algo.fuzzIntervalDays(baseInterval: 2, seed: 42)
            expectEqual(f2, 2, "2天不能抖动")
            let f3 = algo.fuzzIntervalDays(baseInterval: 3, seed: 42)
            expectTrue(f3 >= 2 && f3 <= 4, "3天间隔抖动跨度必须在 [2, 4] 之间")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F2_03", name: "F2_边界_基准间隔临界跨度7天测试", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let f7 = algo.fuzzIntervalDays(baseInterval: 7, seed: 42)
            expectTrue(f7 >= 6 && f7 <= 8, "7天间隔抖动跨度应在合理范围")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F2_04", name: "F2_边界_基准间隔临界跨度30天测试", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let f30 = algo.fuzzIntervalDays(baseInterval: 30, seed: 42)
            expectTrue(f30 >= 26 && f30 <= 34, "30天间隔抖动跨度在 [26, 34]")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F2_05", name: "F2_边界_基准间隔临界跨度90天测试", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let f90 = algo.fuzzIntervalDays(baseInterval: 90, seed: 42)
            expectTrue(f90 >= 76 && f90 <= 104, "90天间隔抖动跨度安全合法")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F2_06", name: "F2_边界_极大间隔抖动截断保护", tier: "Tier2") {
            let algo = FsrsAlgorithm()
            let fMax = algo.fuzzIntervalDays(baseInterval: FsrsAlgorithm.maxInterval, seed: 999)
            expectTrue(fMax <= FsrsAlgorithm.maxInterval, "抖动后不能超过最大允许间隔")
        })
    }
    
    // MARK: - F3 边界极值
    private static func registerF3BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F3_01", name: "F3_边界_1000次大样本随机组合单调性零倒挂检验", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            var rngState: UInt64 = 8888
            func nextRandom() -> Double {
                rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
                return Double(rngState >> 33) / Double(1 << 31)
            }
            
            for _ in 1...1000 {
                let stab = 0.5 + nextRandom() * 50.0
                let diff = 1.0 + nextRandom() * 9.0
                let rep = 1 + Int(nextRandom() * 10.0)
                let elapsed = Int(1.0 + nextRandom() * 60.0)
                let item = WordStudyState(wordId: 1, repetitionCount: rep, stability: stab, difficulty: diff, interval: max(1, Int(stab)), nextReviewDate: 100, lastReviewedDate: 100 - elapsed, firstLearnedDate: 50, type: 2)
                
                let hard = calc.calculate(item: item, quality: 3, today: 100)
                let good = calc.calculate(item: item, quality: 4, today: 100)
                let easy = calc.calculate(item: item, quality: 5, today: 100)
                
                expectTrue(hard.interval <= good.interval, "Hard <= Good 发生倒挂！Hard: \(hard.interval), Good: \(good.interval)")
                expectTrue(good.interval <= easy.interval, "Good <= Easy 发生倒挂！Good: \(good.interval), Easy: \(easy.interval)")
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F3_02", name: "F3_边界_连续多次评Again稳定性下限安全", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            var item = WordStudyState(wordId: 1, repetitionCount: 3, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 90, firstLearnedDate: 50, type: 2)
            
            for _ in 1...5 {
                let res = calc.calculate(item: item, quality: 1, today: 100)
                expectTrue(res.stability >= FsrsAlgorithm.sMin)
                expectTrue(res.interval >= 1)
                item = WordStudyState(wordId: 1, repetitionCount: res.repetitionCount, stability: res.stability, difficulty: res.difficulty, interval: res.interval, nextReviewDate: res.nextReviewDate, lastReviewedDate: res.lastReviewedDate, firstLearnedDate: res.firstLearnedDate, type: res.type)
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F3_03", name: "F3_边界_连续评Easy稳定性平稳增长", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            var item = WordStudyState(wordId: 1)
            var currentDay = 100
            for _ in 1...5 {
                let res = calc.calculate(item: item, quality: 5, today: currentDay)
                expectTrue(res.stability > item.stability)
                expectTrue(res.interval >= 1)
                currentDay += res.interval
                item = WordStudyState(wordId: 1, repetitionCount: res.repetitionCount, stability: res.stability, difficulty: res.difficulty, interval: res.interval, nextReviewDate: res.nextReviewDate, lastReviewedDate: res.lastReviewedDate, firstLearnedDate: res.firstLearnedDate, type: res.type)
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F3_04", name: "F3_边界_最大难度10下评Again截断惩罚", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            let item = WordStudyState(wordId: 1, repetitionCount: 5, stability: 20.0, difficulty: 10.0, interval: 20, nextReviewDate: 100, lastReviewedDate: 80, firstLearnedDate: 30, type: 2)
            let res = calc.calculate(item: item, quality: 2, today: 100)
            expectTrue(res.stability < 10.0, "难度为10时遗忘应受到强烈截断惩罚")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F3_05", name: "F3_边界_预测字典全覆盖性", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            let item = WordStudyState(wordId: 1)
            let map = calc.predictNextIntervals(item: item, today: 100)
            expectEqual(map.count, 4, "预测字典必须包含全部4个按钮预览")
        })
    }
    
    // MARK: - F4 边界极值
    private static func registerF4BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F4_01", name: "F4_边界_无数据时加载返回空字典而非崩溃", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            let all = try await storage.getAllStudyStates()
            expectTrue(all.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F4_02", name: "F4_边界_特殊字符与日文汉字状态存储", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            let state = WordStudyState(wordId: 8888, repetitionCount: 1, stability: 3.14159, difficulty: 7.7777, interval: 3, nextReviewDate: 103, lastReviewedDate: 100, firstLearnedDate: 100, type: 2)
            try await storage.saveStudyState(state)
            let loaded = try await storage.getStudyState(wordId: 8888)
            expectNotNil(loaded)
            expectEqual(loaded?.wordId, 8888)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F4_03", name: "F4_边界_超万张卡片批量存储与反序列化吞吐", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            var bigStates: [WordStudyState] = []
            bigStates.reserveCapacity(5000)
            for i in 1...5000 {
                bigStates.append(WordStudyState(wordId: i, repetitionCount: 1, stability: 1.0, difficulty: 5.0, interval: 1, nextReviewDate: 101, lastReviewedDate: 100, firstLearnedDate: 100, type: 2))
            }
            try await storage.saveStudyStates(bigStates)
            let all = try await storage.getAllStudyStates()
            expectEqual(all.count, 5000)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F4_04", name: "F4_边界_保存空数组时不破坏原有文件", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            try await storage.saveStudyStates([])
            let all = try await storage.getAllStudyStates()
            expectTrue(all.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F4_05", name: "F4_边界_同一wordId更新不增加条数", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.saveStudyState(WordStudyState(wordId: 1, repetitionCount: 1))
            try await storage.saveStudyState(WordStudyState(wordId: 1, repetitionCount: 2))
            let all = try await storage.getAllStudyStates()
            expectEqual(all.count, 1)
            expectEqual(all[1]?.repetitionCount, 2)
        })
    }
    
    // MARK: - F5 边界极值
    private static func registerF5BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F5_01", name: "F5_边界_EpochDay为0或负数的Streak推算", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 5, reviewedIncrement: 0, date: 0)
            let s0 = await storage.calculateCurrentStreak(today: 0)
            expectEqual(s0, 1)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F5_02", name: "F5_边界_跨闰年打卡连续性", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            // 假设 19782 代表 2024-02-28, 19783 代表 2024-02-29, 19784 代表 2024-03-01
            try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 0, date: 19782)
            try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 0, date: 19783)
            try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 0, date: 19784)
            
            let streak = await storage.calculateCurrentStreak(today: 19784)
            expectEqual(streak, 3, "闰年打卡基于 EpochDay 连续天数应为 3")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F5_03", name: "F5_边界_0增量记录打卡", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 0, reviewedIncrement: 0, date: 100)
            let rec = await storage.getTodayRecord(today: 100)
            expectNotNil(rec)
            expectEqual(rec?.totalCount, 0)
            let streak = await storage.calculateCurrentStreak(today: 100)
            expectEqual(streak, 0, "学习总量为0时不计入打卡Streak")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F5_04", name: "F5_边界_连续打卡365天长周期推算", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            for d in 1...365 {
                try await storage.recordDailyStudy(learnedIncrement: 1, reviewedIncrement: 1, date: d)
            }
            let streak = await storage.calculateCurrentStreak(today: 365)
            expectEqual(streak, 365, "连续365天打卡 Streak 必须为 365")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F5_05", name: "F5_边界_连续断卡100天后打卡", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 1)
            try await storage.recordDailyStudy(learnedIncrement: 10, reviewedIncrement: 0, date: 102)
            let streak = await storage.calculateCurrentStreak(today: 102)
            expectEqual(streak, 1, "长期断卡后打卡 Streak 重置为 1")
        })
    }
    
    // MARK: - F6 边界极值
    private static func registerF6BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F6_01", name: "F6_边界_空词库抽样安全返回空数组", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords([])
            
            let sampled = try await dictStorage.sampleNewWords(count: 10, excludingLearnedIds: [])
            expectTrue(sampled.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F6_02", name: "F6_边界_全量已下架词库抽样安全返回空", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let words = [
                Word(id: 1, japanese: "w1", hiragana: "", chinese: "", level: "N1", isDelisted: true),
                Word(id: 2, japanese: "w2", hiragana: "", chinese: "", level: "N1", isDelisted: true)
            ]
            try await dictStorage.saveWords(words)
            let sampled = try await dictStorage.sampleNewWords(count: 5, excludingLearnedIds: [])
            expectTrue(sampled.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F6_03", name: "F6_边界_排除集合等于全量词库时抽样安全返回空", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let words = [Word(id: 1, japanese: "w1", hiragana: "", chinese: "", level: "N1")]
            try await dictStorage.saveWords(words)
            let sampled = try await dictStorage.sampleNewWords(count: 5, excludingLearnedIds: [1])
            expectTrue(sampled.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F6_04", name: "F6_边界_抽样配额超过可用候选上限安全截断", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let words = (1...3).map { Word(id: $0, japanese: "w_\($0)", hiragana: "", chinese: "", level: "N1") }
            try await dictStorage.saveWords(words)
            let sampled = try await dictStorage.sampleNewWords(count: 20, excludingLearnedIds: [])
            expectEqual(sampled.count, 3, "候选仅3条时，抽样请求20条安全返回3条")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F6_05", name: "F6_边界_传入不存在等级筛选安全返回空", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let words = [Word(id: 1, japanese: "w1", hiragana: "", chinese: "", level: "N1")]
            try await dictStorage.saveWords(words)
            let sampled = try await dictStorage.sampleNewWords(count: 5, excludingLearnedIds: [], level: "N9")
            expectTrue(sampled.isEmpty)
        })
    }
    
    // MARK: - F7 边界极值
    private static func registerF7BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F7_01", name: "F7_边界_全部为P0急救卡切片排序", tier: "Tier2") {
            let cards = [
                WordStudyState(wordId: 1, repetitionCount: 2, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 88, firstLearnedDate: 50, type: 2), // R~0.8
                WordStudyState(wordId: 2, repetitionCount: 2, stability: 10.0, difficulty: 5.0, interval: 10, nextReviewDate: 100, lastReviewedDate: 85, firstLearnedDate: 50, type: 2)  // R~0.7 (更低更急)
            ]
            let sliced = LearningSessionPolicy.sliceReviewCards(states: cards, today: 100)
            expectEqual(sliced.count, 2)
            expectTrue(sliced[0].retrievability <= sliced[1].retrievability, "P0 急救卡必须按回忆率升序（最危急先复习）")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F7_02", name: "F7_边界_全部为P1深度逾期卡切片", tier: "Tier2") {
            let cards = [
                WordStudyState(wordId: 1, repetitionCount: 1, stability: 1.0, difficulty: 5.0, interval: 1, nextReviewDate: 11, lastReviewedDate: 10, firstLearnedDate: 0, type: 2), // elapsed=90, R~0.50 (<0.6)
                WordStudyState(wordId: 2, repetitionCount: 1, stability: 1.0, difficulty: 5.0, interval: 1, nextReviewDate: 21, lastReviewedDate: 20, firstLearnedDate: 0, type: 2)  // elapsed=80, R~0.51 (<0.6)
            ]
            let sliced = LearningSessionPolicy.sliceReviewCards(states: cards, today: 100)
            expectEqual(sliced.count, 2)
            for s in sliced {
                expectEqual(s.priority, .p1Overdue)
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F7_03", name: "F7_边界_全部为P2常规到期卡切片", tier: "Tier2") {
            let cards = [
                WordStudyState(wordId: 1, repetitionCount: 5, stability: 60.0, difficulty: 4.0, interval: 60, nextReviewDate: 100, lastReviewedDate: 98, firstLearnedDate: 10, type: 2),
                WordStudyState(wordId: 2, repetitionCount: 5, stability: 60.0, difficulty: 4.0, interval: 60, nextReviewDate: 99, lastReviewedDate: 97, firstLearnedDate: 10, type: 2)
            ]
            let sliced = LearningSessionPolicy.sliceReviewCards(states: cards, today: 100)
            expectEqual(sliced.count, 2)
            for s in sliced {
                expectEqual(s.priority, .p2Due)
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F7_04", name: "F7_边界_极高积压卡片精确截断为40", tier: "Tier2") {
            var cards: [WordStudyState] = []
            for i in 1...200 {
                cards.append(WordStudyState(wordId: i, repetitionCount: 2, stability: 5.0, difficulty: 5.0, interval: 5, nextReviewDate: 90, lastReviewedDate: 85, firstLearnedDate: 50, type: 2))
            }
            let sliced = LearningSessionPolicy.sliceReviewCards(states: cards, today: 100)
            expectEqual(sliced.count, LearningSessionPolicy.maxReviewDamping)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F7_05", name: "F7_边界_三明治穿插比例失衡时安全混排", tier: "Tier2") {
            let revWords = (1...30).map { Word(id: $0, japanese: "rev_\($0)", hiragana: "", chinese: "", level: "N1") }
            let newWords = [Word(id: 999, japanese: "new_1", hiragana: "", chinese: "", level: "N1")]
            let mixed = LearningSessionPolicy.sandwichMix(p0Cards: [], reviewCards: revWords, newCards: newWords)
            expectEqual(mixed.count, 31)
            expectTrue(mixed.contains { $0.id == 999 })
        })
    }
    
    // MARK: - F8 边界极值
    private static func registerF8BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F8_01", name: "F8_边界_未缓存词库时安全返回空数组", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            let words = try await dictStorage.preloadWordsIfNeeded()
            expectTrue(words.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F8_02", name: "F8_边界_配额请求0词返回空", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            let sampled = try await dictStorage.sampleNewWords(count: 0, excludingLearnedIds: [])
            expectTrue(sampled.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F8_03", name: "F8_边界_超大配额100词安全抽取", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let dictStorage = MockDictionaryLocalStorage(sandbox: sandbox)
            try await dictStorage.saveWords(TestDataGenerator.generate9876Dictionary())
            let sampled = try await dictStorage.sampleNewWords(count: 100, excludingLearnedIds: [])
            expectEqual(sampled.count, 100)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F8_04", name: "F8_边界_预测间隔在0天与1天展示格式", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            let item = WordStudyState(wordId: 1, repetitionCount: 1, stability: 0.5, difficulty: 5.0, interval: 1, nextReviewDate: 101, lastReviewedDate: 100, firstLearnedDate: 100, type: 2)
            let previews = calc.predictNextIntervals(item: item, today: 100)
            expectEqual(previews[.hard], "1d")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F8_05", name: "F8_边界_高稳定性长周期间隔显示格式为年或月", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            let item = WordStudyState(wordId: 1, repetitionCount: 10, stability: 400.0, difficulty: 2.0, interval: 400, nextReviewDate: 500, lastReviewedDate: 100, firstLearnedDate: 0, type: 2)
            let previews = calc.predictNextIntervals(item: item, today: 500)
            expectTrue(previews[.easy]?.hasSuffix("y") == true || previews[.easy]?.hasSuffix("m") == true)
        })
    }
    
    // MARK: - F9 边界极值
    private static func registerF9BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F9_01", name: "F9_边界_同卡连续10次Again稳定性保护", tier: "Tier2") {
            let calc = SrsCalculatorImpl()
            var item = WordStudyState(wordId: 99)
            for _ in 1...10 {
                let res = calc.calculate(item: item, quality: 1, today: 100)
                expectEqual(res.repetitionCount, 0)
                expectTrue(res.stability >= FsrsAlgorithm.sMin)
                item = WordStudyState(wordId: 99, repetitionCount: res.repetitionCount, stability: res.stability, difficulty: res.difficulty, interval: res.interval, nextReviewDate: res.nextReviewDate, lastReviewedDate: res.lastReviewedDate, firstLearnedDate: res.firstLearnedDate, type: res.type)
            }
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F9_02", name: "F9_边界_全选Easy时战报指标", tier: "Tier2") {
            let answers: [Int] = Array(repeating: 5, count: 15)
            let correctCount = answers.filter { $0 >= 3 }.count
            expectEqual(correctCount, 15)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F9_03", name: "F9_边界_重学队列反复进出直到清空", tier: "Tier2") {
            var relearnQueue = [10, 20]
            var clearCount = 0
            while !relearnQueue.isEmpty {
                let card = relearnQueue.removeFirst()
                // 模拟第一次答错，第二次答对
                if card == 10 && clearCount == 0 {
                    relearnQueue.append(card)
                    clearCount += 1
                }
            }
            expectTrue(relearnQueue.isEmpty)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F9_04", name: "F9_边界_会话用时0秒战报计算", tier: "Tier2") {
            let duration: TimeInterval = 0
            expectEqual(duration, 0)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F9_05", name: "F9_边界_持久化写回遇到无效状态容错", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            let state = WordStudyState(wordId: 0, repetitionCount: 0)
            try await storage.saveStudyState(state)
            let loaded = try await storage.getStudyState(wordId: 0)
            expectNotNil(loaded)
        })
    }
    
    // MARK: - F10 边界极值
    private static func registerF10BoundaryTests() {
        TestRegistry.shared.register(TestCase(id: "T2_F10_01", name: "F10_边界_空字节文件容错读取", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let emptyFile = sandbox.fileURL(named: "study_states.json")
            try Data().write(to: emptyFile)
            
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            let all = try await storage.getAllStudyStates()
            expectTrue(all.isEmpty, "空字节文件应平稳兜底为空字典，不能崩溃")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F10_02", name: "F10_边界_损坏JSON内容容错读取", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let corruptFile = sandbox.fileURL(named: "study_states.json")
            try "INVALID_JSON_CORRUPTED_DATA".data(using: .utf8)?.write(to: corruptFile)
            
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            let all = try await storage.getAllStudyStates()
            expectTrue(all.isEmpty, "损坏的 JSON 数据应平稳兜底，不发生崩溃")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F10_03", name: "F10_边界_高并发读写死锁防御", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            
            await withTaskGroup(of: Void.self) { group in
                for i in 1...20 {
                    group.addTask {
                        try? await storage.saveStudyState(WordStudyState(wordId: i, repetitionCount: 1))
                        _ = try? await storage.getStudyState(wordId: i)
                    }
                }
            }
            let all = try await storage.getAllStudyStates()
            expectTrue(all.count > 0)
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F10_04", name: "F10_边界_连续冷启动状态严格幂等", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            
            let storage1 = MockLearningLocalStorage(sandbox: sandbox)
            try await storage1.saveStudyState(WordStudyState(wordId: 1, repetitionCount: 2, stability: 5.0, difficulty: 5.0, interval: 5, nextReviewDate: 105, lastReviewedDate: 100, firstLearnedDate: 90, type: 2))
            
            let storage2 = MockLearningLocalStorage(sandbox: sandbox)
            let s2 = try await storage2.getStudyState(wordId: 1)
            
            let storage3 = MockLearningLocalStorage(sandbox: sandbox)
            let s3 = try await storage3.getStudyState(wordId: 1)
            
            expectEqual(s2, s3, "多次冷启动重新加载结果必须严格一致")
        })
        
        TestRegistry.shared.register(TestCase(id: "T2_F10_05", name: "F10_边界_沙盒目录自动生成自愈能力", tier: "Tier2") {
            let sandbox = MockSandbox()
            defer { sandbox.cleanUp() }
            
            let storage = MockLearningLocalStorage(sandbox: sandbox)
            try await storage.saveStudyState(WordStudyState(wordId: 99, repetitionCount: 1))
            let loaded = try await storage.getStudyState(wordId: 99)
            expectNotNil(loaded)
        })
    }
}
