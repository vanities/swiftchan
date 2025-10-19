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
    @Binding var presentingToastMessage: String?

    @ViewBuilder
    var body: some View {
        if canShowContextMenu {
            Button {
                UIPasteboard.general.string = url.absoluteString
                debugPrint("📋 Copied URL to pasteboard: \(url.absoluteString)")
                notificationGenerator.notificationOccurred(.success)
                notifySuccess(for: url, message: "URL Copied")
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
                    notifySuccess(for: cachedURL, message: "GIF Copied")
                } else if let image = UIImage(data: data) {
                    UIPasteboard.general.image = image
                    notifySuccess(for: cachedURL, message: "Image Copied")
                } else {
                    notifyFailure(message: "Could not copy image")
                    return
                }
            }
        }
    }

    private func saveToPhotos() {
        ImageSaver.saveImageToPhotoAlbum(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    notifySuccess(for: url, message: "Saved to Photos")
                case .failure(let error):
                    notifyFailure(message: error.localizedDescription)
                }
            }
        }
    }

    private func notifySuccess(for url: URL, message: String = "Success!") {
        notificationGenerator.notificationOccurred(.success)

        // Set state before showing toast
        presentingToastResult = .success(url)
        presentingToastMessage = message

        debugPrint("✅ Setting toast state - message: \(message), result: success")

        // Show toast after state is set
        presentingToast = true
    }

    private func notifyFailure(message: String) {
        notificationGenerator.notificationOccurred(.error)
        let error = NSError(domain: "MediaContextMenu", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        presentingToastResult = .failure(error)
        presentingToastMessage = message
        presentingToast = true
    }
}
