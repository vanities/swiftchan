//
//  AppState.swift
//  swiftchan
//
//  Created by vanities on 11/25/20.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var fullscreenView: (AnyView)?
    @Published var showingCatalogMenu: Bool = false
}
