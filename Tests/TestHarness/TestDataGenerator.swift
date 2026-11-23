import Foundation

// MARK: - 基础模型定义（对齐 PROJECT.md 接口契约）

public struct Word: Identifiable, Codable, Sendable, Hashable {
    public let id: Int
    public let rawId: String?
    public let japanese: String
    public let hiragana: String
    public let chinese: String
    public let level: String
    public let pos: String?
    public let example1: String?
    public let gloss1: String?
    public let example2: String?
    public let gloss2: String?
    public let example3: String?
    public let gloss3: String?
    public let isDelisted: Bool
    public let updatedAt: String?
    
    public init(
        id: Int,
        rawId: String? = nil,
        japanese: String,
        hiragana: String,
        chinese: String,
        level: String,
        pos: String? = "名",
        example1: String? = nil,
        gloss1: String? = nil,
        example2: String? = nil,
        gloss2: String? = nil,
        example3: String? = nil,
        gloss3: String? = nil,
        isDelisted: Bool = false,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.rawId = rawId
        self.japanese = japanese
        self.hiragana = hiragana
        self.chinese = chinese
        self.level = level
        self.pos = pos
        self.example1 = example1
        self.gloss1 = gloss1
        self.example2 = example2
        self.gloss2 = gloss2
        self.example3 = example3
        self.gloss3 = gloss3
        self.isDelisted = isDelisted
        self.updatedAt = updatedAt
    }
}

public protocol SrsItem: Sendable {
    var repetitionCount: Int { get }
    var stability: Double { get }
    var difficulty: Double { get }
    var interval: Int { get }
    var nextReviewDate: Int { get }
    var lastReviewedDate: Int? { get }
    var firstLearnedDate: Int? { get }
    var type: Int { get } // 0=New, 1=Learning, 2=Review, 3=Relearning
}

public struct SrsUpdateResult: Sendable, Equatable {
    public let repetitionCount: Int
    public let stability: Double
    public let difficulty: Double
    public let interval: Int
    public let nextReviewDate: Int
    public let lastReviewedDate: Int?
    public let firstLearnedDate: Int?
    public let type: Int
    
    public init(
        repetitionCount: Int,
        stability: Double,
        difficulty: Double,
        interval: Int,
        nextReviewDate: Int,
        lastReviewedDate: Int?,
        firstLearnedDate: Int?,
        type: Int
    ) {
        self.repetitionCount = repetitionCount
        self.stability = stability
        self.difficulty = difficulty
        self.interval = interval
        self.nextReviewDate = nextReviewDate
        self.lastReviewedDate = lastReviewedDate
        self.firstLearnedDate = firstLearnedDate
        self.type = type
    }
}

public struct WordStudyState: SrsItem, Identifiable, Codable, Sendable, Equatable {
    public var id: Int { wordId }
    public let wordId: Int
    public var repetitionCount: Int
    public var stability: Double
    public var difficulty: Double
    public var interval: Int
    public var nextReviewDate: Int
    public var lastReviewedDate: Int?
    public var firstLearnedDate: Int?
    public var type: Int
    
    public init(
        wordId: Int,
        repetitionCount: Int = 0,
        stability: Double = 0.0,
        difficulty: Double = 0.0,
        interval: Int = 0,
        nextReviewDate: Int = 0,
        lastReviewedDate: Int? = nil,
        firstLearnedDate: Int? = nil,
        type: Int = 0
    ) {
        self.wordId = wordId
        self.repetitionCount = repetitionCount
        self.stability = stability
        self.difficulty = difficulty
        self.interval = interval
        self.nextReviewDate = nextReviewDate
        self.lastReviewedDate = lastReviewedDate
        self.firstLearnedDate = firstLearnedDate
        self.type = type
    }
}

public struct StudyDailyRecord: Identifiable, Codable, Sendable, Equatable {
    public var id: Int { date }
    public let date: Int // EpochDay
    public var learnedCount: Int
    public var reviewedCount: Int
    public var totalCount: Int { learnedCount + reviewedCount }
    
    public init(date: Int, learnedCount: Int = 0, reviewedCount: Int = 0) {
        self.date = date
        self.learnedCount = learnedCount
        self.reviewedCount = reviewedCount
    }
}

public enum FsrsRating: Int, Sendable, CaseIterable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

public struct MemoryState: Sendable, Equatable {
    public var stability: Double
    public var difficulty: Double
    
    public init(stability: Double = 0.0, difficulty: Double = 0.0) {
        self.stability = stability
        self.difficulty = difficulty
    }
}

// MARK: - FSRS 6 核心算法纯 Swift 原生实现（严格对齐 Android FsrsAlgorithm.kt）

public struct FsrsAlgorithm: Sendable {
    public static let defaultParameters: [Double] = [
        0.212,      // w[0]: init_stability for Again
        1.2931,     // w[1]: init_stability for Hard
        2.3065,     // w[2]: init_stability for Good
        8.2956,     // w[3]: init_stability for Easy
        6.4133,     // w[4]: init_difficulty base
        0.8334,     // w[5]: init_difficulty rating factor
        3.0194,     // w[6]: next_difficulty delta factor
        0.001,      // w[7]: mean_reversion weight
        1.8722,     // w[8]: stability_after_success exp base
        0.1666,     // w[9]: stability_after_success stability power
        0.796,      // w[10]: stability_after_success retrievability factor
        1.4835,     // w[11]: stability_after_failure base
        0.0614,     // w[12]: stability_after_failure difficulty power
        0.2629,     // w[13]: stability_after_failure stability power
        1.6483,     // w[14]: stability_after_failure retrievability factor
        0.6014,     // w[15]: hard_penalty
        1.8729,     // w[16]: easy_bonus
        0.5425,     // w[17]: short_term factor
        0.0912,     // w[18]: short_term rating offset
        0.0658,     // w[19]: short_term stability power
        0.1542      // w[20]: decay (FSRS 6)
    ]
    
    public static let sMin: Double = 0.01
    public static let sMax: Double = 36500.0
    public static let dMin: Double = 1.0
    public static let dMax: Double = 10.0
    public static let maxInterval: Int = 36500
    
    public let parameters: [Double]
    public let desiredRetention: Double
    
    public init(parameters: [Double] = FsrsAlgorithm.defaultParameters, desiredRetention: Double = 0.9) {
        self.parameters = parameters
        self.desiredRetention = desiredRetention
    }
    
    private var w: [Double] { parameters }
    
    public func forgettingCurve(elapsedDays: Double, stability: Double) -> Double {
        let decay = w[20]
        let factor = pow(0.9, 1.0 / -decay) - 1.0
        return pow(1.0 + factor * (elapsedDays / stability), -decay)
    }
    
    public func nextInterval(stability: Double, retention: Double? = nil) -> Double {
        let targetRetention = retention ?? desiredRetention
        let decay = w[20]
        let factor = pow(0.9, 1.0 / -decay) - 1.0
        return (stability / factor) * (pow(targetRetention, 1.0 / -decay) - 1.0)
    }
    
    public func initStability(rating: FsrsRating) -> Double {
        let s = w[rating.rawValue - 1]
        return min(max(s, FsrsAlgorithm.sMin), FsrsAlgorithm.sMax)
    }
    
    public func initDifficulty(rating: FsrsRating) -> Double {
        let d = w[4] - exp(w[5] * Double(rating.rawValue - 1)) + 1.0
        return min(max(d, FsrsAlgorithm.dMin), FsrsAlgorithm.dMax)
    }
    
    public func stabilityAfterSuccess(stability: Double, difficulty: Double, retrievability: Double, rating: FsrsRating) -> Double {
        let hardPenalty = (rating == .hard) ? w[15] : 1.0
        let easyBonus = (rating == .easy) ? w[16] : 1.0
        
        let newS = stability * (
            exp(w[8]) *
            (11.0 - difficulty) *
            pow(stability, -w[9]) *
            (exp((1.0 - retrievability) * w[10]) - 1.0) *
            hardPenalty *
            easyBonus + 1.0
        )
        return min(max(newS, FsrsAlgorithm.sMin), FsrsAlgorithm.sMax)
    }
    
    public func stabilityAfterFailure(stability: Double, difficulty: Double, retrievability: Double) -> Double {
        let newS = w[11] *
            pow(difficulty, -w[12]) *
            (pow(stability + 1.0, w[13]) - 1.0) *
            exp((1.0 - retrievability) * w[14])
        
        // 官方截断约束: S / exp(w[17] * w[18])
        let maxS = stability / exp(w[17] * w[18])
        return min(max(min(newS, maxS), FsrsAlgorithm.sMin), FsrsAlgorithm.sMax)
    }
    
    public func stabilityShortTerm(stability: Double, rating: FsrsRating) -> Double {
        let sinc = exp(w[17] * (Double(rating.rawValue) - 3.0 + w[18])) * pow(stability, -w[19])
        let clampedSinc = (rating.rawValue >= 3) ? max(sinc, 1.0) : sinc
        return min(max(stability * clampedSinc, FsrsAlgorithm.sMin), FsrsAlgorithm.sMax)
    }
    
    public func nextDifficulty(difficulty: Double, rating: FsrsRating) -> Double {
        let deltaD = -w[6] * (Double(rating.rawValue) - 3.0)
        let linearDamped = deltaD * (10.0 - difficulty) / 9.0
        let newD = difficulty + linearDamped
        
        // Mean reversion
        let d0Good = w[4] - exp(w[5] * (4.0 - 1.0)) + 1.0
        let reverted = w[7] * (d0Good - newD) + newD
        return min(max(reverted, FsrsAlgorithm.dMin), FsrsAlgorithm.dMax)
    }
    
    public func step(currentState: MemoryState?, rating: FsrsRating, elapsedDays: Double) -> MemoryState {
        guard let current = currentState, current.stability > 0.0 else {
            return MemoryState(
                stability: initStability(rating: rating),
                difficulty: initDifficulty(rating: rating)
            )
        }
        
        let s = min(max(current.stability, FsrsAlgorithm.sMin), FsrsAlgorithm.sMax)
        let d = min(max(current.difficulty, FsrsAlgorithm.dMin), FsrsAlgorithm.dMax)
        
        let newS: Double
        if elapsedDays < 1.0 {
            newS = stabilityShortTerm(stability: s, rating: rating)
        } else {
            let r = forgettingCurve(elapsedDays: elapsedDays, stability: s)
            if rating == .again {
                newS = stabilityAfterFailure(stability: s, difficulty: d, retrievability: r)
            } else {
                newS = stabilityAfterSuccess(stability: s, difficulty: d, retrievability: r, rating: rating)
            }
        }
        
        let newD = nextDifficulty(difficulty: d, rating: rating)
        return MemoryState(
            stability: min(max(newS, FsrsAlgorithm.sMin), FsrsAlgorithm.sMax),
            difficulty: min(max(newD, FsrsAlgorithm.dMin), FsrsAlgorithm.dMax)
        )
    }
    
    public func nextIntervalDays(stability: Double) -> Int {
        let raw = nextInterval(stability: stability)
        let rounded = Int(raw.rounded())
        return min(max(rounded, 1), FsrsAlgorithm.maxInterval)
    }
    
    public func fuzzIntervalDays(baseInterval: Int, seed: Int64) -> Int {
        if baseInterval < 3 { return baseInterval }
        
        let span: Int
        if baseInterval < 7 {
            span = 1
        } else if baseInterval < 30 {
            span = max(1, Int((Double(baseInterval) * 0.08).rounded()))
        } else if baseInterval < 90 {
            span = max(2, Int((Double(baseInterval) * 0.12).rounded()))
        } else {
            span = max(4, Int((Double(baseInterval) * 0.15).rounded()))
        }
        
        // 确定性线性同余算法对齐 Java Random (LCG with seed)
        let combinedSeed = seed ^ (Int64(baseInterval) &* 1103515245 &+ 12345)
        var state = (combinedSeed ^ 0x5DEECE66D) & ((1 << 48) - 1)
        
        func nextBits(_ bits: Int) -> Int32 {
            state = (state &* 0x5DEECE66D &+ 0xB) & ((1 << 48) - 1)
            return Int32(state >> (48 - bits))
        }
        
        let bound = Int32(span * 2 + 1)
        let rInt: Int
        if (bound & (bound - 1)) == 0 {
            rInt = Int((Int64(bound) &* Int64(nextBits(31))) >> 31)
        } else {
            var bits = nextBits(31)
            var val = bits % bound
            while (bits - val + (bound - 1) < 0) {
                bits = nextBits(31)
                val = bits % bound
            }
            rInt = Int(val)
        }
        
        let delta = rInt - span
        return min(max(baseInterval + delta, 1), FsrsAlgorithm.maxInterval)
    }
}

// MARK: - SRS 计算器实现（带单调性截断约束 Hard <= Good <= Easy）

public final class SrsCalculatorImpl: Sendable {
    private let fsrs: FsrsAlgorithm
    
    public init(fsrs: FsrsAlgorithm = FsrsAlgorithm()) {
        self.fsrs = fsrs
    }
    
    public func calculate(item: SrsItem, quality: Int, today: Int, itemId: Int = 1) -> SrsUpdateResult {
        precondition(quality >= 0 && quality <= 5, "Quality must be between 0 and 5, got \(quality)")
        
        let rating: FsrsRating
        switch quality {
        case 0...2: rating = .again
        case 3: rating = .hard
        case 4: rating = .good
        default: rating = .easy
        }
        
        let currentState: MemoryState? = (item.stability > 0.0 && item.repetitionCount > 0)
            ? MemoryState(stability: item.stability, difficulty: item.difficulty)
            : nil
        
        let elapsedDays: Double
        if let last = item.lastReviewedDate, last > 0 {
            elapsedDays = max(0.0, Double(today - last))
        } else {
            elapsedDays = 0.0
        }
        
        let newState = fsrs.step(currentState: currentState, rating: rating, elapsedDays: elapsedDays)
        
        let newInterval: Int
        let newRepetitionCount: Int
        
        if quality < 3 {
            newRepetitionCount = item.repetitionCount
            newInterval = fsrs.nextIntervalDays(stability: newState.stability)
        } else {
            newRepetitionCount = item.repetitionCount + 1
            let seed = (Int64(itemId) << 32) ^ (Int64(today) << 8) ^ Int64(newRepetitionCount)
            
            let stateHard = (rating == .hard) ? newState : fsrs.step(currentState: currentState, rating: .hard, elapsedDays: elapsedDays)
            let stateGood = (rating == .good) ? newState : fsrs.step(currentState: currentState, rating: .good, elapsedDays: elapsedDays)
            let stateEasy = (rating == .easy) ? newState : fsrs.step(currentState: currentState, rating: .easy, elapsedDays: elapsedDays)
            
            let rawHard = fsrs.nextIntervalDays(stability: stateHard.stability)
            let rawGood = fsrs.nextIntervalDays(stability: stateGood.stability)
            let rawEasy = fsrs.nextIntervalDays(stability: stateEasy.stability)
            
            var fuzzedHard = fsrs.fuzzIntervalDays(baseInterval: rawHard, seed: seed)
            var fuzzedGood = fsrs.fuzzIntervalDays(baseInterval: rawGood, seed: seed)
            var fuzzedEasy = fsrs.fuzzIntervalDays(baseInterval: rawEasy, seed: seed)
            
            // 严格单调性截断约束: Hard <= Good <= Easy
            if fuzzedHard > fuzzedGood {
                fuzzedHard = fuzzedGood
            }
            if fuzzedEasy < fuzzedGood {
                fuzzedEasy = fuzzedGood
            }
            
            switch rating {
            case .hard: newInterval = fuzzedHard
            case .good: newInterval = fuzzedGood
            case .easy: newInterval = fuzzedEasy
            case .again: newInterval = fuzzedGood
            }
        }
        
        let nextReviewDate = (newRepetitionCount == 0 && quality < 3) ? 0 : (today + newInterval)
        let firstLearnedDate = (item.repetitionCount == 0 && quality >= 3) ? today : item.firstLearnedDate
        let lastReviewedDate = today
        
        let type: Int
        if newRepetitionCount > 0 && quality >= 3 {
            type = 2 // Review
        } else if quality < 3 && item.repetitionCount > 0 {
            type = 3 // Relearning
        } else if quality < 3 {
            type = 1 // Learning
        } else {
            type = item.type
        }
        
        return SrsUpdateResult(
            repetitionCount: newRepetitionCount,
            stability: newState.stability,
            difficulty: newState.difficulty,
            interval: newInterval,
            nextReviewDate: nextReviewDate,
            lastReviewedDate: lastReviewedDate,
            firstLearnedDate: firstLearnedDate,
            type: type
        )
    }
    
    public func predictNextIntervals(item: SrsItem, today: Int, itemId: Int = 1) -> [FsrsRating: String] {
        let ratings: [FsrsRating] = [.again, .hard, .good, .easy]
        var result: [FsrsRating: String] = [:]
        for r in ratings {
            let quality: Int
            switch r {
            case .again: quality = 1
            case .hard: quality = 3
            case .good: quality = 4
            case .easy: quality = 5
            }
            let res = calculate(item: item, quality: quality, today: today, itemId: itemId)
            if quality < 3 && item.repetitionCount == 0 {
                result[r] = "< 10m"
            } else if res.interval <= 1 {
                result[r] = "1d"
            } else if res.interval < 30 {
                result[r] = "\(res.interval)d"
            } else if res.interval < 365 {
                result[r] = "\(res.interval / 30)m"
            } else {
                result[r] = "\(res.interval / 365)y"
            }
        }
        return result
    }
}

// MARK: - 测试专用的沙盒持久化层与词库生成器

public actor MockDictionaryLocalStorage {
    private var inMemoryWords: [Word]?
    private let wordsFileURL: URL
    
    public init(sandbox: MockSandbox) {
        self.wordsFileURL = sandbox.fileURL(named: "words_cache.json")
    }
    
    public func saveWords(_ words: [Word]) throws {
        let data = try JSONEncoder().encode(words)
        try data.write(to: wordsFileURL, options: .atomic)
        self.inMemoryWords = words
    }
    
    public func preloadWordsIfNeeded() throws -> [Word] {
        if let memory = inMemoryWords, !memory.isEmpty {
            return memory
        }
        guard FileManager.default.fileExists(atPath: wordsFileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: wordsFileURL)
        let words = try JSONDecoder().decode([Word].self, from: data)
        self.inMemoryWords = words
        return words
    }
    
    public func getWords(by ids: Set<Int>) throws -> [Int: Word] {
        let all = try preloadWordsIfNeeded()
        let filtered = all.filter { ids.contains($0.id) }
        return Dictionary(uniqueKeysWithValues: filtered.map { ($0.id, $0) })
    }
    
    public func sampleNewWords(count: Int, excludingLearnedIds: Set<Int>, level: String? = nil) throws -> [Word] {
        let all = try preloadWordsIfNeeded()
        var candidates = all.filter { !excludingLearnedIds.contains($0.id) && !$0.isDelisted }
        if let level = level, level != "all" {
            candidates = candidates.filter { $0.level == level }
        }
        return Array(candidates.prefix(count))
    }
}

public actor MockLearningLocalStorage {
    private let statesFileURL: URL
    private let dailyRecordsFileURL: URL
    private var statesCache: [Int: WordStudyState] = [:]
    private var dailyRecordsCache: [Int: StudyDailyRecord] = [:]
    private var isLoaded: Bool = false
    
    public init(sandbox: MockSandbox) {
        self.statesFileURL = sandbox.fileURL(named: "study_states.json")
        self.dailyRecordsFileURL = sandbox.fileURL(named: "daily_records.json")
    }
    
    private func loadIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true
        if let data = try? Data(contentsOf: statesFileURL),
           let states = try? JSONDecoder().decode([WordStudyState].self, from: data) {
            for state in states {
                statesCache[state.wordId] = state
            }
        }
        if let data = try? Data(contentsOf: dailyRecordsFileURL),
           let records = try? JSONDecoder().decode([StudyDailyRecord].self, from: data) {
            for record in records {
                dailyRecordsCache[record.date] = record
            }
        }
    }
    
    private func flushStates() throws {
        let array = Array(statesCache.values)
        let data = try JSONEncoder().encode(array)
        try data.write(to: statesFileURL, options: .atomic)
    }
    
    private func flushRecords() throws {
        let array = Array(dailyRecordsCache.values)
        let data = try JSONEncoder().encode(array)
        try data.write(to: dailyRecordsFileURL, options: .atomic)
    }
    
    public func getStudyState(wordId: Int) throws -> WordStudyState? {
        loadIfNeeded()
        return statesCache[wordId]
    }
    
    public func getAllStudyStates() throws -> [Int: WordStudyState] {
        loadIfNeeded()
        return statesCache
    }
    
    public func saveStudyState(_ state: WordStudyState) throws {
        loadIfNeeded()
        statesCache[state.wordId] = state
        try flushStates()
    }
    
    public func saveStudyStates(_ states: [WordStudyState]) throws {
        loadIfNeeded()
        for s in states {
            statesCache[s.wordId] = s
        }
        try flushStates()
    }
    
    public func recordDailyStudy(learnedIncrement: Int, reviewedIncrement: Int, date: Int) throws {
        loadIfNeeded()
        var record = dailyRecordsCache[date] ?? StudyDailyRecord(date: date)
        record.learnedCount += learnedIncrement
        record.reviewedCount += reviewedIncrement
        dailyRecordsCache[date] = record
        try flushRecords()
    }
    
    public func getTodayRecord(today: Int) -> StudyDailyRecord? {
        loadIfNeeded()
        return dailyRecordsCache[today]
    }
    
    public func calculateCurrentStreak(today: Int) -> Int {
        loadIfNeeded()
        var streak = 0
        var checkDay = today
        
        // 如果今天尚未打卡，查看昨天是否打卡（宽限期）
        if let todayRecord = dailyRecordsCache[today], todayRecord.totalCount > 0 {
            streak += 1
            checkDay -= 1
        } else if let yesterdayRecord = dailyRecordsCache[today - 1], yesterdayRecord.totalCount > 0 {
            checkDay = today - 1
        } else {
            return 0
        }
        
        while let rec = dailyRecordsCache[checkDay], rec.totalCount > 0 {
            streak += 1
            checkDay -= 1
        }
        return streak
    }
}

// MARK: - 卡片切片策略与会话模型

public enum CardPriority: Int, Comparable, Sendable {
    case p0Emergency = 0   // 回忆率 0.6 <= R < 0.9，升序排
    case p1Overdue = 1     // R < 0.6 深度逾期
    case p2Due = 2         // R >= 0.9 常规到期
    
    public static func < (lhs: CardPriority, rhs: CardPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct PrioritizedReviewCard: Sendable {
    public let state: WordStudyState
    public let priority: CardPriority
    public let retrievability: Double
}

public struct LearningSessionPolicy: Sendable {
    public static let defaultNewQuota: Int = 15
    public static let maxReviewDamping: Int = 40
    
    public static func sliceReviewCards(states: [WordStudyState], today: Int, algorithm: FsrsAlgorithm = FsrsAlgorithm()) -> [PrioritizedReviewCard] {
        let dueStates = states.filter { $0.repetitionCount > 0 && $0.nextReviewDate <= today }
        var result: [PrioritizedReviewCard] = []
        
        for st in dueStates {
            let elapsed = max(1.0, Double(today - (st.lastReviewedDate ?? (today - st.interval))))
            let r = algorithm.forgettingCurve(elapsedDays: elapsed, stability: max(st.stability, 0.01))
            let prio: CardPriority
            if r >= 0.6 && r < 0.9 {
                prio = .p0Emergency
            } else if r < 0.6 {
                prio = .p1Overdue
            } else {
                prio = .p2Due
            }
            result.append(PrioritizedReviewCard(state: st, priority: prio, retrievability: r))
        }
        
        // 排序规则:
        // P0: 回忆率升序 (最危险的先复习)
        // P1: 回忆率升序 (严重逾期)
        // P2: FIFO 逾期天数
        let p0 = result.filter { $0.priority == .p0Emergency }.sorted { $0.retrievability < $1.retrievability }
        let p1 = result.filter { $0.priority == .p1Overdue }.sorted { $0.retrievability < $1.retrievability }
        let p2 = result.filter { $0.priority == .p2Due }.sorted { $0.state.nextReviewDate < $1.state.nextReviewDate }
        
        let combined = p0 + p1 + p2
        return Array(combined.prefix(maxReviewDamping))
    }
    
    public static func sandwichMix(p0Cards: [Word], reviewCards: [Word], newCards: [Word]) -> [Word] {
        var queue: [Word] = []
        queue.append(contentsOf: p0Cards)
        
        if reviewCards.isEmpty {
            queue.append(contentsOf: newCards)
            return queue
        }
        if newCards.isEmpty {
            queue.append(contentsOf: reviewCards)
            return queue
        }
        
        var revIdx = 0
        var newIdx = 0
        let step = max(1, reviewCards.count / max(1, newCards.count))
        
        while revIdx < reviewCards.count || newIdx < newCards.count {
            for _ in 0..<step {
                if revIdx < reviewCards.count {
                    queue.append(reviewCards[revIdx])
                    revIdx += 1
                }
            }
            if newIdx < newCards.count {
                queue.append(newCards[newIdx])
                newIdx += 1
            }
        }
        return queue
    }
}

// MARK: - 9,876 虚拟词库生成工具

public struct TestDataGenerator {
    public static func generate9876Dictionary() -> [Word] {
        var words: [Word] = []
        words.reserveCapacity(9876)
        
        let levels = ["N5", "N4", "N3", "N2", "N1"]
        let counts = [800, 1200, 1800, 2500, 3576] // 总计 9876
        
        var currentId = 1
        for (idx, lvl) in levels.enumerated() {
            let count = counts[idx]
            for i in 1...count {
                let isDelisted = (currentId % 200 == 0) // 每 200 个词包含一个已下架测试词
                let word = Word(
                    id: currentId,
                    rawId: "word_\(currentId)",
                    japanese: "単語_\(lvl)_\(i)",
                    hiragana: "たんご_\(i)",
                    chinese: "词条释义 \(lvl)-\(i)",
                    level: lvl,
                    pos: (i % 2 == 0) ? "名" : "動",
                    example1: "これは単語\(i)の例文です。",
                    gloss1: "这是词条\(i)的例句。",
                    isDelisted: isDelisted
                )
                words.append(word)
                currentId += 1
            }
        }
        return words
    }
}
