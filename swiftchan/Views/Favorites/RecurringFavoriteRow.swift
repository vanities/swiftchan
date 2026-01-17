//
//  RecurringFavoriteRow.swift
//  swiftchan
//
//  Row view for displaying a recurring favorite in the list.
//

import SwiftUI
import Kingfisher

struct RecurringFavoriteRow: View {
    let favorite: RecurringFavorite

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text("/\(favorite.boardName)/")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(favorite.effectiveDisplayName)
                    .font(.headline)
                    .lineLimit(1)

                if let lastMatched = favorite.lastMatchedAt {
                    Text("\(favorite.lastMatchCount) match\(favorite.lastMatchCount == 1 ? "" : "es") - \(lastMatched.timeAgoDisplay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not yet searched")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailUrl = favorite.lastThumbnailUrl {
            KFImage(thumbnailUrl)
                .placeholder {
                    placeholderView
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipped()
                .cornerRadius(8)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "repeat")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
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
                Image(systemName: "repeat")
                    .foregroundColor(.gray)
            }
    }
}

extension Date {
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#if DEBUG
#Preview {
    List {
        RecurringFavoriteRow(
            favorite: RecurringFavorite(
                searchPattern: "ptg",
                boardName: "g",
                displayName: "Python Thread General"
            )
        )
    }
    .modelContainer(for: RecurringFavorite.self, inMemory: true)
}
#endif
