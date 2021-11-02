//
//  GalleryContextMenu.swift
//  swiftchan
//
//  Created by Adam Mischke on 10/29/21.
//

import SwiftUI

struct GalleryContextMenu: View {
    let url: URL

    @State private var notificationGenerator = UINotificationFeedbackGenerator()
    @Binding var isExportingDocument: Bool
    @Binding private(set) var showContextMenu: Bool
    @Binding var presentingToast: Bool
    @Binding var presentingToastResult: Result<URL, Error>?

    @ViewBuilder
    var body: some View {
        if showContextMenu {
            Button(action: {
                UIPasteboard.general.string = url.absoluteString
                notificationGenerator.notificationOccurred(.success)
                presentingToast = true
                presentingToastResult = .success(url)
            }, label: {
                Text("Copy URL")
                Image(systemName: "doc.on.doc")
            })
                .accessibilityIdentifier(AccessibilityIdentifiers.copyToPasteboardButton)
            switch MediaDetector.detect(url: url) {
            case .image, .gif:
                Group {
                Button(action: {
                    CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { result in
                        switch result {
                        case .success(let url):
                            let data = try? Data(contentsOf: url)
                            if let data = data {
                                UIPasteboard.general.image = UIImage(data: data)
                                presentingToastResult = .success(url)
                                notificationGenerator.notificationOccurred(.success)
                                presentingToast = true
                                return
                            }

                        default: break
                        }
                        presentingToastResult = .failure("Could not copy image")
                        notificationGenerator.notificationOccurred(.error)
                        presentingToast = true

                    }

                }, label: {
                    Text("Copy Image")
                    Image(systemName: "photo.on.rectangle")
                })

                Button(action: {
                    let imageSaver = ImageSaver(completionHandler: { result in
                        switch result {
                        case .success(_):
                            presentingToastResult = .success(url)
                            notificationGenerator.notificationOccurred(.success)
                        case .failure(let error):
                            presentingToastResult = .failure(error)
                            notificationGenerator.notificationOccurred(.error)
                        }
                        presentingToast = true
                    })
                    imageSaver.saveImageToPhotos(url: url)
                }, label: {
                    Text("Save to Photos")
                    Image(systemName: "square.and.arrow.down")
                })
                    .accessibilityIdentifier(AccessibilityIdentifiers.saveToPhotosButton)
            }
            case .webm, .none:
                Button(action: {
                    isExportingDocument.toggle()
                }, label: {
                    Text("Save to Files")
                    Image(systemName: "folder")
                })
                    .accessibilityIdentifier(AccessibilityIdentifiers.saveToFilesButton)
            }
        }
    }
}
