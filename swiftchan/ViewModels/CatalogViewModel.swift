//
//  CatalogViewModel.swift
//  swiftchan
//
//  Created on 11/12/20.
//

import SwiftUI
import FourChan
import Combine

@Observable
class CatalogViewModel {
    enum LoadingState {
        case initial, loading, loaded, error

    }

    var boardName: String
    let prefetcher = Prefetcher.shared

    private(set) var posts = [SwiftchanPost]()
    var state = LoadingState.initial
    private(set) var progressText = ""
    private var cancellables: Set<AnyCancellable> = []

    func getFilteredPosts(searchText: String) -> [SwiftchanPost] {
        if searchText.isEmpty {
            return posts
        } else {
            return posts.compactMap { swiftChanPost in
                let commentAndSubject = "\(swiftChanPost.post.com?.clean.lowercased() ?? "") \(swiftChanPost.post.sub?.clean.lowercased() ?? "")"
                return commentAndSubject.contains(searchText.lowercased()) ? swiftChanPost : nil
            }
        }
    }

    init(boardName: String) {
        self.boardName = boardName
    }

    @MainActor
    func load() async {
        state = .loading
        progressText = "Loading /\(boardName)/ 0%"
        do {
            let catalog = try await FourChanAsyncService.shared.getCatalog(boardName: boardName) { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressText = "Loading /\(self?.boardName ?? "")/ \(Int(progress * 100))%"
                }
            }
            var tempPosts: [SwiftchanPost] = []
            var index = 0
            for page in catalog {
                for thread in page.threads {
                    let comment: AttributedString
                    if let com = thread.com {
                        comment = CommentParser(comment: com).getComment()
                    } else {
                        comment = AttributedString()
                    }
                    tempPosts.append(SwiftchanPost(post: thread, boardName: boardName, comment: comment, index: index))
                    index += 1
                }
            }
            posts = tempPosts

            if posts.count > 0 {
                state = .loaded
                handleSorting(value: UserDefaults.getSortFilesBy(boardName: boardName), attributeKey: "files")
                handleSorting(value: UserDefaults.getSortRepliesBy(boardName: boardName), attributeKey: "replies")

                NotificationCenter.default.publisher(for: .sortingRepliesDidChange)
                    .sink { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.handleSorting(value: UserDefaults.getSortRepliesBy(boardName: self!.boardName), attributeKey: "replies")
                        }
                    }
                    .store(in: &cancellables)

                NotificationCenter.default.publisher(for: .sortingFilesDidChange)
                    .sink { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.handleSorting(value: UserDefaults.getSortFilesBy(boardName: self!.boardName), attributeKey: "files")
                        }
                    }
                    .store(in: &cancellables)
            } else {
                state = .error
            }
        } catch {
            state = .error
        }
    }

    func handleSorting(value: SortRow.SortType, attributeKey: String) {
        guard value != .none else {
            return
        }
        posts.sort { (lhs: SwiftchanPost, rhs: SwiftchanPost) -> Bool in
            // https://stackoverflow.com/questions/26829304/assigning-operator-function-in-variable
            let operation: (Int, Int) -> Bool = value == .ascending ? (<) : (>)
            return operation(
                lhs.post.valueByPropertyName(name: attributeKey),
                rhs.post.valueByPropertyName(name: attributeKey)
            )
        }
    }

    @MainActor
    func prefetch() {
        let urls = posts.compactMap { post in
            return post.post.getMediaUrl(boardId: boardName, thumbnail: !UserDefaults.getFullImagesForThumbanails())
        }
        prefetcher.prefetchImages(urls: urls)
    }

    @MainActor
    func stopPrefetching() {
        prefetcher.stopPrefetching()
    }

}
