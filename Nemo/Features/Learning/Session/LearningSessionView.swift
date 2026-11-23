//
//  LearningSessionView.swift
//  Nemo
//

import SwiftUI

/// 学习会话主全屏二级视图
public struct LearningSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings_dark_mode_option") private var storedDarkMode: String = "auto"
    @State private var store: LearningSessionStore
    @State private var showReportErrorSheet: Bool = false
    @State private var showLearningOverviewSheet: Bool = false
    @State private var showTypingPracticeSheet: Bool = false
    private let mode: LearningHomeStore.LearningMode
    private let dailyGoal: Int

    public init(
        mode: LearningHomeStore.LearningMode = .word,
        dailyGoal: Int = 20,
        store: LearningSessionStore? = nil
    ) {
        self.mode = mode
        self.dailyGoal = dailyGoal
        _store = State(wrappedValue: store ?? LearningSessionStore())
    }

    private var hasActiveItem: Bool {
        store.currentWord != nil || store.currentGrammar != nil
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.nemoGroupedBackground
                .ignoresSafeArea()

            if store.isSessionFinished, let stats = store.stats {
                VStack(spacing: 0) {
                    if stats.dailyStreak > 0 {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 13))
                            Text("已连续打卡 \(stats.dailyStreak) 天")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                        .padding(.top, 8)
                    }

                    LearningFinishedView(
                        stats: stats,
                        onFinish: {
                            dismiss()
                        },
                        onRestart: {
                            Task {
                                await store.loadRealSessionData(
                                    dailyGoal: dailyGoal,
                                    mode: mode == .word ? .word : .grammar
                                )
                            }
                        }
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                VStack(spacing: 0) {
                    if store.mode == .word, let word = store.currentWord {
                        SRSLearningCardView(
                            word: word,
                            isAnswerShown: store.isAnswerShown,
                            badgeType: store.currentBadgeType,
                            progress: store.progress,
                            queueCounts: store.queueCounts,
                            onRevealAnswer: {
                                store.revealAnswer()
                            },
                            onSpeakWord: {
                                store.speak(text: word.hiragana)
                            },
                            onSpeakText: { text in
                                store.speak(text: text)
                            },
                            isPlayingAudio: store.isPlayingAudio,
                            playingText: store.playingText,
                            onPracticeClick: {
                                showTypingPracticeSheet = true
                            },
                            isWhiteboardEnabled: store.isWhiteboardEnabled
                        )
                    } else if store.mode == .grammar, let grammar = store.currentGrammar {
                        SRSGrammarCardView(
                            grammar: grammar,
                            isAnswerShown: store.isAnswerShown,
                            badgeType: store.currentBadgeType,
                            progress: store.progress,
                            queueCounts: store.queueCounts,
                            onRevealAnswer: {
                                store.revealAnswer()
                            },
                            onSpeakText: { text in
                                store.speak(text: text)
                            },
                            isPlayingAudio: store.isPlayingAudio,
                            playingText: store.playingText
                        )
                    } else {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(mode == .word ? "单词题库准备中..." : "语法题库准备中...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                // 底部常驻 SRS 评价操作栏
                VStack(spacing: 8) {
                    if hasActiveItem {
                        LearningSRSActionBar(
                            isFlipped: store.isAnswerShown,
                            ratingIntervals: store.ratingIntervals,
                            delayRemainingSeconds: store.delayRemainingSeconds,
                            onShowAnswer: {
                                store.revealAnswer()
                            },
                            onRating: { quality in
                                store.submitRating(quality)
                            }
                        )
                        .padding(.bottom, 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.nemoGroupedBackground.opacity(0),
                                    Color.nemoGroupedBackground.opacity(0.85),
                                    Color.nemoGroupedBackground
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea(edges: .bottom)
                        )
                    }
                }
            }

            // 顶部通知横幅
            if let toast = store.toastMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(toast)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThickMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 56)

                    Spacer()
                }
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.isSessionFinished)
        .animation(.easeInOut(duration: 0.25), value: store.toastMessage)
        .navigationTitle(store.isSessionFinished ? "学习完成" : (mode == .word ? "单词学习" : "语法学习"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if !store.isSessionFinished {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        if store.canUndo {
                            store.undo()
                        }
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!store.canUndo)

                    if store.remainingCount > 0 {
                        Button {
                            showLearningOverviewSheet = true
                        } label: {
                            HStack(spacing: 3) {
                                Text("剩余")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Text("\(store.remainingCount)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    moreOptionsMenu
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: "我在 Nemo 已经连续打卡 \(store.stats?.dailyStreak ?? 1) 天！今日达成 \(store.completedCount) 项日语卡片！"
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .background {
            NemoTabBarFollowsThePush()
        }
        .sheet(isPresented: $store.showRatingGuide) {
            RatingGuideSheet()
        }
        .sheet(isPresented: $showLearningOverviewSheet) {
            LearningOverviewSheet(
                store: store,
                dailyGoal: dailyGoal
            )
        }
        .sheet(isPresented: $showReportErrorSheet) {
            ContentReportSheet(
                mode: store.mode,
                onConfirm: { errType, details in
                    store.reportContentError(errorType: errType, description: details)
                }
            )
        }
        .sheet(isPresented: $showTypingPracticeSheet) {
            if let word = store.currentWord {
                TypingPracticeSheet(word: word)
            }
        }
        .task {
            if store.wordsQueue.isEmpty && store.grammarsQueue.isEmpty {
                await store.loadRealSessionData(
                    dailyGoal: dailyGoal,
                    mode: mode == .word ? .word : .grammar
                )
            }
        }
    }

    // MARK: - 更多操作菜单（严格以 Android 源码 LearnHeaderMoreMenu.kt 为样板对齐）
    private var moreOptionsMenu: some View {
        Menu {
            // 1. 评分说明 (rating_guide)
            Button {
                store.showRatingGuide = true
            } label: {
                Label("评分说明", systemImage: "info.circle")
            }

            // 2. 卡片操作项 (bury, suspend, report_error) - 仅在有剩余卡片时展示
            if store.remainingCount > 0 {
                Button {
                    store.buryCurrent()
                } label: {
                    Label("今日暂缓此项", systemImage: "calendar")
                }

                Button(role: .destructive) {
                    store.suspendCurrent()
                } label: {
                    Label("暂停此卡片", systemImage: "trash")
                }

                Button {
                    showReportErrorSheet = true
                } label: {
                    Label("报告条目错误", systemImage: "flag")
                }
            }

            Divider()

            // 3. 翻面自动朗读 (auto_audio) - 仅在单词模式下展示
            if store.mode == .word {
                Button {
                    store.isAutoAudioEnabled.toggle()
                } label: {
                    HStack {
                        Label("翻面自动朗读", systemImage: "speaker.wave.2")
                        if store.isAutoAudioEnabled {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            // 4. 显示答案等待 (delay) - 扁平开关与当前时长展示，支持开启时调节时长
            Button {
                store.isShowAnswerDelayEnabled.toggle()
            } label: {
                HStack {
                    Label(
                        store.isShowAnswerDelayEnabled ? "显示答案等待 (当前: \(store.showAnswerDelaySeconds)s)" : "显示答案等待 (已关闭)",
                        systemImage: "clock"
                    )
                    if store.isShowAnswerDelayEnabled {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            if store.isShowAnswerDelayEnabled {
                Menu {
                    ForEach([1, 2, 3, 5], id: \.self) { sec in
                        Button {
                            store.setShowAnswerDelay(seconds: sec)
                        } label: {
                            HStack {
                                Text("\(sec)s")
                                if store.showAnswerDelaySeconds == sec {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("等待时长 (\(store.showAnswerDelaySeconds)s)", systemImage: "timer")
                }
            }

            // 5. 自动翻面 (auto_reveal) - 扁平开关与当前时长展示，支持开启时调节时长
            Button {
                store.isAutoRevealAnswerEnabled.toggle()
            } label: {
                HStack {
                    Label(
                        store.isAutoRevealAnswerEnabled ? "自动翻面 (当前: \(store.autoRevealSeconds)s)" : "自动翻面 (已关闭)",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                    if store.isAutoRevealAnswerEnabled {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            if store.isAutoRevealAnswerEnabled {
                Menu {
                    ForEach([3, 5, 10], id: \.self) { sec in
                        Button {
                            store.setAutoRevealDuration(seconds: sec)
                        } label: {
                            HStack {
                                Text("\(sec)s")
                                if store.autoRevealSeconds == sec {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("翻面时长 (\(store.autoRevealSeconds)s)", systemImage: "clock.arrow.circlepath")
                }
            }

            // 6. 手写白板 (whiteboard)
            Button {
                store.isWhiteboardEnabled.toggle()
            } label: {
                HStack {
                    Label("手写白板", systemImage: "pencil.tip")
                    if store.isWhiteboardEnabled {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            // 7. 显示模式 (heading_display_mode)
            Section("显示模式") {
                Button {
                    store.setDarkMode("auto")
                    storedDarkMode = "auto"
                } label: {
                    HStack {
                        Label("自动模式", systemImage: "circle.lefthalf.filled")
                        if storedDarkMode == "auto" {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    store.setDarkMode("dark")
                    storedDarkMode = "dark"
                } label: {
                    HStack {
                        Label("深色模式", systemImage: "moon")
                        if storedDarkMode == "dark" {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    store.setDarkMode("light")
                    storedDarkMode = "light"
                } label: {
                    HStack {
                        Label("浅色模式", systemImage: "sun.max")
                        if storedDarkMode == "light" {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

/// 今日学习概览弹窗
struct LearningOverviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: LearningSessionStore
    let dailyGoal: Int

    private var modeText: String {
        store.mode == .word ? "单词" : "语法"
    }

    private var percent: Int {
        guard dailyGoal > 0 else { return 0 }
        return Int((Double(store.completedCount) / Double(dailyGoal)) * 100)
    }

    private var estMinutes: Int {
        max(1, (store.remainingCount * 15) / 60)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 今日目标完成度
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("今日目标完成度")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("\(store.completedCount) / \(dailyGoal) \(modeText)")
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Text("\(percent)%")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                    .padding(16)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // 剩余与预估时间
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("待处理剩余")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(store.remainingCount) \(modeText)")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("预估剩余耗时")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(store.remainingCount > 0 ? "约 \(estMinutes) 分钟" : "已全部完成")
                                .font(.headline.bold())
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // 队列分布
                    VStack(alignment: .leading, spacing: 12) {
                        Text("队列卡片分布")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            queueCard(title: "新学", count: store.queueCounts.newCount, color: .blue)
                            queueCard(title: "在学", count: store.queueCounts.learningCount, color: .cyan)
                            queueCard(title: "复习", count: store.queueCounts.reviewCount, color: .green)
                            queueCard(title: "重学", count: store.queueCounts.relearnCount, color: .orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 24)

                    Button {
                        dismiss()
                    } label: {
                        Text("继续学习")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .nemoPrimaryActionButtonStyle()
                    .nemoCapsuleButtonBorderShape()
                    .tint(.blue)
                }
                .padding(20)
            }
            .navigationTitle("今日学习概览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func queueCard(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// 内容错误报告弹窗
struct ContentReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mode: LearningSessionStore.SessionMode
    let onConfirm: (String, String?) -> Void

    @State private var selectedError: String = ""
    @State private var description: String = ""

    private var options: [String] {
        if mode == .word {
            return ["释义错误", "注音错误", "例句错误", "拼写错误", "词性错误", "其他问题"]
        } else {
            return ["解释错误", "接续错误", "注音错误", "例句错误", "级别错误", "其他问题"]
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(mode == .word ? "请选择当前单词内容的错误类型：" : "请选择当前语法内容的错误类型：")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(options, id: \.self) { opt in
                        Button {
                            selectedError = opt
                        } label: {
                            Text(opt)
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .foregroundStyle(selectedError == opt ? Color.red : Color.primary)
                                .background(selectedError == opt ? Color.red.opacity(0.12) : Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(selectedError == opt ? Color.red : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField("补充具体错误细节（选填，100字以内）", text: $description, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Spacer()

                HStack(spacing: 12) {
                    Button("我再想想") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .foregroundStyle(.secondary)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())

                    Button("确认反馈") {
                        onConfirm(selectedError.isEmpty ? (options.first ?? "其他问题") : selectedError, description.isEmpty ? nil : description)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .foregroundStyle(.white)
                    .background(Color.red)
                    .clipShape(Capsule())
                }
            }
            .padding(20)
            .navigationTitle("报告条目错误")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// 评分说明弹窗
struct RatingGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nemo 基于记忆遗忘曲线调度算法，根据你每次回答的真实反馈，动态计算最佳复习时机。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("四档评分指南") {
                    ratingItemRow(
                        title: "重来 (Again)",
                        color: .red,
                        subtitle: "完全没有印象，或拼写释义完全错误",
                        effect: "卡片将重新加入今日学习队列，并在数分钟内再次考核"
                    )

                    ratingItemRow(
                        title: "困难 (Hard)",
                        color: .orange,
                        subtitle: "回忆过程艰难，勉强拼凑或需要提示才想起",
                        effect: "卡片被判定为掌握较薄弱，安排较短的复习间隔"
                    )

                    ratingItemRow(
                        title: "良好 (Good)",
                        color: .blue,
                        subtitle: "在正常思考时间内正确回忆，符合预期",
                        effect: "标准稳步推进，记忆间隔将以基准倍率按天递增"
                    )

                    ratingItemRow(
                        title: "简单 (Easy)",
                        color: .green,
                        subtitle: "毫不费力瞬间秒答，极度熟练掌握",
                        effect: "大幅延长复习周期，避免对超熟词汇进行无效重复"
                    )
                }

                Section("卡片快捷操作") {
                    cardOpItemRow(
                        title: "今日暂缓此项 (Bury)",
                        icon: "calendar",
                        color: .blue,
                        description: "今日暂缓学习该卡片，从今日队列中移出，明日恢复正常学习计划。"
                    )

                    cardOpItemRow(
                        title: "暂停此卡片 (Suspend)",
                        icon: "trash",
                        color: .orange,
                        description: "彻底暂停该卡片，移出所有日常学习与复习队列，直到在词库管理中重新激活。"
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("评分说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func ratingItemRow(
        title: String,
        color: Color,
        subtitle: String,
        effect: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
            }
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.primary)
            Text(effect)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func cardOpItemRow(
        title: String,
        icon: String,
        color: Color,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Learning Session - Word") {
    LearningSessionView(mode: .word, dailyGoal: 20, store: LearningSessionStore.mock)
}

#Preview("Learning Session - Grammar") {
    LearningSessionView(mode: .grammar, dailyGoal: 10, store: LearningSessionStore.mockGrammar)
}
