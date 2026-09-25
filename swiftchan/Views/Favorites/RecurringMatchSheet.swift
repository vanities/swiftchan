//
//  RecurringMatchSheet.swift
//  swiftchan
//
//  Sheet for displaying loading state and thread picker for recurring favorites.
//

import SwiftUI

struct RecurringMatchSheet: View {
    let favorite: RecurringFavorite
    @State private var viewModel = RecurringFavoriteViewModel()
    let onSelect: (SwiftchanPost) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchAttempt = UUID()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case .noMatches:
                    noMatchesView
                case .singleMatch(let post):
                    singleMatchView(post)
                case .multipleMatches(let posts):
                    multipleMatchesView(posts)
                case .error(let message):
                    errorView(message)
                }
            }
            .navigationTitle("Find Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.reset()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task(id: searchAttempt) {
            await viewModel.findMatches(for: favorite)
            guard case .singleMatch(let post) = viewModel.state else { return }
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            guard !Task.isCancelled, case .singleMatch(let current) = viewModel.state, current.id == post.id else { return }
            dismiss()
            onSelect(post)
        }
        .onDisappear { viewModel.reset() }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching /\(favorite.boardName)/ for \"\(favorite.searchPattern)\"...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noMatchesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Threads Found")
                .font(.title2)
                .fontWeight(.semibold)
            Text("No threads matching \"\(favorite.searchPattern)\" were found on /\(favorite.boardName)/.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Search Again") { searchAttempt = UUID() }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func singleMatchView(_ post: SwiftchanPost) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            Text("Thread Found!")
                .font(.title2)
                .fontWeight(.semibold)
            Text(post.post.sub?.clean ?? "Thread #\(post.post.no)")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Label("\(post.post.replies ?? 0)", systemImage: "bubble.right")
                Label("\(post.post.images ?? 0)", systemImage: "photo")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func multipleMatchesView(_ posts: [SwiftchanPost]) -> some View {
        List {
            Section {
                Text("Found \(posts.count) matching threads. Select one to open:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Section("Threads (Newest First)") {
                ForEach(posts) { post in
                    Button {
                        viewModel.reset()
                        dismiss()
                        onSelect(post)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.post.sub?.clean ?? "Thread #\(post.post.no)")
                                .font(.headline)
                                .lineLimit(2)
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Label("\(post.post.replies ?? 0)", systemImage: "bubble.right")
                                Label("\(post.post.images ?? 0)", systemImage: "photo")
                                Text("No. \(post.post.no)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") { searchAttempt = UUID() }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
