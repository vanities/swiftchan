//
//  MediaContextMenu.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/21/21.
//

import SwiftUI

extension View {
    func mediaDownloadMenu(url: URL) -> some View {
        modifier(MediaDownloadMenuModifier(url: url))
    }
}

struct MediaDownloadMenuModifier: ViewModifier {
    let url: URL

    @State var isExportingDocument: Bool = false
    @State private var presentingToast: Bool = false
    @State private var presentingToastResult: Result<URL, Error>?
    @State private var showContextMenu: Bool = true

    func body(content: Content) -> some View {
        content
            .fileExporter(isPresented: $isExportingDocument,
                          document: FileExport(url: url.absoluteString),
                          contentType: .image,
                          onCompletion: { result in
                presentingToastResult = result
                presentingToast = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            })
            .contextMenu {
                MediaContextMenu(
                    url: url,
                    isExportingDocument: $isExportingDocument,
                    showContextMenu: $showContextMenu,
                    presentingToast: $presentingToast,
                    presentingToastResult: $presentingToastResult
                )
            }
            .toast(isPresented: $presentingToast, dismissAfter: 1.0, content: { Toast(presentingToastResult: presentingToastResult) })
    }
}
