import Foundation

/// 词库本地沙盒离线持久化存储管理器。
public actor DictionaryLocalStorage {
    public static let shared = DictionaryLocalStorage()

    private let fileManager = FileManager.default

    private var storageDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("NemoDictionary", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var wordsFileURL: URL {
        storageDirectory.appendingPathComponent("words_cache.json")
    }

    private var grammarsFileURL: URL {
        storageDirectory.appendingPathComponent("grammars_cache.json")
    }

    /// 检查本地是否已有单词缓存
    public func hasCachedWords() -> Bool {
        fileManager.fileExists(atPath: wordsFileURL.path)
    }

    /// 检查本地是否已有语法缓存
    public func hasCachedGrammars() -> Bool {
        fileManager.fileExists(atPath: grammarsFileURL.path)
    }

    /// 获取本地已缓存的单词总数
    public func getWordCount() -> Int {
        guard let words = try? loadWords() else { return 0 }
        return words.count
    }

    /// 获取本地已缓存的语法总数
    public func getGrammarCount() -> Int {
        guard let grammars = try? loadGrammars() else { return 0 }
        return grammars.count
    }

    /// 增量更新或追加单词
    public func upsertWords(_ newWords: [Word]) throws {
        let currentWords = (try? loadWords()) ?? []
        var wordMap = Dictionary(currentWords.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        for word in newWords {
            wordMap[word.id] = word
        }
        let merged = wordMap.values.sorted { $0.id < $1.id }
        try saveWords(merged)
    }

    /// 增量更新或追加语法
    public func upsertGrammars(_ newGrammars: [Grammar]) throws {
        let currentGrammars = (try? loadGrammars()) ?? []
        var grammarMap = Dictionary(currentGrammars.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        for grammar in newGrammars {
            grammarMap[grammar.id] = grammar
        }
        let merged = grammarMap.values.sorted { $0.id < $1.id }
        try saveGrammars(merged)
    }

    /// 持久化写入全量单词数据
    public func saveWords(_ words: [Word]) throws {
        let data = try JSONEncoder().encode(words)
        try data.write(to: wordsFileURL, options: [.atomic])
    }

    /// 从本地沙盒读取全量单词
    public func loadWords() throws -> [Word] {
        guard fileManager.fileExists(atPath: wordsFileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: wordsFileURL)
        return try JSONDecoder().decode([Word].self, from: data)
    }

    /// 持久化写入全量语法数据
    public func saveGrammars(_ grammars: [Grammar]) throws {
        let data = try JSONEncoder().encode(grammars)
        try data.write(to: grammarsFileURL, options: [.atomic])
    }

    /// 从本地沙盒读取全量语法
    public func loadGrammars() throws -> [Grammar] {
        guard fileManager.fileExists(atPath: grammarsFileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: grammarsFileURL)
        return try JSONDecoder().decode([Grammar].self, from: data)
    }

    /// 清空本地词库缓存
    public func clearCache() {
        try? fileManager.removeItem(at: wordsFileURL)
        try? fileManager.removeItem(at: grammarsFileURL)
    }
}
