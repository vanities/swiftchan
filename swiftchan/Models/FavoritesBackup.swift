import Foundation

struct FavoritesBackup: Codable, Equatable {
    static let maximumBytes = 5 * 1_024 * 1_024

    struct Thread: Codable, Equatable {
        var board: String
        let number: Int
        let title: String
        let createdAt: Date
        let savedAt: Date
        var key: String { "\(board)/\(number)" }
    }

    struct General: Codable, Equatable {
        var board: String
        var tag: String
        var name: String?
        let createdAt: Date
        var key: String { "\(board)/\(tag)" }
    }

    struct ImportPlan {
        let threads: [Thread]
        let generals: [General]
        let replies: [Reply]
        let skipped: Int
    }

    struct Reply: Codable, Equatable {
        var board: String
        let threadID: Int
        let postID: Int
        let title: String
        let text: String
        let savedAt: Date
        var key: String { "\(board)/\(postID)" }
    }

    let format: String
    let version: Int
    let exportedAt: Date
    var threads: [Thread]
    var generals: [General]
    var replies: [Reply]?

    init(threads: [Thread], generals: [General], replies: [Reply]? = nil, exportedAt: Date = Date()) {
        format = "swiftchan.favorites"
        version = replies?.isEmpty == false ? 2 : 1
        self.exportedAt = exportedAt
        self.threads = threads
        self.generals = generals
        self.replies = replies
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(validated())
        guard data.count <= Self.maximumBytes else { throw BackupError.tooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= maximumBytes else { throw BackupError.tooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Self.self, from: data).validated()
    }

    func validated() throws -> Self {
        guard format == "swiftchan.favorites" else { throw BackupError.invalidFile }
        guard version == 1 || version == 2 else { throw BackupError.unsupportedVersion }
        var result = self
        for index in result.threads.indices {
            guard let board = Deeplinker.normalizedBoard(result.threads[index].board), result.threads[index].number > 0 else {
                throw BackupError.invalidFile
            }
            result.threads[index].board = board
        }
        for index in result.generals.indices {
            guard let board = Deeplinker.normalizedBoard(result.generals[index].board) else { throw BackupError.invalidFile }
            let tag = result.generals[index].tag.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/")).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty, !tag.contains("/"), tag.rangeOfCharacter(from: .newlines) == nil else { throw BackupError.invalidFile }
            result.generals[index].board = board
            result.generals[index].tag = "/\(tag.lowercased())/"
            let name = result.generals[index].name?.trimmingCharacters(in: .whitespacesAndNewlines)
            result.generals[index].name = name?.isEmpty == false ? name : nil
        }
        if var replies = result.replies {
            for index in replies.indices {
                guard let board = Deeplinker.normalizedBoard(replies[index].board),
                      replies[index].threadID > 0, replies[index].postID >= replies[index].threadID else { throw BackupError.invalidFile }
                replies[index].board = board
            }
            result.replies = replies
        }
        return result
    }

    /// Existing favorites win; repeated records in a file are imported only once.
    func importPlan(threadKeys: Set<String>, generalKeys: Set<String>, replyKeys: Set<String> = []) throws -> ImportPlan {
        let backup = try validated()
        var threadsSeen = threadKeys
        var generalsSeen = generalKeys
        var repliesSeen = replyKeys
        let threads = backup.threads.filter { threadsSeen.insert($0.key).inserted }
        let generals = backup.generals.filter { generalsSeen.insert($0.key).inserted }
        let replies = (backup.replies ?? []).filter { repliesSeen.insert($0.key).inserted }
        return ImportPlan(threads: threads, generals: generals, replies: replies,
                          skipped: backup.threads.count + backup.generals.count + (backup.replies?.count ?? 0)
                          - threads.count - generals.count - replies.count)
    }

    enum BackupError: LocalizedError {
        case invalidFile, unsupportedVersion, tooLarge

        var errorDescription: String? {
            switch self {
            case .invalidFile: return "This file contains invalid favorites. Nothing was imported."
            case .unsupportedVersion: return "This backup needs a newer version of Swiftchan."
            case .tooLarge: return "Choose a favorites backup of 5 MB or smaller."
            }
        }
    }
}
