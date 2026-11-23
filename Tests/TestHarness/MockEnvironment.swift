import Foundation

// MARK: - 测试断言与结果收集系统

public struct TestFailure: Sendable {
    public let testName: String
    public let message: String
    public let file: String
    public let line: Int
    
    public var description: String {
        return "[\(testName)] ❌ 失败于 \(URL(fileURLWithPath: file).lastPathComponent):\(line): \(message)"
    }
}

public final class TestContext: @unchecked Sendable {
    public static let shared = TestContext()
    
    private let lock = NSLock()
    private var currentTestName: String = ""
    private var failures: [TestFailure] = []
    
    private init() {}
    
    public func setCurrentTest(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        currentTestName = name
    }
    
    public func recordFailure(_ message: String, file: String, line: Int) {
        lock.lock()
        defer { lock.unlock() }
        let failure = TestFailure(testName: currentTestName, message: message, file: file, line: line)
        failures.append(failure)
    }
    
    public func popFailures() -> [TestFailure] {
        lock.lock()
        defer { lock.unlock() }
        let f = failures
        failures.removeAll()
        return f
    }
}

// MARK: - 常用断言辅助函数

public func expectTrue(_ condition: @autoclosure () -> Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    if !condition() {
        let msg = message.isEmpty ? "预期结果为 true，但实际为 false" : message
        TestContext.shared.recordFailure(msg, file: file, line: line)
    }
}

public func expectFalse(_ condition: @autoclosure () -> Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    if condition() {
        let msg = message.isEmpty ? "预期结果为 false，但实际为 true" : message
        TestContext.shared.recordFailure(msg, file: file, line: line)
    }
}

public func expectEqual<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: @autoclosure () -> T, _ message: String = "", file: String = #file, line: Int = #line) {
    let act = actual()
    let exp = expected()
    if act != exp {
        let msg = message.isEmpty ? "期望值: <\(exp)>，实际值: <\(act)>" : "\(message) [期望: <\(exp)>, 实际: <\(act)>]"
        TestContext.shared.recordFailure(msg, file: file, line: line)
    }
}

public func expectNotEqual<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: @autoclosure () -> T, _ message: String = "", file: String = #file, line: Int = #line) {
    let act = actual()
    let exp = expected()
    if act == exp {
        let msg = message.isEmpty ? "期望值不等于 <\(exp)>，但实际相等" : "\(message) [值均等于: <\(act)>]"
        TestContext.shared.recordFailure(msg, file: file, line: line)
    }
}

public func expectApproxEqual(_ actual: Double, _ expected: Double, accuracy: Double = 0.001, _ message: String = "", file: String = #file, line: Int = #line) {
    let diff = abs(actual - expected)
    if diff > accuracy {
        let msg = message.isEmpty ? "浮点数误差超限: 期望 <\(expected)>，实际 <\(actual)>，差值 <\(diff)> > <\(accuracy)>" : "\(message) [期望: \(expected), 实际: \(actual), diff: \(diff)]"
        TestContext.shared.recordFailure(msg, file: file, line: line)
    }
}

public func expectNil(_ value: Any?, _ message: String = "", file: String = #file, line: Int = #line) {
    if value != nil {
        let msg = message.isEmpty ? "预期为 nil，但实际有值: <\(String(describing: value))>" : message
        TestContext.shared.recordFailure(msg, file: file, line: line)
    }
}

public func expectNotNil(_ value: Any?, _ message: String = "", file: String = #file, line: Int = #line) {
    if value == nil {
        let msg = message.isEmpty ? "预期不为 nil，但实际为 nil" : message
        TestContext.shared.recordFailure(msg, file: file, line: line)
    }
}

public func expectThrows<T>(_ expression: () throws -> T, _ message: String = "", file: String = #file, line: Int = #line) {
    do {
        _ = try expression()
        let msg = message.isEmpty ? "预期抛出异常，但正常返回" : message
        TestContext.shared.recordFailure(msg, file: file, line: line)
    } catch {
        // 成功抛出符合预期
    }
}

public func expectAsyncThrows<T>(_ expression: () async throws -> T, _ message: String = "", file: String = #file, line: Int = #line) async {
    do {
        _ = try await expression()
        let msg = message.isEmpty ? "预期异步操作抛出异常，但正常返回" : message
        TestContext.shared.recordFailure(msg, file: file, line: line)
    } catch {
        // 成功抛出符合预期
    }
}

// MARK: - 测试用例与套件结构

public struct TestCase: Sendable {
    public let id: String
    public let name: String
    public let tier: String
    public let action: @Sendable () async throws -> Void
    
    public init(id: String, name: String, tier: String, action: @escaping @Sendable () async throws -> Void) {
        self.id = id
        self.name = name
        self.tier = tier
        self.action = action
    }
}

public struct TestResult: Sendable {
    public let testCase: TestCase
    public let duration: TimeInterval
    public let failures: [TestFailure]
    
    public var isSuccess: Bool { failures.isEmpty }
}

public final class TestRegistry: @unchecked Sendable {
    public static let shared = TestRegistry()
    private var tests: [TestCase] = []
    private let lock = NSLock()
    
    private init() {}
    
    public func register(_ test: TestCase) {
        lock.lock()
        defer { lock.unlock() }
        tests.append(test)
    }
    
    public func getTests(forTier tier: String? = nil) -> [TestCase] {
        lock.lock()
        defer { lock.unlock() }
        if let tier = tier {
            return tests.filter { $0.tier == tier }
        }
        return tests
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        tests.removeAll()
    }
}

// MARK: - 沙盒文件系统与环境隔离

public final class MockSandbox: @unchecked Sendable {
    public let sandboxURL: URL
    private let fileManager = FileManager.default
    
    public init(prefix: String = "NemoSandbox_") {
        let tempDir = fileManager.temporaryDirectory
        self.sandboxURL = tempDir.appendingPathComponent("\(prefix)\(UUID().uuidString)", isDirectory: true)
        try? fileManager.createDirectory(at: sandboxURL, withIntermediateDirectories: true)
    }
    
    public func fileURL(named fileName: String) -> URL {
        return sandboxURL.appendingPathComponent(fileName)
    }
    
    public func cleanUp() {
        try? fileManager.removeItem(at: sandboxURL)
    }
    
    deinit {
        cleanUp()
    }
}

// MARK: - 模拟时钟 (MockClock)

public final class MockClock: @unchecked Sendable {
    private var currentEpochDayValue: Int
    private let lock = NSLock()
    
    public init(initialEpochDay: Int = 100) {
        self.currentEpochDayValue = initialEpochDay
    }
    
    public var currentEpochDay: Int {
        lock.lock()
        defer { lock.unlock() }
        return currentEpochDayValue
    }
    
    public func setEpochDay(_ day: Int) {
        lock.lock()
        defer { lock.unlock() }
        currentEpochDayValue = day
    }
    
    public func advanceDays(_ days: Int) {
        lock.lock()
        defer { lock.unlock() }
        currentEpochDayValue += days
    }
}
