//
//  FavoriteThreadRow.swift
//  swiftchan
//
//  Row view for displaying a favorite thread in the list.
//

import SwiftUI
import Kingfisher

struct FavoriteThreadRow: View {
    let favorite: FavoriteThread

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text("/\(favorite.boardName)/")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(favorite.title.isEmpty ? "Thread #\(favorite.threadId)" : favorite.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(favorite.replyCount)", systemImage: "bubble.right")
                    Label("\(favorite.imageCount)", systemImage: "photo")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailUrl = favorite.thumbnailUrl {
            KFImage(thumbnailUrl)
                .placeholder {
                    placeholderView
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipped()
                .cornerRadius(8)
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }
}

#if DEBUG
#Preview {
    List {
        FavoriteThreadRow(
            favorite: FavoriteThread(
                threadId: 123456,
                boardName: "pol",
                title: "Example Thread Title",
                thumbnailUrlString: nil,
                replyCount: 42,
                imageCount: 12,
                createdTime: Date()
            )
        )
    }
    .modelContainer(for: FavoriteThread.self, inMemory: true)
}
#endif
