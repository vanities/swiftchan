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
            BoardsView(viewModel: boardViewModel)
                .blur(radius: backgrounding ? 10 : 0)

            if let fullscreenView = appState.fullscreenView {
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
                .opacity(backgrounding ? 1 :0)

        }
        .environmentObject(appState)
        .onChange(of: scenePhase) { value in
            switch value {
            case .background, .inactive:
                withAnimation(.linear(duration: 0.1)) {
                    backgrounding = true
                }
            case .active:
                withAnimation(.linear(duration: 0.1)) {
                    backgrounding = false
                }
            @unknown default:
                backgrounding = true
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
