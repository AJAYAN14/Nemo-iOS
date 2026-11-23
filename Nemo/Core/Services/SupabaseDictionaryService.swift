import Foundation

/// Supabase 云端词库同步服务。
public actor SupabaseDictionaryService {
    public static let shared = SupabaseDictionaryService()

    private let endpoint = "https://ccggidebxekvqbpjktxl.supabase.co/rest/v1"
    private let apiKey = "sb_publishable_c6vmYxJAeY8mqXvitlb3Pw_WkrzsRqg"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// 获取云端词库元数据版本
    public func fetchSyncMeta() async throws -> SyncMeta? {
        guard let url = URL(string: "\(endpoint)/sync_meta?select=*&limit=1") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let metas = try JSONDecoder().decode([SyncMeta].self, from: data)
        return metas.first
    }

    /// 分批拉取全量单词数据
    public func fetchAllWords(
        onProgress: (@Sendable (Int, Int) -> Void)? = nil
    ) async throws -> [Word] {
        var allWords: [Word] = []
        var offset = 0
        let pageSize = 1000
        var totalCount = 9876

        let decoder = JSONDecoder()

        while true {
            try Task.checkCancellation()

            guard let url = URL(string: "\(endpoint)/dictionary_words?select=*&is_delisted=eq.false&order=id.asc") else {
                break
            }

            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("\(offset)-\(offset + pageSize - 1)", forHTTPHeaderField: "Range")
            request.setValue("count=exact", forHTTPHeaderField: "Prefer")
            request.timeoutInterval = 30

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 206 else {
                throw URLError(.badServerResponse)
            }

            if let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String ??
                httpResponse.allHeaderFields["content-range"] as? String {
                if let totalPart = contentRange.split(separator: "/").last,
                   let total = Int(totalPart) {
                    totalCount = total
                }
            }

            let batch = try decoder.decode([Word].self, from: data)
            if batch.isEmpty {
                break
            }

            allWords.append(contentsOf: batch)
            onProgress?(allWords.count, totalCount)

            if batch.count < pageSize || allWords.count >= totalCount {
                break
            }
            offset += pageSize
        }

        return allWords
    }

    /// 分批拉取全量语法数据
    public func fetchAllGrammars(
        onProgress: (@Sendable (Int, Int) -> Void)? = nil
    ) async throws -> [Grammar] {
        var allGrammars: [Grammar] = []
        var offset = 0
        let pageSize = 1000
        var totalCount = 741

        let decoder = JSONDecoder()

        while true {
            try Task.checkCancellation()

            guard let url = URL(string: "\(endpoint)/dictionary_grammars?select=*&is_delisted=eq.false&order=id.asc") else {
                break
            }

            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("\(offset)-\(offset + pageSize - 1)", forHTTPHeaderField: "Range")
            request.setValue("count=exact", forHTTPHeaderField: "Prefer")
            request.timeoutInterval = 30

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 206 else {
                throw URLError(.badServerResponse)
            }

            if let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String ??
                httpResponse.allHeaderFields["content-range"] as? String {
                if let totalPart = contentRange.split(separator: "/").last,
                   let total = Int(totalPart) {
                    totalCount = total
                }
            }

            let batch = try decoder.decode([Grammar].self, from: data)
            if batch.isEmpty {
                break
            }

            allGrammars.append(contentsOf: batch)
            onProgress?(allGrammars.count, totalCount)

            if batch.count < pageSize || allGrammars.count >= totalCount {
                break
            }
            offset += pageSize
        }

        return allGrammars
    }

    /// 增量拉取自指定时间戳以来更新的单词列表
    public func fetchWordsModifiedSince(timestamp: String) async throws -> [Word] {
        var allWords: [Word] = []
        var offset = 0
        let pageSize = 1000
        let decoder = JSONDecoder()

        guard let encodedTimestamp = timestamp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        while true {
            try Task.checkCancellation()

            guard let url = URL(string: "\(endpoint)/dictionary_words?select=*&updated_at=gt.\(encodedTimestamp)&order=updated_at.asc") else {
                break
            }

            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("\(offset)-\(offset + pageSize - 1)", forHTTPHeaderField: "Range")
            request.timeoutInterval = 30

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 206 else {
                throw URLError(.badServerResponse)
            }

            let batch = try decoder.decode([Word].self, from: data)
            if batch.isEmpty {
                break
            }

            allWords.append(contentsOf: batch)
            if batch.count < pageSize {
                break
            }
            offset += pageSize
        }

        return allWords
    }

    /// 增量拉取自指定时间戳以来更新的语法列表
    public func fetchGrammarsModifiedSince(timestamp: String) async throws -> [Grammar] {
        var allGrammars: [Grammar] = []
        var offset = 0
        let pageSize = 1000
        let decoder = JSONDecoder()

        guard let encodedTimestamp = timestamp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        while true {
            try Task.checkCancellation()

            guard let url = URL(string: "\(endpoint)/dictionary_grammars?select=*&updated_at=gt.\(encodedTimestamp)&order=updated_at.asc") else {
                break
            }

            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("\(offset)-\(offset + pageSize - 1)", forHTTPHeaderField: "Range")
            request.timeoutInterval = 30

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 206 else {
                throw URLError(.badServerResponse)
            }

            let batch = try decoder.decode([Grammar].self, from: data)
            if batch.isEmpty {
                break
            }

            allGrammars.append(contentsOf: batch)
            if batch.count < pageSize {
                break
            }
            offset += pageSize
        }

        return allGrammars
    }
}
