//
//  FourplebsService.swift
//  swiftchan
//
//  Service for fetching archived threads from 4plebs.org
//  API docs: https://4plebs.org/docs/foolfuuka/
//
//  NOTE: API currently blocked by anti-bot protection ("Please wait" page).
//  For now, we just open the archive URL in Safari.
//  This code is kept for when the API becomes accessible.
//

import Foundation
import FourChan

@MainActor
final class FourplebsService {
    static let shared = FourplebsService()

    /// Boards archived by 4plebs
    static let supportedBoards: Set<String> = [
        "adv", "f", "hr", "mlpol", "mo", "o", "pol", "s4s", "sp", "tg", "trv", "tv", "x"
    ]

    /// Check if a board is archived by 4plebs
    static func isSupported(board: String) -> Bool {
        supportedBoards.contains(board.lowercased())
    }

    /// Get the archive URL for a thread (for opening in Safari)
    static func archiveUrl(board: String, threadNum: Int) -> URL? {
        guard isSupported(board: board) else { return nil }
        return URL(string: "https://archive.4plebs.org/\(board)/thread/\(threadNum)/")
    }

    enum FourplebsError: Error, LocalizedError {
        case unsupportedBoard
        case notFound
        case networkError(Error)
        case decodingError(Error)
        case invalidResponse
        case antiBot

        var errorDescription: String? {
            switch self {
            case .unsupportedBoard:
                return "This board is not archived by 4plebs"
            case .notFound:
                return "Thread not found in archive"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to parse archive response: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from archive"
            case .antiBot:
                return "Archive requires browser verification"
            }
        }
    }

    private let baseURL = "https://archive.4plebs.org"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Fetch an archived thread from 4plebs
    /// NOTE: Currently blocked by anti-bot protection. This is kept for future use.
    /// - Parameters:
    ///   - board: The board name (must be supported by 4plebs)
    ///   - threadNum: The thread number
    /// - Returns: FourplebsThread containing posts with media URLs
    func getThread(board: String, threadNum: Int) async throws -> FourplebsThread {
        print("DEBUG 4plebs: getThread called for /\(board)/\(threadNum)")
        guard Self.isSupported(board: board) else {
            throw FourplebsError.unsupportedBoard
        }

        let urlString = "\(baseURL)/_/api/chan/thread/?board=\(board)&num=\(threadNum)"
        guard let url = URL(string: urlString) else {
            throw FourplebsError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse

        print("DEBUG 4plebs: Fetching \(url)")
        do {
            (data, response) = try await session.data(for: request)
            print("DEBUG 4plebs: Got response, data size: \(data.count) bytes")
        } catch {
            print("DEBUG 4plebs: Network error: \(error)")
            throw FourplebsError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FourplebsError.invalidResponse
        }

        print("DEBUG 4plebs: Status code: \(httpResponse.statusCode)")

        // Check for anti-bot page
        if let responseString = String(data: data, encoding: .utf8) {
            if responseString.contains("Please wait") || responseString.contains("Just a moment") {
                print("DEBUG 4plebs: Anti-bot protection detected")
                throw FourplebsError.antiBot
            }
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw FourplebsError.notFound
        case 403, 429, 503:
            throw FourplebsError.antiBot
        default:
            throw FourplebsError.networkError(URLError(.badServerResponse))
        }

        do {
            // Debug: print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("DEBUG 4plebs raw response (first 500 chars): \(String(responseString.prefix(500)))")
            }

            let archiveResponse = try JSONDecoder().decode(FourplebsThreadResponse.self, from: data)

            // Check for error in response
            if let error = archiveResponse.error {
                if error.lowercased().contains("not found") || error.lowercased().contains("does not exist") {
                    throw FourplebsError.notFound
                }
                throw FourplebsError.invalidResponse
            }

            guard let thread = archiveResponse.thread else {
                throw FourplebsError.notFound
            }

            if thread.getAllPosts().isEmpty {
                throw FourplebsError.notFound
            }

            return thread
        } catch let error as FourplebsError {
            throw error
        } catch {
            print("DEBUG 4plebs: Decoding error: \(error)")
            throw FourplebsError.decodingError(error)
        }
    }
}
