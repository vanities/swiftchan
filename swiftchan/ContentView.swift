//
//  ContentView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct ContentView: View {
    @StateObject private var userSettings = UserSettings()

    var body: some View {
        BoardsView(viewModel: BoardsView.ViewModel())
            .environmentObject(self.userSettings)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
