//
//  GalleryContextMenu.swift
//  swiftchan
//
//  Created on 10/29/21.
//

import SwiftUI
import UIKit

struct MediaContextMenu: View {
    let url: URL

    @State private var notificationGenerator = UINotificationFeedbackGenerator()
    @Binding var isExportingDocument: Bool
    @Binding private(set) var canShowContextMenu: Bool
    @Binding var presentingToast: Bool
    @Binding var presentingToastResult: Result<URL, Error>?

    @ViewBuilder
    var body: some View {
        if canShowContextMenu {
            Button {
                UIPasteboard.general.string = url.absoluteString
                notificationGenerator.notificationOccurred(.success)
                presentingToast = true
                presentingToastResult = .success(url)
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.copyToPasteboardButton)

            switch Media.detect(url: url) {
            case .image, .gif:
                Button {
                    copyImage()
                } label: {
                    Label("Copy Image", systemImage: "photo.on.rectangle")
                }

                Button {
                    saveToPhotos()
                } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.saveToPhotosButton)

            case .webm, .mp4, .none:
                Button {
                    isExportingDocument.toggle()
                } label: {
                    Label("Save to Files", systemImage: "folder")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.saveToFilesButton)
            }

            ShareLink(item: url) {
                Label("Share…", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func copyImage() {
        CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { cachedURL in
            DispatchQueue.main.async {
                guard let cachedURL = cachedURL,
                      let data = try? Data(contentsOf: cachedURL) else {
                    notifyFailure(message: "Could not copy image")
                    return
                }

                if cachedURL.isGif() {
                    UIPasteboard.general.setData(data, forPasteboardType: "com.compuserve.gif")
                } else if let image = UIImage(data: data) {
                    UIPasteboard.general.image = image
                } else {
                    notifyFailure(message: "Could not copy image")
                    return
                }

                notifySuccess(for: cachedURL)
            }
        }
    }

    private func saveToPhotos() {
        ImageSaver.saveImageToPhotoAlbum(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    notifySuccess(for: url)
                case .failure(let error):
                    notifyFailure(message: error.localizedDescription)
                }
            }
        }
    }

    private func notifySuccess(for url: URL) {
        notificationGenerator.notificationOccurred(.success)
        presentingToastResult = .success(url)
        presentingToast = true
    }

    private func notifyFailure(message: String) {
        notificationGenerator.notificationOccurred(.error)
        let error = NSError(domain: "MediaContextMenu", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        presentingToastResult = .failure(error)
        presentingToast = true
    }
}
