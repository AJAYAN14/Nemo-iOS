//
//  LearningSessionStore.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 学习会话业务中枢（遵循现代 iOS @Observable 纯原生架构，支持单词与语法双模式闭环）
@MainActor
@Observable
public final class LearningSessionStore {
    /// 学习会话模式
    public enum SessionMode: Sendable {
        case word
        case grammar
    }

    // MARK: - 核心可观察状态
    public private(set) var mode: SessionMode = .word
    public private(set) var status: LearningSessionStatus = .loading
    public private(set) var wordsQueue: [Word] = []
    public private(set) var grammarsQueue: [Grammar] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var isFlipped: Bool = false
    public private(set) var isSessionFinished: Bool = false
    public private(set) var queueCounts: QueueCountState = QueueCountState()
    public private(set) var ratingIntervals: [SRSRatingQuality: String] = [:]
    public private(set) var currentCombo: Int = 0
    public private(set) var maxCombo: Int = 0
    public private(set) var stats: LearningSessionStats? = nil

    public private(set) var totalSessionCount: Int = 0
    public private(set) var completedCount: Int = 0
    public private(set) var isPlayingAudio: Bool = false
    public private(set) var playingText: String? = nil

    // MARK: - 撤销快照模型与状态
    public struct LearningUndoSnapshot: Sendable {
        public let mode: SessionMode
        public let wordsQueue: [Word]
        public let grammarsQueue: [Grammar]
        public let itemQueueTypes: [LearningQueueType]
        public let currentIndex: Int
        public let completedCount: Int
        public let totalSessionCount: Int
        public let queueCounts: QueueCountState
        public let currentCombo: Int
        public let maxCombo: Int
        public let sessionNewCount: Int
        public let sessionReviewCount: Int
        public let sessionRelearnCount: Int
    }

    public private(set) var undoSnapshot: LearningUndoSnapshot? = nil
    public var canUndo: Bool { undoSnapshot != nil }

    // MARK: - 更多操作菜单与偏好配置状态
    public var isAutoAudioEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAutoAudioEnabled, forKey: "settings_auto_audio_enabled")
        }
    }
    public var showRatingGuide: Bool = false

    public var isShowAnswerDelayEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "settings_show_answer_delay_enabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "settings_show_answer_delay_enabled")
            resetDelayCountdown()
        }
    }

    public var showAnswerDelaySeconds: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "settings_show_answer_delay_seconds")
            return val > 0 ? val : 1
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "settings_show_answer_delay_seconds")
            resetDelayCountdown()
        }
    }

    public func setShowAnswerDelay(seconds: Int) {
        self.showAnswerDelaySeconds = seconds
        self.isShowAnswerDelayEnabled = true
        resetDelayCountdown()
    }

    public private(set) var delayRemainingSeconds: Int = 0
    private var delayTimerTask: Task<Void, Never>? = nil

    public var isAutoRevealAnswerEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "settings_auto_reveal_enabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "settings_auto_reveal_enabled")
            scheduleAutoRevealIfNeeded()
        }
    }

    public var autoRevealSeconds: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "settings_auto_reveal_seconds")
            return val > 0 ? val : 5
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "settings_auto_reveal_seconds")
            scheduleAutoRevealIfNeeded()
        }
    }

    public func setAutoRevealDuration(seconds: Int) {
        self.autoRevealSeconds = seconds
        self.isAutoRevealAnswerEnabled = true
        scheduleAutoRevealIfNeeded()
    }

    private var autoRevealTask: Task<Void, Never>? = nil

    public var isWhiteboardEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "settings_whiteboard_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "settings_whiteboard_enabled") }
    }

    public private(set) var toastMessage: String? = nil
    private var toastTask: Task<Void, Never>? = nil

    public func showToast(_ message: String) {
        toastTask?.cancel()
        self.toastMessage = message
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            self?.toastMessage = nil
        }
    }

    public func resetDelayCountdown() {
        delayTimerTask?.cancel()
        delayTimerTask = nil
        guard isShowAnswerDelayEnabled && !isFlipped else {
            delayRemainingSeconds = 0
            return
        }
        delayRemainingSeconds = showAnswerDelaySeconds
        delayTimerTask = Task { @MainActor [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, let self = self else { return }
                guard self.delayRemainingSeconds > 0 else { return }
                self.delayRemainingSeconds -= 1
            }
        }
    }

    public func scheduleAutoRevealIfNeeded() {
        autoRevealTask?.cancel()
        autoRevealTask = nil
        guard isAutoRevealAnswerEnabled && !isFlipped && !isSessionFinished else { return }
        let durationNanos = UInt64(autoRevealSeconds) * 1_000_000_000
        autoRevealTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: durationNanos)
            guard !Task.isCancelled, let self = self else { return }
            if !self.isFlipped && !self.isSessionFinished {
                self.revealAnswer()
            }
        }
    }

    // MARK: - 依赖注入与存储层
    private let dictionaryStorage: DictionaryLocalStorage
    private let learningStorage: LearningLocalStorage
    private let srsCalculator: SrsCalculatorProtocol

    // 内部统计与任务管理
    private var sessionStartTime: Date = Date()
    private var sessionNewCount: Int = 0
    private var sessionReviewCount: Int = 0
    private var sessionRelearnCount: Int = 0
    private var advanceTask: Task<Void, Never>?
    private var itemQueueTypes: [LearningQueueType] = []

    // MARK: - 计算属性
    public var currentWord: Word? {
        guard mode == .word, currentIndex >= 0 && currentIndex < wordsQueue.count else { return nil }
        return wordsQueue[currentIndex]
    }

    public var currentGrammar: Grammar? {
        guard mode == .grammar, currentIndex >= 0 && currentIndex < grammarsQueue.count else { return nil }
        return grammarsQueue[currentIndex]
    }

    /// 当前会话中剩余待处理卡片数
    public var remainingCount: Int {
        guard !isSessionFinished else { return 0 }
        let total = mode == .word ? wordsQueue.count : grammarsQueue.count
        return max(0, total - currentIndex)
    }

    /// 进度百分比 (0.0 ~ 1.0)
    public var progress: Double {
        guard totalSessionCount > 0 else { return 0.0 }
        if isSessionFinished || completedCount >= totalSessionCount {
            return 1.0
        }
        return min(max(Double(completedCount) / Double(totalSessionCount), 0.0), 1.0)
    }

    /// 是否已展示答案
    public var isAnswerShown: Bool { isFlipped }

    /// 当前卡片对应的徽章类型
    public var currentBadgeType: CardBadgeType {
        let currentType: LearningQueueType = currentIndex < itemQueueTypes.count ? itemQueueTypes[currentIndex] : .new
        switch currentType {
        case .new:
            return .new
        case .learning:
            return .learning
        case .review:
            return .review
        case .relearn:
            return .relearn
        }
    }

    // MARK: - 初始化
    public init(
        mode: SessionMode = .word,
        words: [Word] = [],
        grammars: [Grammar] = [],
        dictionaryStorage: DictionaryLocalStorage = .shared,
        learningStorage: LearningLocalStorage = .shared,
        srsCalculator: SrsCalculatorProtocol = SrsCalculatorImpl()
    ) {
        self.mode = mode
        self.dictionaryStorage = dictionaryStorage
        self.learningStorage = learningStorage
        self.srsCalculator = srsCalculator
        self.isAutoAudioEnabled = UserDefaults.standard.bool(forKey: "settings_auto_audio_enabled")

        if mode == .word && !words.isEmpty {
            loadWords(words)
        } else if mode == .grammar && !grammars.isEmpty {
            loadGrammars(grammars)
        }
    }

    /// 便捷静态构造：供预览快速走查
    public static var mock: LearningSessionStore {
        LearningSessionStore(mode: .word, words: LearningMockData.mockWords)
    }

    public static var mockGrammar: LearningSessionStore {
        LearningSessionStore(mode: .grammar, grammars: LearningMockData.mockGrammars)
    }

    public static var mockCompleted: LearningSessionStore {
        let store = LearningSessionStore(mode: .word, words: LearningMockData.mockWords)
        store.status = .completed(stats: LearningMockData.mockStats)
        store.isSessionFinished = true
        store.stats = LearningMockData.mockStats
        store.completedCount = store.totalSessionCount
        store.queueCounts = QueueCountState(newCount: 0, learningCount: 0, reviewCount: 0, relearnCount: 0)
        return store
    }

    // MARK: - 真实数据动态抽取与流转闭环

    /// 从本地离线库与持久化存储动态抽取今日学习队列
    public func loadRealSessionData(dailyGoal: Int = 20, mode: SessionMode = .word) async {
        advanceTask?.cancel()
        advanceTask = nil
        self.mode = mode
        self.status = .loading

        let today = LearningLocalStorage.getLearningDay(resetHour: 4)

        if mode == .word {
            await loadRealWordData(dailyGoal: dailyGoal, today: today)
        } else {
            await loadRealGrammarData(dailyGoal: dailyGoal, today: today)
        }
    }

    private func loadRealWordData(dailyGoal: Int, today: Int) async {
        do {
            let allWords = try await dictionaryStorage.loadWords()
            if allWords.isEmpty {
                finishEmptySession()
                return
            }
            let wordMap = Dictionary(allWords.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })

            // 1. 读取到期待复习卡片
            let dueStates = try await learningStorage.getDueStudyStates(today: today)
            var sessionWords: [Word] = []
            var sessionTypes: [LearningQueueType] = []

            for due in dueStates {
                if let w = wordMap[due.wordId] {
                    sessionWords.append(w)
                    sessionTypes.append(due.type == 3 ? .relearn : .review)
                }
            }

            // 2. 抽取未学新词（严格遵循 JLPT 等级进阶权重升序：N5 优先，同级按 ID 升序）
            let allStates = try await learningStorage.getAllStudyStates()
            let neededNewCount = max(dailyGoal - sessionWords.count, 0)

            let sortedWords = allWords.sorted { lhs, rhs in
                if lhs.jlptLevel.sortOrder != rhs.jlptLevel.sortOrder {
                    return lhs.jlptLevel.sortOrder < rhs.jlptLevel.sortOrder
                }
                return lhs.id < rhs.id
            }

            if neededNewCount > 0 {
                var newWordsFound = 0
                for w in sortedWords {
                    guard newWordsFound < neededNewCount else { break }
                    if allStates[w.id] == nil {
                        sessionWords.append(w)
                        sessionTypes.append(.new)
                        newWordsFound += 1
                    }
                }
            }

            // 3. 对齐 Android SessionLoader：若无到期复习也无可学新词，直接优雅进入完成空状态
            if sessionWords.isEmpty {
                finishEmptySession()
                return
            }

            setupWordSession(words: sessionWords, types: sessionTypes, today: today)
        } catch {
            finishEmptySession()
        }
    }

    private func loadRealGrammarData(dailyGoal: Int, today: Int) async {
        do {
            let allGrammars = try await dictionaryStorage.loadGrammars()
            if allGrammars.isEmpty {
                finishEmptySession()
                return
            }
            let grammarMap = Dictionary(allGrammars.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })

            // 1. 读取到期待复习语法
            let dueStates = try await learningStorage.getDueGrammarStudyStates(today: today)
            var sessionGrammars: [Grammar] = []
            var sessionTypes: [LearningQueueType] = []

            for due in dueStates {
                if let g = grammarMap[due.grammarId] {
                    sessionGrammars.append(g)
                    sessionTypes.append(due.type == 3 ? .relearn : .review)
                }
            }

            // 2. 抽取未学新语法（严格遵循 JLPT 等级进阶权重升序：N5 优先，同级按 ID 升序）
            let allStates = try await learningStorage.getAllGrammarStudyStates()
            let neededNewCount = max(dailyGoal - sessionGrammars.count, 0)

            let sortedGrammars = allGrammars.sorted { lhs, rhs in
                if lhs.jlptLevel.sortOrder != rhs.jlptLevel.sortOrder {
                    return lhs.jlptLevel.sortOrder < rhs.jlptLevel.sortOrder
                }
                return lhs.id < rhs.id
            }

            if neededNewCount > 0 {
                var newGrammarsFound = 0
                for g in sortedGrammars {
                    guard newGrammarsFound < neededNewCount else { break }
                    if allStates[g.id] == nil {
                        sessionGrammars.append(g)
                        sessionTypes.append(.new)
                        newGrammarsFound += 1
                    }
                }
            }

            // 3. 对齐 Android SessionLoader：若无可学语法，直接优雅进入完成空状态
            if sessionGrammars.isEmpty {
                finishEmptySession()
                return
            }

            setupGrammarSession(grammars: sessionGrammars, types: sessionTypes, today: today)
        } catch {
            finishEmptySession()
        }
    }

    /// 对齐 Android SessionLoader 完成状态：无数据时优雅呈现完成看板，严禁注入假数据
    private func finishEmptySession() {
        self.wordsQueue = []
        self.grammarsQueue = []
        self.itemQueueTypes = []
        self.totalSessionCount = 0
        self.completedCount = 0
        self.currentIndex = 0
        self.isFlipped = false
        self.isSessionFinished = true
        self.queueCounts = QueueCountState()
        let emptyStats = LearningSessionStats(
            totalLearnedCount: 0,
            newCount: 0,
            reviewCount: 0,
            relearnCount: 0,
            maxCombo: 0,
            durationSeconds: 0,
            dailyStreak: 0
        )
        self.stats = emptyStats
        self.status = .completed(stats: emptyStats)
    }

    private func setupWordSession(words: [Word], types: [LearningQueueType], today: Int) {
        self.wordsQueue = words
        self.grammarsQueue = []
        self.itemQueueTypes = types
        self.totalSessionCount = words.count
        self.completedCount = 0
        self.currentIndex = 0
        self.isFlipped = false
        self.isSessionFinished = false
        self.currentCombo = 0
        self.maxCombo = 0
        self.sessionStartTime = Date()
        self.sessionNewCount = 0
        self.sessionReviewCount = 0
        self.sessionRelearnCount = 0
        self.stats = nil

        updateInitialQueueCounts(from: types)

        Task { @MainActor in
            await prepareIntervalsForCurrentItem()
            self.status = .learning(isFlipped: false)
            self.resetDelayCountdown()
            self.scheduleAutoRevealIfNeeded()
        }
    }

    private func setupGrammarSession(grammars: [Grammar], types: [LearningQueueType], today: Int) {
        self.wordsQueue = []
        self.grammarsQueue = grammars
        self.itemQueueTypes = types
        self.totalSessionCount = grammars.count
        self.completedCount = 0
        self.currentIndex = 0
        self.isFlipped = false
        self.isSessionFinished = false
        self.currentCombo = 0
        self.maxCombo = 0
        self.sessionStartTime = Date()
        self.sessionNewCount = 0
        self.sessionReviewCount = 0
        self.sessionRelearnCount = 0
        self.stats = nil

        updateInitialQueueCounts(from: types)

        Task { @MainActor in
            await prepareIntervalsForCurrentItem()
            self.status = .learning(isFlipped: false)
            self.resetDelayCountdown()
            self.scheduleAutoRevealIfNeeded()
        }
    }

    private func updateInitialQueueCounts(from types: [LearningQueueType]) {
        var newCount = 0
        var learningCount = 0
        var reviewCount = 0
        var relearnCount = 0
        for t in types {
            switch t {
            case .new: newCount += 1
            case .learning: learningCount += 1
            case .review: reviewCount += 1
            case .relearn: relearnCount += 1
            }
        }
        self.queueCounts = QueueCountState(
            newCount: newCount,
            learningCount: learningCount,
            reviewCount: reviewCount,
            relearnCount: relearnCount
        )
    }

    // MARK: - 意图方法

    public func loadWords(_ words: [Word]) {
        advanceTask?.cancel()
        advanceTask = nil
        self.mode = .word
        setupWordSession(
            words: words,
            types: Array(repeating: .new, count: words.count),
            today: LearningLocalStorage.getLearningDay(resetHour: 4)
        )
    }

    public func loadGrammars(_ grammars: [Grammar]) {
        advanceTask?.cancel()
        advanceTask = nil
        self.mode = .grammar
        setupGrammarSession(
            grammars: grammars,
            types: Array(repeating: .new, count: grammars.count),
            today: LearningLocalStorage.getLearningDay(resetHour: 4)
        )
    }

    public func restartSession() {
        advanceTask?.cancel()
        advanceTask = nil
        Task { @MainActor in
            await loadRealSessionData(dailyGoal: totalSessionCount > 0 ? totalSessionCount : 20, mode: mode)
        }
    }

    public func flipCard() {
        guard case .learning = status else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            self.isFlipped.toggle()
            self.status = .learning(isFlipped: self.isFlipped)
        }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        if isFlipped && isAutoAudioEnabled {
            if mode == .word, let word = currentWord {
                speak(text: word.hiragana)
            } else if mode == .grammar, let grammar = currentGrammar {
                speak(text: grammar.title)
            }
        }
    }

    public func revealAnswer() {
        guard !isFlipped else { return }
        autoRevealTask?.cancel()
        autoRevealTask = nil
        flipCard()
    }

    public func submitRating(_ quality: SRSRatingQuality) {
        guard case .learning = status else { return }

        TtsSpeechService.shared.stop()
        isPlayingAudio = false
        playingText = nil

        saveUndoSnapshot()
        autoRevealTask?.cancel()
        autoRevealTask = nil
        delayTimerTask?.cancel()
        delayTimerTask = nil
        delayRemainingSeconds = 0

        advanceTask?.cancel()
        advanceTask = nil

        triggerHaptic(for: quality)

        let currentType: LearningQueueType = currentIndex < itemQueueTypes.count ? itemQueueTypes[currentIndex] : .new
        decrementQueueCount(for: currentType)

        let today = LearningLocalStorage.getLearningDay(resetHour: 4)
        let isNew = (currentType == .new)
        let isReview = (currentType == .review || currentType == .relearn)

        switch quality {
        case .again:
            currentCombo = 0
            sessionRelearnCount += 1
            if mode == .word, let word = currentWord {
                wordsQueue.append(word)
            } else if mode == .grammar, let grammar = currentGrammar {
                grammarsQueue.append(grammar)
            }
            itemQueueTypes.append(.relearn)
            queueCounts.relearnCount += 1
            totalSessionCount += 1
        case .hard:
            currentCombo = 0
            sessionReviewCount += 1
        case .good:
            currentCombo += 1
            maxCombo = max(maxCombo, currentCombo)
            sessionReviewCount += 1
        case .easy:
            currentCombo += 1
            maxCombo = max(maxCombo, currentCombo)
            sessionNewCount += 1
        }

        completedCount += 1
        status = .processing

        // 异步状态推演并原子写盘
        if mode == .word, let word = currentWord {
            Task { [weak self] in
                guard let self else { return }
                var state = (try? await self.learningStorage.getStudyState(wordId: word.id)) ?? WordStudyState.newCard(wordId: word.id)
                let result = self.srsCalculator.calculate(item: state, ratingQuality: quality, today: today, itemId: word.id)
                state.update(with: result)
                try? await self.learningStorage.saveStudyState(state)
                try? await self.learningStorage.recordDailyStudy(
                    learnedWordsIncrement: isNew ? 1 : 0,
                    reviewedWordsIncrement: isReview ? 1 : 0,
                    learnedGrammarsIncrement: 0,
                    reviewedGrammarsIncrement: 0,
                    date: today
                )
            }
        } else if mode == .grammar, let grammar = currentGrammar {
            Task { [weak self] in
                guard let self else { return }
                var state = (try? await self.learningStorage.getGrammarStudyState(grammarId: grammar.id)) ?? GrammarStudyState.newCard(grammarId: grammar.id)
                let result = self.srsCalculator.calculate(item: state, ratingQuality: quality, today: today, itemId: grammar.id)
                state.update(with: result)
                try? await self.learningStorage.saveGrammarStudyState(state)
                try? await self.learningStorage.recordDailyStudy(
                    learnedWordsIncrement: 0,
                    reviewedWordsIncrement: 0,
                    learnedGrammarsIncrement: isNew ? 1 : 0,
                    reviewedGrammarsIncrement: isReview ? 1 : 0,
                    date: today
                )
            }
        }

        advanceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled, let self else { return }
            await self.advanceToNextItem()
        }
    }

    private func decrementQueueCount(for type: LearningQueueType) {
        switch type {
        case .new:
            if queueCounts.newCount > 0 { queueCounts.newCount -= 1 }
        case .learning:
            if queueCounts.learningCount > 0 { queueCounts.learningCount -= 1 }
        case .review:
            if queueCounts.reviewCount > 0 { queueCounts.reviewCount -= 1 }
        case .relearn:
            if queueCounts.relearnCount > 0 { queueCounts.relearnCount -= 1 }
        }
    }

    private func advanceToNextItem() async {
        advanceTask = nil
        currentIndex += 1
        isFlipped = false

        let queueCount = mode == .word ? wordsQueue.count : grammarsQueue.count
        if currentIndex >= queueCount {
            await finishSession()
        } else {
            await prepareIntervalsForCurrentItem()
            status = .learning(isFlipped: false)
            resetDelayCountdown()
            scheduleAutoRevealIfNeeded()
        }
    }

    private func finishSession() async {
        advanceTask?.cancel()
        advanceTask = nil

        self.queueCounts = QueueCountState(newCount: 0, learningCount: 0, reviewCount: 0, relearnCount: 0)
        self.completedCount = self.totalSessionCount

        let duration = max(Date().timeIntervalSince(sessionStartTime), 1.0)
        let today = LearningLocalStorage.getLearningDay(resetHour: 4)
        let realStreak = (try? await learningStorage.calculateCurrentStreak(today: today)) ?? 1

        let finalStats = LearningSessionStats(
            totalLearnedCount: completedCount,
            newCount: sessionNewCount,
            reviewCount: sessionReviewCount,
            relearnCount: sessionRelearnCount,
            maxCombo: maxCombo,
            durationSeconds: duration,
            dailyStreak: realStreak
        )
        self.stats = finalStats
        self.isSessionFinished = true
        self.status = .completed(stats: finalStats)

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    public func speak(text: String) {
        self.isPlayingAudio = true
        self.playingText = text

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif

        TtsSpeechService.shared.speak(text: text) { [weak self] in
            Task { @MainActor in
                self?.isPlayingAudio = false
                self?.playingText = nil
            }
        }
    }

    private func prepareIntervalsForCurrentItem() async {
        let today = LearningLocalStorage.getLearningDay(resetHour: 4)
        if mode == .word, let word = currentWord {
            let state = (try? await learningStorage.getStudyState(wordId: word.id)) ?? WordStudyState.newCard(wordId: word.id)
            let predicted = srsCalculator.predictNextIntervals(item: state, today: today, itemId: word.id)
            self.ratingIntervals = predicted.isEmpty ? defaultIntervals : predicted
        } else if mode == .grammar, let grammar = currentGrammar {
            let state = (try? await learningStorage.getGrammarStudyState(grammarId: grammar.id)) ?? GrammarStudyState.newCard(grammarId: grammar.id)
            let predicted = srsCalculator.predictNextIntervals(item: state, today: today, itemId: grammar.id)
            self.ratingIntervals = predicted.isEmpty ? defaultIntervals : predicted
        }
    }

    private var defaultIntervals: [SRSRatingQuality: String] {
        [
            .again: "< 1m",
            .hard: "10m",
            .good: "1d",
            .easy: "4d"
        ]
    }

    private func triggerHaptic(for quality: SRSRatingQuality) {
        #if canImport(UIKit)
        switch quality {
        case .again:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .hard:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .good:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .easy:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }

    // MARK: - 卡片操作与菜单控制

    /// 撤销上一次评分或卡片操作
    public func undo() {
        guard let snapshot = undoSnapshot else { return }
        advanceTask?.cancel()
        advanceTask = nil
        autoRevealTask?.cancel()
        autoRevealTask = nil
        delayTimerTask?.cancel()
        delayTimerTask = nil

        self.mode = snapshot.mode
        self.wordsQueue = snapshot.wordsQueue
        self.grammarsQueue = snapshot.grammarsQueue
        self.itemQueueTypes = snapshot.itemQueueTypes
        self.currentIndex = snapshot.currentIndex
        self.completedCount = snapshot.completedCount
        self.totalSessionCount = snapshot.totalSessionCount
        self.queueCounts = snapshot.queueCounts
        self.currentCombo = snapshot.currentCombo
        self.maxCombo = snapshot.maxCombo
        self.sessionNewCount = snapshot.sessionNewCount
        self.sessionReviewCount = snapshot.sessionReviewCount
        self.sessionRelearnCount = snapshot.sessionRelearnCount
        self.isFlipped = false
        self.isSessionFinished = false
        self.stats = nil
        self.undoSnapshot = nil

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        Task { @MainActor in
            await prepareIntervalsForCurrentItem()
            self.status = .learning(isFlipped: false)
            self.resetDelayCountdown()
            self.scheduleAutoRevealIfNeeded()
        }

        showToast("已撤销上一次评分")
    }

    /// 保存当前状态快照供撤销使用
    public func saveUndoSnapshot() {
        self.undoSnapshot = LearningUndoSnapshot(
            mode: mode,
            wordsQueue: wordsQueue,
            grammarsQueue: grammarsQueue,
            itemQueueTypes: itemQueueTypes,
            currentIndex: currentIndex,
            completedCount: completedCount,
            totalSessionCount: totalSessionCount,
            queueCounts: queueCounts,
            currentCombo: currentCombo,
            maxCombo: maxCombo,
            sessionNewCount: sessionNewCount,
            sessionReviewCount: sessionReviewCount,
            sessionRelearnCount: sessionRelearnCount
        )
    }

    /// 搁置当前卡片（今日不再出现，从当前会话队列剔除并推进至下一项）
    public func buryCurrent() {
        guard case .learning = status else { return }
        saveUndoSnapshot()
        let title = mode == .word ? (currentWord?.japanese ?? "") : (currentGrammar?.title ?? "")
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        showToast("已暂缓: \(title) (今日不再出现)")
        Task { @MainActor [weak self] in
            await self?.removeCurrentItemAndAdvance()
        }
    }

    /// 暂停当前卡片（标记跳过 isSkipped = true 并原子持久化，从当前会话推进至下一项）
    public func suspendCurrent() {
        guard case .learning = status else { return }
        saveUndoSnapshot()
        let title = mode == .word ? (currentWord?.japanese ?? "") : (currentGrammar?.title ?? "")
        if mode == .word, let word = currentWord {
            Task { [weak self] in
                guard let self else { return }
                var state = (try? await self.learningStorage.getStudyState(wordId: word.id)) ?? WordStudyState.newCard(wordId: word.id)
                state.isSkipped = true
                try? await self.learningStorage.saveStudyState(state)
            }
        } else if mode == .grammar, let grammar = currentGrammar {
            Task { [weak self] in
                guard let self else { return }
                var state = (try? await self.learningStorage.getGrammarStudyState(grammarId: grammar.id)) ?? GrammarStudyState.newCard(grammarId: grammar.id)
                state.isSkipped = true
                try? await self.learningStorage.saveGrammarStudyState(state)
            }
        }

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        showToast("已暂停: \(title)")
        Task { @MainActor [weak self] in
            await self?.removeCurrentItemAndAdvance()
        }
    }

    /// 提交条目内容报错反馈
    public func reportContentError(errorType: String, description: String?) {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        showToast("反馈成功，感谢您的反馈！")
    }

    /// 从当前学习队列中移除当前项并平滑推进至下一项
    private func removeCurrentItemAndAdvance() async {
        advanceTask?.cancel()
        advanceTask = nil
        autoRevealTask?.cancel()
        autoRevealTask = nil
        delayTimerTask?.cancel()
        delayTimerTask = nil

        let currentType: LearningQueueType = currentIndex < itemQueueTypes.count ? itemQueueTypes[currentIndex] : .new
        decrementQueueCount(for: currentType)

        if mode == .word {
            guard currentIndex >= 0 && currentIndex < wordsQueue.count else { return }
            wordsQueue.remove(at: currentIndex)
        } else {
            guard currentIndex >= 0 && currentIndex < grammarsQueue.count else { return }
            grammarsQueue.remove(at: currentIndex)
        }

        if currentIndex < itemQueueTypes.count {
            itemQueueTypes.remove(at: currentIndex)
        }

        totalSessionCount = max(completedCount, totalSessionCount - 1)

        let remainingCount = mode == .word ? wordsQueue.count : grammarsQueue.count
        if remainingCount == 0 || currentIndex >= remainingCount {
            await finishSession()
        } else {
            isFlipped = false
            await prepareIntervalsForCurrentItem()
            status = .learning(isFlipped: false)
            resetDelayCountdown()
            scheduleAutoRevealIfNeeded()
        }
    }

    /// 切换深浅色显示模式并持久化
    public func setDarkMode(_ option: String) {
        UserDefaults.standard.set(option, forKey: "settings_dark_mode_option")
    }

    /// 当前持久化的深浅色选项
    public var currentDarkModeOption: String {
        UserDefaults.standard.string(forKey: "settings_dark_mode_option") ?? "auto"
    }
}
