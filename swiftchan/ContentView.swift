//
//  ContentView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var appState = AppState()
    @StateObject private var boardViewModel = BoardsView.ViewModel()

    @State var backgrounding: Bool = false

    var body: some View {
        ZStack {
            BoardsView(viewModel: self.boardViewModel)
                .environmentObject(self.appState)
                .blur(radius: self.backgrounding ? 10 : 0)

            if let fullscreenView = self.appState.fullscreenView {
                fullscreenView
            }

            // privacy splash
            Image("swallow")
                .renderingMode(.template)
                .resizable()
                .zIndex(1)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.primary)
                .frame(width: 100)
                .opacity(self.backgrounding ? 1 :0)

        }
        .onChange(of: self.scenePhase) { value in
            switch value {
            case .background, .inactive:
                withAnimation(.linear(duration: 0.1)) {
                    self.backgrounding = true
                }
            case .active:
                withAnimation(.linear(duration: 0.1)) {
                    self.backgrounding = false
                }
            @unknown default:
                self.backgrounding = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
