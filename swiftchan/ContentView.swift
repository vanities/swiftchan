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
    @StateObject private var userSettings = UserSettings()
    @StateObject private var appState = AppState()

    @State var backgrounding: Bool = false

    var body: some View {
        ZStack {
            BoardsView(viewModel: BoardsView.ViewModel())
                .environmentObject(self.userSettings)
                .environmentObject(self.appState)
                .blur(radius: self.backgrounding ? 15 : 0)

            // privacy splash
            if self.backgrounding {
                Image("swallow")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.primary)
                    .frame(width: 100)
                    .zIndex(1)
                    .transition(AnyTransition.opacity)
            }

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
