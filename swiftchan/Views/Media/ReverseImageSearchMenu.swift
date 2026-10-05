import SwiftUI

struct ReverseImageSearchMenu: View {
    let media: Media
    var identifier = "Image Search"

    var body: some View {
        if ReverseImageSearchProvider.sourceURL(for: media) != nil {
            Menu {
                ReverseImageSearchLinks(media: media)
                Divider()
                Link("Open Original", destination: media.url)
                    .accessibilityIdentifier("Open Original Media")
            } label: {
                Label(ReverseImageSearchProvider.usesThumbnail(for: media) ? "Search Thumbnail" : "Image Search",
                      systemImage: "photo.badge.magnifyingglass")
            }
            .accessibilityIdentifier(identifier)
        }
    }
}

struct ReverseImageSearchLinks: View {
    let media: Media

    var body: some View {
        Section(ReverseImageSearchProvider.usesThumbnail(for: media) ? "Search Video Thumbnail" : "Reverse Image Search") {
            ForEach(ReverseImageSearchProvider.allCases) { provider in
                if let url = provider.searchURL(for: media) {
                    Link(provider.name, destination: url)
                        .accessibilityIdentifier("Image Search \(provider.name)")
                }
            }
        }
    }
}
