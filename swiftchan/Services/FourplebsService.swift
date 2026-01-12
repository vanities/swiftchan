//
//  FourplebsService.swift
//  swiftchan
//
//  Service for fetching archived threads from 4plebs.org
//  API docs: https://4plebs.org/docs/foolfuuka/
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

    enum FourplebsError: Error, LocalizedError {
        case unsupportedBoard
        case notFound
        case networkError(Error)
        case decodingError(Error)
        case invalidResponse

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
    /// - Parameters:
    ///   - board: The board name (must be supported by 4plebs)
    ///   - threadNum: The thread number
    /// - Returns: Array of Post objects
    func getThread(board: String, threadNum: Int) async throws -> [Post] {
        guard Self.isSupported(board: board) else {
            throw FourplebsError.unsupportedBoard
        }

        let urlString = "\(baseURL)/_/api/chan/thread/?board=\(board)&num=\(threadNum)"
        guard let url = URL(string: urlString) else {
            throw FourplebsError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.setValue("swiftchan-ios/1.0", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FourplebsError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FourplebsError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw FourplebsError.notFound
        case 429:
            // Rate limited - treat as network error
            throw FourplebsError.networkError(URLError(.networkConnectionLost))
        default:
            throw FourplebsError.networkError(URLError(.badServerResponse))
        }

        do {
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

            let posts = thread.toPosts(board: board)
            if posts.isEmpty {
                throw FourplebsError.notFound
            }

            return posts
        } catch let error as FourplebsError {
            throw error
        } catch {
            throw FourplebsError.decodingError(error)
        }
    }
}
