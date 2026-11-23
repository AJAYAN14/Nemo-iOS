import Foundation

/// 确定性 48-bit 线性同余随机数发生器（对齐 java.util.Random）
public struct JavaRandom: Sendable {
    private var seed: UInt64
    private static let multiplier: UInt64 = 0x5DEECE66D // 25214903917
    private static let addend: UInt64 = 0xB            // 11
    private static let mask: UInt64 = (1 << 48) - 1    // 281474976710655

    public init(seed: Int64) {
        self.seed = (UInt64(bitPattern: seed) ^ Self.multiplier) & Self.mask
    }

    private mutating func next(bits: Int) -> Int32 {
        seed = (seed &* Self.multiplier &+ Self.addend) & Self.mask
        return Int32(truncatingIfNeeded: seed >> (48 - bits))
    }

    public mutating func nextInt(_ bound: Int) -> Int {
        precondition(bound > 0, "bound must be positive")
        if (bound & (bound - 1)) == 0 {
            return Int((Int64(bound) &* Int64(next(bits: 31))) >> 31)
        }
        var u = next(bits: 31)
        var r = u % Int32(bound)
        while (u - r &+ Int32(bound - 1)) < 0 {
            u = next(bits: 31)
            r = u % Int32(bound)
        }
        return Int(r)
    }
}

/// FSRS 6 记忆算法核心引擎（纯 Swift 原生无外部依赖）
public final class FsrsAlgorithm: Sendable {
    /// FSRS 6 官方 21 个参数默认值
    public static let defaultParameters: [Double] = [
        0.212,     // w[0]: init_stability for Again (G=1)
        1.2931,    // w[1]: init_stability for Hard (G=2)
        2.3065,    // w[2]: init_stability for Good (G=3)
        8.2956,    // w[3]: init_stability for Easy (G=4)
        6.4133,    // w[4]: init_difficulty base
        0.8334,    // w[5]: init_difficulty rating factor
        3.0194,    // w[6]: next_difficulty delta factor
        0.001,     // w[7]: mean_reversion weight
        1.8722,    // w[8]: stability_after_success exp base
        0.1666,    // w[9]: stability_after_success stability power
        0.796,     // w[10]: stability_after_success retrievability factor
        1.4835,    // w[11]: stability_after_failure base
        0.0614,    // w[12]: stability_after_failure difficulty power
        0.2629,    // w[13]: stability_after_failure stability power
        1.6483,    // w[14]: stability_after_failure retrievability factor
        0.6014,    // w[15]: hard_penalty
        1.8729,    // w[16]: easy_bonus
        0.5425,    // w[17]: short_term factor
        0.0912,    // w[18]: short_term rating offset
        0.0658,    // w[19]: short_term stability power
        0.1542     // w[20]: decay (FSRS 6 遗忘衰减指数)
    ]

    public static let sMin: Double = 0.01
    public static let sMax: Double = 36500.0
    public static let dMin: Double = 1.0
    public static let dMax: Double = 10.0
    public static let maxInterval: Int = 36500

    public let parameters: [Double]
    public let desiredRetention: Double

    public init(
        parameters: [Double] = defaultParameters,
        desiredRetention: Double = 0.9
    ) {
        self.parameters = parameters
        self.desiredRetention = desiredRetention
    }

    private var w: [Double] {
        parameters
    }

    // MARK: - 核心数学公式

    /// 幂律遗忘曲线计算记忆留存概率 R(t, S)
    public func forgettingCurve(elapsedDays: Double, stability: Double) -> Double {
        let decay = w[20]
        let factor = pow(0.9, 1.0 / -decay) - 1.0
        return pow(elapsedDays / stability * factor + 1.0, -decay)
    }

    /// 最优复习间隔计算 I(S, R)
    public func nextInterval(stability: Double, retention: Double? = nil) -> Double {
        let s = min(max(stability, Self.sMin), Self.sMax)
        let r = min(max(retention ?? desiredRetention, 0.01), 0.999)
        let decay = w[20]
        let factor = pow(0.9, 1.0 / -decay) - 1.0
        return s / factor * (pow(r, 1.0 / -decay) - 1.0)
    }

    /// 最优复习天数（取整并截断在 [1, 36500] 天）
    public func nextIntervalDays(stability: Double, retention: Double? = nil) -> Int {
        let raw = nextInterval(stability: stability, retention: retention)
        let rounded = Int(raw.rounded())
        return min(max(rounded, 1), Self.maxInterval)
    }

    /// 初学初始稳定性 S0(G)
    public func initStability(rating: FsrsRating) -> Double {
        let val = w[rating.rawValue - 1]
        return min(max(val, Self.sMin), Self.sMax)
    }

    /// 初学初始难度 D0(G)
    public func initDifficulty(rating: FsrsRating) -> Double {
        let val = w[4] - exp(w[5] * Double(rating.rawValue - 1)) + 1.0
        return min(max(val, Self.dMin), Self.dMax)
    }

    /// 跨天复习成功稳定性更新 S'r(D, S, R, G)
    public func stabilityAfterSuccess(
        stability: Double,
        difficulty: Double,
        retrievability: Double,
        rating: FsrsRating
    ) -> Double {
        let s = min(max(stability, Self.sMin), Self.sMax)
        let d = min(max(difficulty, Self.dMin), Self.dMax)
        let r = min(max(retrievability, 0.0), 1.0)
        let hardPenalty = (rating == .hard) ? w[15] : 1.0
        let easyBonus = (rating == .easy) ? w[16] : 1.0
        let newS = s * (
            exp(w[8]) *
            (11.0 - d) *
            pow(s, -w[9]) *
            (exp((1.0 - r) * w[10]) - 1.0) *
            hardPenalty *
            easyBonus + 1.0
        )
        return min(max(newS, Self.sMin), Self.sMax)
    }

    /// 跨天复习失败稳定性更新 S'f(D, S, R)（包含官方上限截断）
    public func stabilityAfterFailure(
        stability: Double,
        difficulty: Double,
        retrievability: Double
    ) -> Double {
        let s = min(max(stability, Self.sMin), Self.sMax)
        let d = min(max(difficulty, Self.dMin), Self.dMax)
        let r = min(max(retrievability, 0.0), 1.0)
        let newS = w[11] *
            pow(d, -w[12]) *
            (pow(s + 1.0, w[13]) - 1.0) *
            exp((1.0 - r) * w[14])
        let maxS = s / exp(w[17] * w[18])
        return min(max(min(newS, maxS), Self.sMin), Self.sMax)
    }

    /// 当天短期复习稳定性计算
    public func stabilityShortTerm(stability: Double, rating: FsrsRating) -> Double {
        let sinc = exp(w[17] * (Double(rating.rawValue - 3) + w[18])) * pow(stability, -w[19])
        let clampedSinc = (rating.rawValue >= 3) ? max(sinc, 1.0) : sinc
        return min(max(stability * clampedSinc, Self.sMin), Self.sMax)
    }

    /// 材料难度演变计算与均值回归
    public func nextDifficulty(difficulty: Double, rating: FsrsRating) -> Double {
        let deltaD = -w[6] * Double(rating.rawValue - 3)
        let linearDamped = deltaD * (10.0 - difficulty) / 9.0
        let newD = difficulty + linearDamped

        let d0Good = w[4] - exp(w[5] * 3.0) + 1.0
        let reverted = w[7] * (d0Good - newD) + newD
        return min(max(reverted, Self.dMin), Self.dMax)
    }

    // MARK: - 高级状态演化 API

    /// 单步状态转换
    public func step(
        currentState: MemoryState?,
        rating: FsrsRating,
        elapsedDays: Double
    ) -> MemoryState {
        if currentState == nil || currentState?.stability == 0.0 {
            return MemoryState(
                stability: initStability(rating: rating),
                difficulty: initDifficulty(rating: rating)
            )
        }

        let s = min(max(currentState?.stability ?? Self.sMin, Self.sMin), Self.sMax)
        let d = min(max(currentState?.difficulty ?? Self.dMin, Self.dMin), Self.dMax)

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
            stability: min(max(newS, Self.sMin), Self.sMax),
            difficulty: min(max(newD, Self.dMin), Self.dMax)
        )
    }

    /// 四档按钮下一状态预览
    public func nextStates(
        currentState: MemoryState?,
        elapsedDays: Double
    ) -> NextStates {
        let ratings: [FsrsRating] = [.again, .hard, .good, .easy]
        let itemStates = ratings.map { rating -> FsrsItemState in
            let newState = step(currentState: currentState, rating: rating, elapsedDays: elapsedDays)
            let interval = nextInterval(stability: newState.stability)
            return FsrsItemState(memory: newState, interval: interval)
        }
        return NextStates(
            again: itemStates[0],
            hard: itemStates[1],
            good: itemStates[2],
            easy: itemStates[3]
        )
    }

    // MARK: - 确定性 Fuzz 抖动

    /// 确定性间隔抖动（小间隔保底不抖动）
    public func fuzzIntervalDays(baseInterval: Int, seed: Int64) -> Int {
        if baseInterval < 3 {
            return baseInterval
        }

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

        let mixedSeed = seed ^ (Int64(baseInterval) &* 1103515245 &+ 12345)
        var random = JavaRandom(seed: mixedSeed)
        let delta = random.nextInt(span * 2 + 1) - span
        return min(max(baseInterval + delta, 1), Self.maxInterval)
    }

    /// 计算带确定性抖动的实际复习间隔天数
    public func nextIntervalDaysWithFuzz(stability: Double, seed: Int64) -> Int {
        let base = nextIntervalDays(stability: stability)
        return fuzzIntervalDays(baseInterval: base, seed: seed)
    }
}
