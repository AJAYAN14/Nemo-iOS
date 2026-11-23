import SwiftUI

/// 单词列表界面状态中枢。
@MainActor
@Observable
final class WordListStore {
    var allWords: [Word] = []
    var selectedLevel: JLPTLevel = .all
    var selectedFilter: StudyFilter = .all
    var searchText: String = ""
    var isLoading: Bool = true
    var isSyncing: Bool = false
    var syncStatusText: String? = nil
    var errorMessage: String? = nil

    /// 标题：全量时显示“单词列表”，选中分级时动态联动
    var headerTitle: String {
        if selectedLevel == .all {
            return "单词列表"
        } else {
            return "单词列表 (\(selectedLevel.rawValue))"
        }
    }

    /// 各等级统计字典
    var countsByLevel: [JLPTLevel: Int] {
        var dict: [JLPTLevel: Int] = [:]
        for level in [JLPTLevel.n1, .n2, .n3, .n4, .n5] {
            dict[level] = allWords.filter { $0.level.uppercased() == level.rawValue }.count
        }
        return dict
    }

    /// 根据当前所选等级与搜索词过滤后的单词列表
    var filteredWords: [Word] {
        allWords.filter { word in
            let matchLevel: Bool
            if selectedLevel == .all {
                matchLevel = true
            } else {
                matchLevel = word.level.uppercased() == selectedLevel.rawValue
            }
            let matchQuery = word.matches(query: searchText)
            return matchLevel && matchQuery
        }
    }

    /// 初始化载入：优先读取本地离线沙盒，若无数据则自动触发云端拉取
    func loadInitialData() async {
        do {
            let cached = try await DictionaryLocalStorage.shared.loadWords()
            if !cached.isEmpty {
                self.allWords = cached
                self.isLoading = false
                return
            }
        } catch {
            // 本地读取异常时继续尝试云端拉取
        }

        await syncFromRemote()
    }

    /// 从 Supabase 云端全量同步词库并持久化到本地
    func syncFromRemote() async {
        isSyncing = true
        errorMessage = nil
        syncStatusText = "正在连接云端词库..."

        do {
            let remoteWords = try await SupabaseDictionaryService.shared.fetchAllWords { current, total in
                Task { @MainActor in
                    self.syncStatusText = "正在下载词库 (\(current)/\(total))..."
                }
            }

            if !remoteWords.isEmpty {
                try await DictionaryLocalStorage.shared.saveWords(remoteWords)
                self.allWords = remoteWords
            }
            self.isLoading = false
            self.isSyncing = false
            self.syncStatusText = nil
        } catch {
            self.errorMessage = "词库同步失败，请检查网络连接"
            self.isLoading = false
            self.isSyncing = false
            self.syncStatusText = nil
        }
    }

    /// 原生下拉刷新增量触发
    func refresh() async {
        await syncFromRemote()
    }
}

/// 单词列表主界面视图（支持二级推入导航与底层悬浮胶囊搜索栏规范）。
public struct WordListView: View {
    @State private var store = WordListStore()
    @State private var showScrollToTop: Bool = false

    public init() {}

    public var body: some View {
        ScrollViewReader { scrollProxy in
            VStack(spacing: 8) {
                // 苹果原生状态分段控制器
                Picker("学习状态", selection: $store.selectedFilter) {
                    ForEach(StudyFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 4)

                // 列表内容区域
                ZStack(alignment: .bottomTrailing) {
                    Color(uiColor: .systemGroupedBackground)
                        .ignoresSafeArea()

                    if store.isLoading {
                        DictionarySkeletonView()
                    } else if store.isSyncing && store.allWords.isEmpty {
                        syncingProgressCard
                    } else if store.filteredWords.isEmpty {
                        emptyStateView
                    } else {
                        wordsListView(scrollProxy: scrollProxy)
                    }

                    // 词库通用磨砂回顶悬浮按钮（100% 对齐 Android LibraryScrollToTopButton）
                    if showScrollToTop {
                        LibraryScrollToTopButton {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                scrollProxy.scrollTo("TOP_ANCHOR", anchor: .top)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: store.selectedFilter)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: store.selectedLevel)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showScrollToTop)
            .onChange(of: store.searchText) { _, _ in
                showScrollToTop = false
                scrollProxy.scrollTo("TOP_ANCHOR", anchor: .top)
            }
            .onChange(of: store.selectedFilter) { _, _ in
                showScrollToTop = false
                scrollProxy.scrollTo("TOP_ANCHOR", anchor: .top)
            }
            .onChange(of: store.selectedLevel) { _, _ in
                showScrollToTop = false
                scrollProxy.scrollTo("TOP_ANCHOR", anchor: .top)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .background {
            NemoTabBarFollowsThePush()
        }
        .navigationTitle(store.headerTitle)
        .navigationBarTitleDisplayMode(.inline)
        // 100% 对齐参考项目 Clash-Client 原生架构：placement: .toolbar + DefaultToolbarItem(kind: .search, placement: .bottomBar)
        .searchable(
            text: $store.searchText,
            placement: .toolbar,
            prompt: Text("搜索单词、假名或释义")
        )
        .toolbar {
            // 顶栏右侧：原生分级筛选菜单
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("JLPT 等级筛选") {
                        Button {
                            withAnimation { store.selectedLevel = .all }
                        } label: {
                            if store.selectedLevel == .all {
                                Label("全部级别 (\(store.allWords.count) 词)", systemImage: "checkmark")
                            } else {
                                Text("全部级别 (\(store.allWords.count) 词)")
                            }
                        }

                        Divider()

                        ForEach([JLPTLevel.n5, .n4, .n3, .n2, .n1]) { level in
                            let count = store.countsByLevel[level] ?? 0
                            Button {
                                withAnimation { store.selectedLevel = level }
                            } label: {
                                if store.selectedLevel == level {
                                    Label("\(level.rawValue) (\(count) 词)", systemImage: "checkmark")
                                } else {
                                    Text("\(level.rawValue) (\(count) 词)")
                                }
                            }
                        }
                    }
                } label: {
                    Label(
                        "等级筛选",
                        systemImage: store.selectedLevel == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
                    )
                    .font(.body)
                }
            }

            // 底部悬浮搜索栏：原生指派至 .bottomBar
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
        }
        .toolbar(.hidden, for: .tabBar)
        // 原生下拉刷新
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.loadInitialData()
        }
    }

    // MARK: - 单词列表渲染（基于 Cell 复用 List 保证大体量满帧，支持入场动效）
    private func wordsListView(scrollProxy: ScrollViewProxy) -> some View {
        List {
            Color.clear
                .frame(height: 0.1)
                .id("TOP_ANCHOR")
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            ForEach(Array(store.filteredWords.enumerated()), id: \.element.id) { index, word in
                WordListItemView(word: word)
                    .animateListItem()
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onAppear {
                        if index >= 6 {
                            if !showScrollToTop {
                                showScrollToTop = true
                            }
                        } else if index <= 2 {
                            if showScrollToTop {
                                showScrollToTop = false
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - 首次同步进度卡片
    private var syncingProgressCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(store.syncStatusText ?? "正在从云端拉取词库...")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("首次同步约 9,800+ 词条，完成持久化后可全离线秒开")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 32)
    }

    // MARK: - 搜索空状态
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            if !store.searchText.isEmpty {
                Text("未找到与 “\(store.searchText)” 相关的单词")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else if let error = store.errorMessage {
                Text(error)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button("重试同步") {
                    Task { await store.syncFromRemote() }
                }
                .font(.callout.weight(.semibold))
                .buttonStyle(.borderedProminent)
            } else {
                Text("暂无 \(store.selectedLevel.title) 级别的单词")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
    }
}
