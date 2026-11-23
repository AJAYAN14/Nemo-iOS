import Foundation

/// FSRS 4 档标准评分枚举
public enum FsrsRating: Int, Sendable, Equatable, Hashable, CaseIterable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

/// 记忆状态模型（包含稳定性与难度）
public struct MemoryState: Sendable, Equatable {
    /// 记忆稳定性（天数）：记忆留存率维持在 90% 的天数
    public let stability: Double
    /// 材料难度值：有效区间 [1.0, 10.0]
    public let difficulty: Double

    public init(stability: Double = 0.0, difficulty: Double = 0.0) {
        self.stability = stability
        self.difficulty = difficulty
    }
}

/// 单项状态推演结果（包含记忆状态与连续间隔天数）
public struct FsrsItemState: Sendable, Equatable {
    public let memory: MemoryState
    public let interval: Double

    public init(memory: MemoryState, interval: Double) {
        self.memory = memory
        self.interval = interval
    }
}

/// 4 档按钮推演状态集合
public struct NextStates: Sendable, Equatable {
    public let again: FsrsItemState
    public let hard: FsrsItemState
    public let good: FsrsItemState
    public let easy: FsrsItemState

    public init(
        again: FsrsItemState,
        hard: FsrsItemState,
        good: FsrsItemState,
        easy: FsrsItemState
    ) {
        self.again = again
        self.hard = hard
        self.good = good
        self.easy = easy
    }
}
