//
//  AppState.swift
//  swiftchan
//
//  Created by vanities on 11/25/20.
//

import SwiftUI
import Kingfisher
import FourChan

class AppState: ObservableObject {
    @Published private(set) var fullscreen: FullscreenModel?
    @Published var showingCatalogMenu: Bool = false
    @Published var vlcPlayerControlModifier: VLCPlayerControlModifier?
    @Published var showingBottomSheet = false
    @Published var selectedBottomSheetPost: Post?

    func setFullscreen(_ fullscreen: FullscreenModel?) {
        self.fullscreen = fullscreen
    }
}
