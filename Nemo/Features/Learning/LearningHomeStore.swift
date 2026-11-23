//
//  LearningHomeStore.swift
//  Nemo
//

import SwiftUI

/// 学习主页业务状态中枢（遵循现代 Swift @Observable 规范）
@MainActor
@Observable
public final class LearningHomeStore {
    /// 学习内容模式枚举
    public enum LearningMode: String, CaseIterable, Identifiable, Sendable {
        case word = "单词"
        case grammar = "语法"

        public var id: String { rawValue }
    }

    // MARK: - 模式与设置
    public var learningMode: LearningMode = .word
    public var dailyWordGoal: Int = 20
    public var dailyGrammarGoal: Int = 10
    public var resetHour: Int = 4

    // MARK: - 核心学习与打卡指标
    public private(set) var dailyStreak: Int = 0
    public private(set) var todayLearnedWords: Int = 0
    public private(set) var todayReviewedWords: Int = 0
    public private(set) var dueWordsCount: Int = 0
    public private(set) var todayLearnedGrammars: Int = 0
    public private(set) var todayReviewedGrammars: Int = 0
    public private(set) var dueGrammarsCount: Int = 0
    public private(set) var isLoading: Bool = false

    private let storage: LearningLocalStorage

    public init(storage: LearningLocalStorage = .shared) {
        self.storage = storage
    }

    // MARK: - 动态计算属性（随当前学习模式自适应）

    /// 当前模式下的今日新学完成数
    public var currentProgress: Int {
        learningMode == .word ? todayLearnedWords : todayLearnedGrammars
    }

    /// 当前模式下的每日新学目标
    public var currentGoal: Int {
        let goal = learningMode == .word ? dailyWordGoal : dailyGrammarGoal
        return max(goal, 1)
    }

    /// 当前模式下的今日已复习数
    public var reviewedToday: Int {
        learningMode == .word ? todayReviewedWords : todayReviewedGrammars
    }

    /// 当前模式下的待复习未完成数
    public var itemsDue: Int {
        learningMode == .word ? dueWordsCount : dueGrammarsCount
    }

    /// 当前模式下的复习总条目数（已复习 + 待复习）
    public var totalReviewItems: Int {
        reviewedToday + itemsDue
    }

    /// 当前模式下的今日新学进度比例 (0.0 ~ 1.0)
    public var progressFraction: Double {
        guard currentGoal > 0 else { return 0.0 }
        return min(max(Double(currentProgress) / Double(currentGoal), 0.0), 1.0)
    }

    /// 当前模式下的学习达成率百分比 (0 ~ 100)
    public var dailyCompletionRate: Int {
        Int(progressFraction * 100)
    }

    /// 是否已开始今日学习
    public var isLearned: Bool {
        currentProgress > 0 || reviewedToday > 0
    }

    /// 当前模式的主题色彩
    public var primaryModeColor: Color {
        learningMode == .word ? Color.orange : Color.green
    }

    // MARK: - 数据刷新与联动

    /// 全量异步刷新今日学习指标与 Streak
    public func refreshStats() async {
        isLoading = true
        let today = LearningLocalStorage.getLearningDay(resetHour: resetHour)

        do {
            // 1. 读取今日打卡记录
            if let record = try await storage.getTodayRecord(today: today) {
                self.todayLearnedWords = record.learnedWords
                self.todayReviewedWords = record.reviewedWords
                self.todayLearnedGrammars = record.learnedGrammars
                self.todayReviewedGrammars = record.reviewedGrammars
            } else {
                self.todayLearnedWords = 0
                self.todayReviewedWords = 0
                self.todayLearnedGrammars = 0
                self.todayReviewedGrammars = 0
            }

            // 2. 读取待复习卡片数量
            let dueWords = try await storage.getDueStudyStates(today: today)
            self.dueWordsCount = dueWords.count

            let dueGrammars = try await storage.getDueGrammarStudyStates(today: today)
            self.dueGrammarsCount = dueGrammars.count

            // 3. 计算连续打卡天数
            self.dailyStreak = try await storage.calculateCurrentStreak(today: today)
        } catch {
            // 优雅兜底，维持当前状态
        }

        self.isLoading = false
    }

    /// 同步外部传入的设置偏好项并重新计算
    public func syncSettings(wordGoal: Int, grammarGoal: Int, resetHour: Int) {
        if self.dailyWordGoal != wordGoal || self.dailyGrammarGoal != grammarGoal || self.resetHour != resetHour {
            self.dailyWordGoal = wordGoal
            self.dailyGrammarGoal = grammarGoal
            self.resetHour = resetHour
        }
    }
}
