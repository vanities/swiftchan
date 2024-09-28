//
//  AppState.swift
//  swiftchan
//
//  Created by vanities on 11/25/20.
//

import SwiftUI
import Kingfisher
import FourChan

@Observable @MainActor
class AppState {
    var showingCatalogMenu: Bool = false
    var vlcPlayerControlModifier: VLCPlayerControlModifier?
    var showingBottomSheet = false
    var selectedBottomSheetPost: Post?
    var scrollViewPositions: [Int: Int] = [:]
}
