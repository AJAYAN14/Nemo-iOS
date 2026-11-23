import Foundation

@main
struct E2ETestRunner {
    static func main() async {
        print("==================================================================")
        print("🚀 Nemo iOS 学习界面第二阶段 (FSRS / 持久化 / 词库流转) E2E 自动化测试套件")
        print("==================================================================")
        
        let startTime = Date()
        
        // 1. 注册所有测试层级用例
        Tier1_FeatureTests.registerAll()
        Tier2_BoundaryTests.registerAll()
        Tier3_IntegrationTests.registerAll()
        Tier4_RealWorldScenarios.registerAll()
        
        let tiers = ["Tier1", "Tier2", "Tier3", "Tier4"]
        var totalCount = 0
        var totalPassed = 0
        var totalFailed = 0
        var tierSummaries: [(tier: String, total: Int, passed: Int, failed: Int, duration: TimeInterval)] = []
        var allFailures: [TestFailure] = []
        
        for tier in tiers {
            let tests = TestRegistry.shared.getTests(forTier: tier)
            guard !tests.isEmpty else { continue }
            
            print("\n------------------------------------------------------------------")
            print("📦 正在执行 [\(tier)] 用例集 (共 \(tests.count) 个用例)...")
            print("------------------------------------------------------------------")
            
            let tierStartTime = Date()
            var passedInTier = 0
            var failedInTier = 0
            
            for test in tests {
                TestContext.shared.setCurrentTest(test.name)
                let caseStartTime = Date()
                do {
                    try await test.action()
                } catch {
                    TestContext.shared.recordFailure("未捕获异常: \(error.localizedDescription)", file: #file, line: #line)
                }
                
                let caseDuration = Date().timeIntervalSince(caseStartTime)
                let failures = TestContext.shared.popFailures()
                
                if failures.isEmpty {
                    passedInTier += 1
                    let formattedMs = String(format: "%.2fms", caseDuration * 1000.0)
                    print("  ✅ [PASS] \(test.id) - \(test.name) (\(formattedMs))")
                } else {
                    failedInTier += 1
                    allFailures.append(contentsOf: failures)
                    print("  ❌ [FAIL] \(test.id) - \(test.name)")
                    for f in failures {
                        print("     ↳ \(f.description)")
                    }
                }
            }
            
            let tierDuration = Date().timeIntervalSince(tierStartTime)
            totalCount += tests.count
            totalPassed += passedInTier
            totalFailed += failedInTier
            tierSummaries.append((tier: tier, total: tests.count, passed: passedInTier, failed: failedInTier, duration: tierDuration))
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        
        print("\n==================================================================")
        print("📊 测试执行摘要报告 (Test Execution Summary)")
        print("==================================================================")
        for summary in tierSummaries {
            let passRate = (summary.total > 0) ? Double(summary.passed) / Double(summary.total) * 100.0 : 0.0
            let durationStr = String(format: "%.3fs", summary.duration)
            let status = (summary.failed == 0) ? "✅ 全部通过" : "❌ 存在失败 (\(summary.failed))"
            print("• \(summary.tier.padding(toLength: 8, withPad: " ", startingAt: 0)): \(summary.passed)/\(summary.total) 通过 (\(String(format: "%.1f%%", passRate))) | 耗时: \(durationStr) | \(status)")
        }
        
        print("------------------------------------------------------------------")
        let totalPassRate = (totalCount > 0) ? Double(totalPassed) / Double(totalCount) * 100.0 : 0.0
        print("🎯 总用例数: \(totalCount) | 通过: \(totalPassed) | 失败: \(totalFailed) | 通过率: \(String(format: "%.1f%%", totalPassRate))")
        print("⏱️ 总执行耗时: \(String(format: "%.3fs", totalDuration))")
        print("==================================================================")
        
        if totalFailed == 0 {
            print("\n🎉 恭喜！全部 4-Tier \(totalCount) 项 E2E 自动化测试断言全部通过！\n")
            exit(0)
        } else {
            print("\n💥 警告：存在 \(totalFailed) 项测试断言失败，请检查上方失败详情！\n")
            exit(1)
        }
    }
}
