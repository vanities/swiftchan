//
//  MediaContextMenu.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/21/21.
//

import SwiftUI

extension View {
    func mediaDownloadMenu(url: URL, canShowContextMenu: Binding<Bool>) -> some View {
        modifier(MediaDownloadMenuModifier(url: url, canShowContextMenu: canShowContextMenu))
    }
}

struct MediaDownloadMenuModifier: ViewModifier {
    let url: URL
    @Binding var canShowContextMenu: Bool

    @State var isExportingDocument: Bool = false
    @State private var presentingToast: Bool = false
    @State private var presentingToastResult: Result<URL, Error>?

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: $isExportingDocument,
                          document: FileExport(url: url.absoluteString),
                          contentType: .image
            ) { result in
                presentingToastResult = result
                presentingToast = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            .contextMenu {
                MediaContextMenu(
                    url: url,
                    isExportingDocument: $isExportingDocument,
                    canShowContextMenu: $canShowContextMenu,
                    presentingToast: $presentingToast,
                    presentingToastResult: $presentingToastResult
                )
            }
            .toast(isPresented: $presentingToast, dismissAfter: 0.2, content: { Toast(presentingToastResult: presentingToastResult) })
    }
}
