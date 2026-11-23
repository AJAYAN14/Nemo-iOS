import Foundation

/// 基于 FSRS 6 的业务级 SRS 计算器实现
public final class SrsCalculatorImpl: SrsCalculatorProtocol, Sendable {
    public let fsrs: FsrsAlgorithm

    public init(fsrs: FsrsAlgorithm = FsrsAlgorithm()) {
        self.fsrs = fsrs
    }

    public convenience init(
        parameters: [Double] = FsrsAlgorithm.defaultParameters,
        desiredRetention: Double = 0.9
    ) {
        let algo = FsrsAlgorithm(parameters: parameters, desiredRetention: desiredRetention)
        self.init(fsrs: algo)
    }

    // MARK: - 评分映射

    public func mapQualityToRating(_ quality: Int) -> FsrsRating {
        switch quality {
        case ..<3:
            return .again
        case 3:
            return .hard
        case 4:
            return .good
        default:
            return .easy
        }
    }

    public func mapQualityToRating(_ quality: SRSRatingQuality) -> FsrsRating {
        switch quality {
        case .again:
            return .again
        case .hard:
            return .hard
        case .good:
            return .good
        case .easy:
            return .easy
        }
    }

    // MARK: - 种子构建

    private func buildFuzzSeed(itemId: Int, today: Int, repetitions: Int) -> Int64 {
        let uItemId = UInt64(truncatingIfNeeded: itemId)
        let uToday = UInt64(truncatingIfNeeded: today)
        let uReps = UInt64(truncatingIfNeeded: repetitions)
        let seed = (uItemId &* 1103515245) ^ (uToday << 8) ^ uReps
        return Int64(bitPattern: seed)
    }

    // MARK: - 核心计算

    public func calculate(
        item: SrsItem,
        quality: Int,
        today: Int,
        itemId: Int
    ) -> SrsUpdateResult {
        precondition(quality >= 0 && quality <= 5, "Quality must be between 0 and 5, got \(quality)")

        let rating = mapQualityToRating(quality)

        let currentState: MemoryState?
        if item.stability > 0.0 && item.repetitionCount > 0 {
            currentState = MemoryState(stability: item.stability, difficulty: item.difficulty)
        } else {
            currentState = nil
        }

        let elapsedDays: Double
        if let lastReviewed = item.lastReviewedDate, lastReviewed > 0 {
            elapsedDays = max(Double(today - lastReviewed), 0.0)
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
            let seed = buildFuzzSeed(itemId: itemId, today: today, repetitions: newRepetitionCount)

            let stateHard = (rating == .hard) ? newState : fsrs.step(currentState: currentState, rating: .hard, elapsedDays: elapsedDays)
            let stateGood = (rating == .good) ? newState : fsrs.step(currentState: currentState, rating: .good, elapsedDays: elapsedDays)
            let stateEasy = (rating == .easy) ? newState : fsrs.step(currentState: currentState, rating: .easy, elapsedDays: elapsedDays)

            let rawHard = fsrs.nextIntervalDays(stability: stateHard.stability)
            let rawGood = fsrs.nextIntervalDays(stability: stateGood.stability)
            let rawEasy = fsrs.nextIntervalDays(stability: stateEasy.stability)

            var fuzzedHard = fsrs.fuzzIntervalDays(baseInterval: rawHard, seed: seed)
            let fuzzedGood = fsrs.fuzzIntervalDays(baseInterval: rawGood, seed: seed)
            var fuzzedEasy = fsrs.fuzzIntervalDays(baseInterval: rawEasy, seed: seed)

            if fuzzedHard > fuzzedGood {
                fuzzedHard = fuzzedGood
            }
            if fuzzedEasy < fuzzedGood {
                fuzzedEasy = fuzzedGood
            }

            switch rating {
            case .hard:
                newInterval = fuzzedHard
            case .good:
                newInterval = fuzzedGood
            case .easy:
                newInterval = fuzzedEasy
            case .again:
                newInterval = fuzzedGood
            }
        }

        let nextReviewDate: Int
        if newRepetitionCount == 0 && quality < 3 {
            nextReviewDate = 0
        } else {
            nextReviewDate = today + newInterval
        }

        let firstLearnedDate: Int?
        if item.repetitionCount == 0 && quality >= 3 {
            firstLearnedDate = today
        } else {
            firstLearnedDate = item.firstLearnedDate
        }

        let lastReviewedDate: Int? = today

        let type: Int
        if newRepetitionCount > 0 && quality >= 3 {
            type = SrsItemType.review.rawValue
        } else if quality < 3 && item.repetitionCount > 0 {
            type = SrsItemType.relearning.rawValue
        } else if quality < 3 {
            type = SrsItemType.learning.rawValue
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

    public func calculate(
        item: SrsItem,
        ratingQuality: SRSRatingQuality,
        today: Int,
        itemId: Int
    ) -> SrsUpdateResult {
        calculate(item: item, quality: ratingQuality.rawValue, today: today, itemId: itemId)
    }

    // MARK: - 预测展示

    public func predictNextIntervals(
        item: SrsItem,
        today: Int,
        itemId: Int
    ) -> [SRSRatingQuality: String] {
        let rawDict = predictNextIntervalsRaw(item: item, today: today, itemId: itemId)
        var result: [SRSRatingQuality: String] = [:]
        for quality in SRSRatingQuality.allCases {
            if let str = rawDict[quality.rawValue] {
                result[quality] = str
            }
        }
        return result
    }

    public func predictNextIntervalsRaw(
        item: SrsItem,
        today: Int,
        itemId: Int
    ) -> [Int: String] {
        let currentState: MemoryState?
        if item.stability > 0.0 && item.repetitionCount > 0 {
            currentState = MemoryState(stability: item.stability, difficulty: item.difficulty)
        } else {
            currentState = nil
        }

        let elapsedDays: Double
        if let lastReviewed = item.lastReviewedDate, lastReviewed > 0 {
            elapsedDays = max(Double(today - lastReviewed), 0.0)
        } else {
            elapsedDays = 0.0
        }

        // Again 分支
        let againStr: String
        if item.repetitionCount == 0 {
            againStr = "< 1m"
        } else {
            let stateAgain = fsrs.step(currentState: currentState, rating: .again, elapsedDays: elapsedDays)
            let intAgain = fsrs.nextIntervalDays(stability: stateAgain.stability)
            againStr = SrsTimeFormatter.formatInterval(days: intAgain)
        }

        // Hard / Good / Easy 联合推演与截断
        let simulatedReps = item.repetitionCount + 1
        let seed = buildFuzzSeed(itemId: itemId, today: today, repetitions: simulatedReps)

        let stateHard = fsrs.step(currentState: currentState, rating: .hard, elapsedDays: elapsedDays)
        let stateGood = fsrs.step(currentState: currentState, rating: .good, elapsedDays: elapsedDays)
        let stateEasy = fsrs.step(currentState: currentState, rating: .easy, elapsedDays: elapsedDays)

        let rawHard = fsrs.nextIntervalDays(stability: stateHard.stability)
        let rawGood = fsrs.nextIntervalDays(stability: stateGood.stability)
        let rawEasy = fsrs.nextIntervalDays(stability: stateEasy.stability)

        var fuzzedHard = fsrs.fuzzIntervalDays(baseInterval: rawHard, seed: seed)
        let fuzzedGood = fsrs.fuzzIntervalDays(baseInterval: rawGood, seed: seed)
        var fuzzedEasy = fsrs.fuzzIntervalDays(baseInterval: rawEasy, seed: seed)

        if fuzzedHard > fuzzedGood {
            fuzzedHard = fuzzedGood
        }
        if fuzzedEasy < fuzzedGood {
            fuzzedEasy = fuzzedGood
        }

        return [
            SRSRatingQuality.again.rawValue: againStr,
            SRSRatingQuality.hard.rawValue: SrsTimeFormatter.formatInterval(days: fuzzedHard),
            SRSRatingQuality.good.rawValue: SrsTimeFormatter.formatInterval(days: fuzzedGood),
            SRSRatingQuality.easy.rawValue: SrsTimeFormatter.formatInterval(days: fuzzedEasy)
        ]
    }

    public func forgettingCurve(elapsedDays: Double, stability: Double) -> Double {
        fsrs.forgettingCurve(elapsedDays: elapsedDays, stability: stability)
    }

    public func nextInterval(stability: Double, retention: Double? = nil) -> Double {
        fsrs.nextInterval(stability: stability, retention: retention)
    }

    public func nextIntervalDays(stability: Double) -> Int {
        fsrs.nextIntervalDays(stability: stability)
    }
}
