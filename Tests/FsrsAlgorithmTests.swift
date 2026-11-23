import Foundation
#if canImport(XCTest)
import XCTest
#endif

#if TESTING_CLI
public enum SRSRatingQuality: Int, CaseIterable, Sendable {
    case again = 1
    case hard = 3
    case good = 4
    case easy = 5
}
#endif

/// 用于单元测试的轻量 SrsItem 实现
public struct TestSrsItem: SrsItem, Sendable {
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
        lastReviewedDate: Int? = nil,
        firstLearnedDate: Int? = nil,
        type: Int = 0
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

/// FSRS 6 算法核心与单调性测试套件
public final class FsrsAlgorithmTestSuite: Sendable {
    public let calculator: SrsCalculatorImpl
    public let fsrs: FsrsAlgorithm

    public init() {
        self.calculator = SrsCalculatorImpl()
        self.fsrs = calculator.fsrs
    }

    private func createNewItem() -> TestSrsItem {
        TestSrsItem(
            repetitionCount: 0,
            stability: 0.0,
            difficulty: 0.0,
            interval: 0,
            nextReviewDate: 0,
            lastReviewedDate: nil,
            firstLearnedDate: nil,
            type: 0
        )
    }

    private func createItemWithRepetition(
        repetitionCount: Int,
        stability: Double,
        difficulty: Double,
        interval: Int = 1,
        nextReviewDate: Int = 100,
        lastReviewedDate: Int = 90
    ) -> TestSrsItem {
        TestSrsItem(
            repetitionCount: repetitionCount,
            stability: stability,
            difficulty: difficulty,
            interval: interval,
            nextReviewDate: nextReviewDate,
            lastReviewedDate: lastReviewedDate,
            firstLearnedDate: 80,
            type: 2
        )
    }

    // MARK: - 11 项核心单测用例

    /// 1. 首次学习 质量4(Good) 应该毕业并设置间隔
    public func testFirstLearnGoodGraduation() throws {
        let item = createNewItem()
        let result = calculator.calculate(item: item, quality: 4, today: 100, itemId: 1)

        guard result.repetitionCount == 1 else {
            throw TestError("repetitionCount 期望 1，实际: \(result.repetitionCount)")
        }
        guard result.interval > 0 else {
            throw TestError("interval 期望 > 0，实际: \(result.interval)")
        }
        guard result.nextReviewDate == 100 + result.interval else {
            throw TestError("nextReviewDate 期望 \(100 + result.interval)，实际: \(result.nextReviewDate)")
        }
        guard result.stability > 0.0 else {
            throw TestError("stability 期望 > 0，实际: \(result.stability)")
        }
        guard result.difficulty > 0.0 else {
            throw TestError("difficulty 期望 > 0，实际: \(result.difficulty)")
        }
        guard result.type == 2 else {
            throw TestError("type 期望 2 (Review)，实际: \(result.type)")
        }
    }

    /// 2. 首次学习 质量5(Easy) 应该给更长的间隔
    public func testFirstLearnEasyHigherInterval() throws {
        let item1 = createNewItem()
        let item2 = createNewItem()

        let resultGood = calculator.calculate(item: item1, quality: 4, today: 100, itemId: 1)
        let resultEasy = calculator.calculate(item: item2, quality: 5, today: 100, itemId: 1)

        guard resultEasy.interval > resultGood.interval else {
            throw TestError("Easy interval (\(resultEasy.interval)) 期望 > Good interval (\(resultGood.interval))")
        }
        guard resultEasy.stability > resultGood.stability else {
            throw TestError("Easy stability (\(resultEasy.stability)) 期望 > Good stability (\(resultGood.stability))")
        }
    }

    /// 3. 首次学习 质量2(Again) 应该失败且重复次数不增加
    public func testFirstLearnAgainFailure() throws {
        let item = createNewItem()
        let result = calculator.calculate(item: item, quality: 2, today: 100, itemId: 1)

        guard result.repetitionCount == 0 else {
            throw TestError("repetitionCount 期望 0，实际: \(result.repetitionCount)")
        }
        guard result.nextReviewDate == 0 else {
            throw TestError("新卡失败 nextReviewDate 期望 0，实际: \(result.nextReviewDate)")
        }
        guard result.stability > 0.0 else {
            throw TestError("stability 期望 > 0，实际: \(result.stability)")
        }
        guard result.type == 1 else {
            throw TestError("type 期望 1 (Learning)，实际: \(result.type)")
        }
    }

    /// 4. 复习阶段_质量4_间隔应该增加
    public func testReviewGoodIntervalIncrease() throws {
        let item = createItemWithRepetition(
            repetitionCount: 1,
            stability: 3.0,
            difficulty: 5.0,
            interval: 3,
            nextReviewDate: 100,
            lastReviewedDate: 90
        )

        let result = calculator.calculate(item: item, quality: 4, today: 100, itemId: 1)

        guard result.repetitionCount == 2 else {
            throw TestError("repetitionCount 期望 2，实际: \(result.repetitionCount)")
        }
        guard result.interval > 3 else {
            throw TestError("New interval (\(result.interval)) 期望 > 3")
        }
        guard result.stability > 3.0 else {
            throw TestError("Stability (\(result.stability)) 期望 > 3.0")
        }
        guard result.type == 2 else {
            throw TestError("type 期望 2 (Review)，实际: \(result.type)")
        }
    }

    /// 5. 复习阶段_质量2忘记_应该重新适应
    public func testReviewAgainLapseRelearning() throws {
        let item = createItemWithRepetition(
            repetitionCount: 3,
            stability: 10.0,
            difficulty: 5.0,
            interval: 10,
            nextReviewDate: 100,
            lastReviewedDate: 90
        )

        let result = calculator.calculate(item: item, quality: 2, today: 100, itemId: 1)

        guard result.repetitionCount == 3 else {
            throw TestError("repetitionCount 期望 3，实际: \(result.repetitionCount)")
        }
        guard result.nextReviewDate == 100 + result.interval else {
            throw TestError("nextReviewDate 期望 \(100 + result.interval)，实际: \(result.nextReviewDate)")
        }
        guard result.interval > 0 else {
            throw TestError("interval 期望 > 0，实际: \(result.interval)")
        }
        guard result.stability > 0.0 else {
            throw TestError("stability 期望 > 0，实际: \(result.stability)")
        }
        guard result.type == 3 else {
            throw TestError("type 期望 3 (Relearning)，实际: \(result.type)")
        }
    }

    /// 6. 高稳定性卡片忘记时稳定性应该发生断崖式跌落
    public func testHighStabilityDropCliff() throws {
        let highStabilityItem = createItemWithRepetition(
            repetitionCount: 5,
            stability: 60.0,
            difficulty: 4.0,
            interval: 60,
            nextReviewDate: 100,
            lastReviewedDate: 40
        )

        let result = calculator.calculate(item: highStabilityItem, quality: 2, today: 100, itemId: 1)

        guard result.stability < 15.0 else {
            throw TestError("高熟练度卡片遗忘后 stability (\(result.stability)) 期望 < 15.0")
        }
        guard result.interval <= 7 else {
            throw TestError("高熟练度卡片遗忘后 interval (\(result.interval)) 期望 <= 7")
        }
    }

    /// 7. 延迟且记得(Q=4) 应该给予稳定性奖励
    public func testDelayedReviewBoostStability() throws {
        let itemDelayed = createItemWithRepetition(
            repetitionCount: 4,
            stability: 10.0,
            difficulty: 5.0,
            interval: 10,
            nextReviewDate: 90,
            lastReviewedDate: 80
        )

        let itemOnTime = createItemWithRepetition(
            repetitionCount: 4,
            stability: 10.0,
            difficulty: 5.0,
            interval: 10,
            nextReviewDate: 100,
            lastReviewedDate: 90
        )

        let resultDelayed = calculator.calculate(item: itemDelayed, quality: 4, today: 100, itemId: 1)
        let resultOnTime = calculator.calculate(item: itemOnTime, quality: 4, today: 100, itemId: 1)

        guard resultDelayed.stability > resultOnTime.stability else {
            throw TestError("延迟复习稳定性 (\(resultDelayed.stability)) 期望 > 准时复习稳定性 (\(resultOnTime.stability))")
        }
    }

    /// 8. 较高保留率设置应该产生更短或等于较低保留率的复习间隔
    public func testRetentionSettingImpact() throws {
        let highCalc = SrsCalculatorImpl(desiredRetention: 0.95)
        let lowCalc = SrsCalculatorImpl(desiredRetention: 0.75)

        let item = createItemWithRepetition(
            repetitionCount: 3,
            stability: 20.0,
            difficulty: 5.0,
            interval: 20,
            lastReviewedDate: 80
        )

        let highResult = highCalc.calculate(item: item, quality: 4, today: 100, itemId: 1)
        let lowResult = lowCalc.calculate(item: item, quality: 4, today: 100, itemId: 1)

        guard highResult.interval <= lowResult.interval else {
            throw TestError("高保留率间隔 (\(highResult.interval)) 期望 <= 低保留率间隔 (\(lowResult.interval))")
        }
    }

    /// 9. 复习阶段_困难间隔必须小于等于良好间隔且良好必须小于等于简单
    public func testMonotonicityGuarantee() throws {
        let item = createItemWithRepetition(
            repetitionCount: 2,
            stability: 3.5,
            difficulty: 6.0,
            interval: 3,
            nextReviewDate: 100,
            lastReviewedDate: 96
        )

        let hardResult = calculator.calculate(item: item, quality: 3, today: 100, itemId: 1)
        let goodResult = calculator.calculate(item: item, quality: 4, today: 100, itemId: 1)
        let easyResult = calculator.calculate(item: item, quality: 5, today: 100, itemId: 1)

        guard hardResult.interval <= goodResult.interval else {
            throw TestError("Hard (\(hardResult.interval)) 期望 <= Good (\(goodResult.interval))")
        }
        guard goodResult.interval <= easyResult.interval else {
            throw TestError("Good (\(goodResult.interval)) 期望 <= Easy (\(easyResult.interval))")
        }
    }

    /// 10. 大规模随机卡片与时间序列下_复习间隔必须恒保持单调递增性
    public func testMonotonicityUnderExtensiveGrid() throws {
        let stabilities: [Double] = [1.5, 2.5, 3.8, 4.2, 7.0, 15.0]
        for elapsed in 1...20 {
            for stab in stabilities {
                let item = createItemWithRepetition(
                    repetitionCount: 2,
                    stability: stab,
                    difficulty: 5.0,
                    interval: max(Int(stab), 1),
                    nextReviewDate: 100,
                    lastReviewedDate: 100 - elapsed
                )

                let hardResult = calculator.calculate(item: item, quality: 3, today: 100, itemId: 1)
                let goodResult = calculator.calculate(item: item, quality: 4, today: 100, itemId: 1)
                let easyResult = calculator.calculate(item: item, quality: 5, today: 100, itemId: 1)

                guard hardResult.interval <= goodResult.interval else {
                    throw TestError("在 stab=\(stab), elapsed=\(elapsed) 时，Hard (\(hardResult.interval)) > Good (\(goodResult.interval)) 发生倒挂！")
                }
                guard goodResult.interval <= easyResult.interval else {
                    throw TestError("在 stab=\(stab), elapsed=\(elapsed) 时，Good (\(goodResult.interval)) > Easy (\(easyResult.interval)) 发生倒挂！")
                }
            }
        }
    }

    /// 11. Fuzz 确定性与边界断言
    public func testFuzzDeterminismAndBounds() throws {
        // 1. 同种子确定性
        let base1 = 30
        let seed1: Int64 = 123456
        let a = fsrs.fuzzIntervalDays(baseInterval: base1, seed: seed1)
        let b = fsrs.fuzzIntervalDays(baseInterval: base1, seed: seed1)
        guard a == b else {
            throw TestError("相同种子期望产生一致结果，实际 a=\(a), b=\(b)")
        }

        // 2. 合理抖动区间
        let base2 = 60
        let seed2: Int64 = 42
        let fuzzed = fsrs.fuzzIntervalDays(baseInterval: base2, seed: seed2)
        guard fuzzed >= 1 && fuzzed <= FsrsAlgorithm.maxInterval else {
            throw TestError("fuzzed (\(fuzzed)) 超出 [1, maxInterval] 范围")
        }
        guard (51...69).contains(fuzzed) else {
            throw TestError("fuzzed (\(fuzzed)) 超出期望区间 51...69")
        }

        // 3. 小间隔零抖动保底
        let f1 = fsrs.fuzzIntervalDays(baseInterval: 1, seed: 1)
        let f2 = fsrs.fuzzIntervalDays(baseInterval: 2, seed: 2)
        guard f1 == 1 else {
            throw TestError("base=1 期望抖动后为 1，实际: \(f1)")
        }
        guard f2 == 2 else {
            throw TestError("base=2 期望抖动后为 2，实际: \(f2)")
        }
    }

    /// 12. 非法输入与极端边界防御断言（防负数间隔、防实数域外 NaN 穿透、防溢出与崩溃）
    public func testDefensiveBoundsAgainstIllegalInputs() throws {
        // 1. 负数稳定性与超大稳定性输入防御
        let illegalStabilities = [-100.0, -1.0, -0.001, 0.0, 100000.0, 1000000.0]
        for s in illegalStabilities {
            let interval = fsrs.nextInterval(stability: s)
            guard !interval.isNaN && !interval.isInfinite else {
                throw TestError("nextInterval(stability: \(s)) 返回了 NaN 或 Infinite: \(interval)")
            }
            guard interval >= 0.0 else {
                throw TestError("nextInterval(stability: \(s)) 产生了负数复习间隔: \(interval)")
            }
            let days = fsrs.nextIntervalDays(stability: s)
            guard days >= 1 && days <= FsrsAlgorithm.maxInterval else {
                throw TestError("nextIntervalDays(stability: \(s)) 超出 [1, maxInterval] 范围: \(days)")
            }
        }

        // 2. 非法目标保留率（<= 0 或 > 1）输入防御，防除零与崩溃
        let illegalRetentions = [-1.0, 0.0, 0.0001, 1.0, 2.0]
        for r in illegalRetentions {
            let interval = fsrs.nextInterval(stability: 10.0, retention: r)
            guard !interval.isNaN && !interval.isInfinite else {
                throw TestError("nextInterval(retention: \(r)) 返回了 NaN 或 Infinite: \(interval)")
            }
            guard interval >= 0.0 else {
                throw TestError("nextInterval(retention: \(r)) 产生了负数复习间隔: \(interval)")
            }
            let days = fsrs.nextIntervalDays(stability: 10.0, retention: r)
            guard days >= 1 && days <= FsrsAlgorithm.maxInterval else {
                throw TestError("nextIntervalDays(retention: \(r)) 超出 [1, maxInterval] 范围: \(days)")
            }
        }

        // 3. stabilityAfterFailure 负数难度及超范围难度/稳定性/留存率防御，杜绝 NaN 穿透
        let testDifficulties = [-10.0, -5.0, 0.0, 0.5, 12.0, 20.0]
        for d in testDifficulties {
            let failS = fsrs.stabilityAfterFailure(stability: 10.0, difficulty: d, retrievability: 0.5)
            guard !failS.isNaN else {
                throw TestError("stabilityAfterFailure(difficulty: \(d)) 产生了 NaN 穿透！")
            }
            guard failS >= FsrsAlgorithm.sMin && failS <= FsrsAlgorithm.sMax else {
                throw TestError("stabilityAfterFailure(difficulty: \(d)) 超出 [sMin, sMax] 范围: \(failS)")
            }
        }

        // 4. stabilityAfterSuccess 负数难度/极端入参防御
        for d in testDifficulties {
            let successS = fsrs.stabilityAfterSuccess(stability: -5.0, difficulty: d, retrievability: -0.2, rating: .good)
            guard !successS.isNaN else {
                throw TestError("stabilityAfterSuccess(difficulty: \(d)) 产生了 NaN 穿透！")
            }
            guard successS >= FsrsAlgorithm.sMin && successS <= FsrsAlgorithm.sMax else {
                throw TestError("stabilityAfterSuccess(difficulty: \(d)) 超出 [sMin, sMax] 范围: \(successS)")
            }
        }
    }
}

public struct TestError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

// MARK: - XCTestCase 集成（若处于 Xcode/XCTest 环境）

#if canImport(XCTest)
public final class FsrsAlgorithmTests: XCTestCase {
    private var suite: FsrsAlgorithmTestSuite!

    public override func setUp() {
        super.setUp()
        suite = FsrsAlgorithmTestSuite()
    }

    public func testFirstLearnGoodGraduation() throws {
        try suite.testFirstLearnGoodGraduation()
    }

    public func testFirstLearnEasyHigherInterval() throws {
        try suite.testFirstLearnEasyHigherInterval()
    }

    public func testFirstLearnAgainFailure() throws {
        try suite.testFirstLearnAgainFailure()
    }

    public func testReviewGoodIntervalIncrease() throws {
        try suite.testReviewGoodIntervalIncrease()
    }

    public func testReviewAgainLapseRelearning() throws {
        try suite.testReviewAgainLapseRelearning()
    }

    public func testHighStabilityDropCliff() throws {
        try suite.testHighStabilityDropCliff()
    }

    public func testDelayedReviewBoostStability() throws {
        try suite.testDelayedReviewBoostStability()
    }

    public func testRetentionSettingImpact() throws {
        try suite.testRetentionSettingImpact()
    }

    public func testMonotonicityGuarantee() throws {
        try suite.testMonotonicityGuarantee()
    }

    public func testMonotonicityUnderExtensiveGrid() throws {
        try suite.testMonotonicityUnderExtensiveGrid()
    }

    public func testFuzzDeterminismAndBounds() throws {
        try suite.testFuzzDeterminismAndBounds()
    }

    public func testDefensiveBoundsAgainstIllegalInputs() throws {
        try suite.testDefensiveBoundsAgainstIllegalInputs()
    }
}
#endif

// MARK: - CLI 独立执行入口

@main
public struct FsrsAlgorithmTestsRunner {
    public static func main() {
        print("========================================")
        print("  FSRS 6 记忆算法全量 12 项单元测试套件")
        print("========================================")

        let suite = FsrsAlgorithmTestSuite()
        var passedCount = 0
        var failedCount = 0

        let tests: [(String, () throws -> Void)] = [
            ("首次学习 质量4(Good) 应该毕业并设置间隔", { try suite.testFirstLearnGoodGraduation() }),
            ("首次学习 质量5(Easy) 应该给更长的间隔", { try suite.testFirstLearnEasyHigherInterval() }),
            ("首次学习 质量2(Again) 应该失败且重复次数不增加", { try suite.testFirstLearnAgainFailure() }),
            ("复习阶段 质量4 间隔应该增加", { try suite.testReviewGoodIntervalIncrease() }),
            ("复习阶段 质量2忘记 应该重新适应", { try suite.testReviewAgainLapseRelearning() }),
            ("高稳定性卡片忘记时稳定性应该发生断崖式跌落", { try suite.testHighStabilityDropCliff() }),
            ("延迟且记得(Q=4) 应该给予稳定性奖励", { try suite.testDelayedReviewBoostStability() }),
            ("较高保留率设置应该产生更短或等于较低保留率的复习间隔", { try suite.testRetentionSettingImpact() }),
            ("复习阶段 困难间隔必须小于等于良好间隔且良好必须小于等于简单", { try suite.testMonotonicityGuarantee() }),
            ("大规模随机卡片与时间序列下 复习间隔必须恒保持单调递增性", { try suite.testMonotonicityUnderExtensiveGrid() }),
            ("Fuzz 确定性与边界断言", { try suite.testFuzzDeterminismAndBounds() }),
            ("非法与极端输入防御断言（防负数间隔与防NaN穿透）", { try suite.testDefensiveBoundsAgainstIllegalInputs() })
        ]

        for (index, (name, testBlock)) in tests.enumerated() {
            do {
                try testBlock()
                print("[\(index + 1)/\(tests.count)] ✅ PASS: \(name)")
                passedCount += 1
            } catch {
                print("[\(index + 1)/\(tests.count)] ❌ FAIL: \(name)")
                print("       原因: \(error.localizedDescription)")
                failedCount += 1
            }
        }

        print("----------------------------------------")
        print("测试结果: 总数 \(tests.count), 通过: \(passedCount), 失败: \(failedCount)")
        if failedCount == 0 {
            print("🎉 全部 12 项算法单测 100% 绿灯通过！")
            exit(0)
        } else {
            print("💥 存在未通过单测，请检查算法实现！")
            exit(1)
        }
    }
}
