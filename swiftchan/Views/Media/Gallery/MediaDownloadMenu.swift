//
//  MediaContextMenu.swift
//  swiftchan
//
//  Created on 11/21/21.
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
    @State private var presentingToastMessage: String?

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: $isExportingDocument,
                          document: FileExport(url: url.absoluteString),
                          contentType: .image
            ) { result in
                presentingToastResult = result

                switch result {
                case .success:
                    presentingToastMessage = "Saved to Files"
                case .failure(let error):
                    presentingToastMessage = error.localizedDescription
                }

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
                    presentingToastResult: $presentingToastResult,
                    presentingToastMessage: $presentingToastMessage
                )
            }
            .overlay(alignment: .center) {
                if presentingToast {
                    Group {
                        if let customMessage = presentingToastMessage, let result = presentingToastResult {
                            let _ = debugPrint("🍞 Toast showing - message: \(customMessage), result: \(String(describing: result))")

                            switch result {
                            case .success:
                                CustomToastView(message: customMessage, style: .success)
                            case .failure:
                                CustomToastView(message: customMessage, style: .error)
                            }
                        } else {
                            let _ = debugPrint("🍞 Toast showing fallback - message: \(presentingToastMessage ?? "nil"), result: \(String(describing: presentingToastResult))")
                            Toast(presentingToastResult: presentingToastResult)
                        }
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .zIndex(999)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                presentingToast = false
                            }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: presentingToast)
    }
}
