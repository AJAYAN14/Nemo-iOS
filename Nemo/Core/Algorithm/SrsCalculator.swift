import Foundation

/// SRS 业务计算器协议
public protocol SrsCalculatorProtocol: Sendable {
    /// 执行核心状态推演（标准 0..5 quality 入参）
    func calculate(item: SrsItem, quality: Int, today: Int, itemId: Int) -> SrsUpdateResult

    /// 执行核心状态推演（SRSRatingQuality 入参）
    func calculate(item: SrsItem, ratingQuality: SRSRatingQuality, today: Int, itemId: Int) -> SrsUpdateResult

    /// 预测 4 档按钮对应的下次复习间隔文本（SRSRatingQuality 强类型键）
    func predictNextIntervals(item: SrsItem, today: Int, itemId: Int) -> [SRSRatingQuality: String]

    /// 预测 4 档按钮对应的下次复习间隔文本（原始 quality 键）
    func predictNextIntervalsRaw(item: SrsItem, today: Int, itemId: Int) -> [Int: String]

    /// 幂律遗忘曲线
    func forgettingCurve(elapsedDays: Double, stability: Double) -> Double

    /// 最优复习间隔（连续天数）
    func nextInterval(stability: Double, retention: Double?) -> Double

    /// 最优复习间隔（取整天数）
    func nextIntervalDays(stability: Double) -> Int
}
