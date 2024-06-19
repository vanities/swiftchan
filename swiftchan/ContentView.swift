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
    @AppStorage("biometricsEnabled") var biometricsEnabled = false
    @AppStorage("didUnlockBiometrics") var didUnlockBiometrics = true

    @State private var appState = AppState()
    @State private var appContext = AppContext()
    @State var showPrivacyView = false
    @State private var lastBackgroundTimestamp: Date?

    var body: some View {
        ZStack {
            BoardsView()

            if let fullscreen = appState.fullscreen {
                fullscreen.view
                    .matchedGeometryEffect(
                        id: FullscreenModal.id,
                        in: fullscreen.nspace
                    )
                    .onTapGesture {
                        withAnimation {
                            appState.setFullscreen(nil)
                        }
                    }
                    .zIndex(1)
            }
        }
        .privacyView(enabled: $showPrivacyView)
        .environment(appState)
        .environment(appContext)
        .onChange(of: biometricsEnabled) {
            if biometricsEnabled {
                showPrivacyView = true
                appContext.requestBiometricUnlock()
            }
        }
        .onAppear {
            if biometricsEnabled {
                showPrivacyView = true
                appContext.requestBiometricUnlock()
            }
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                withAnimation(.linear(duration: 0.05)) {
                    showPrivacyView = true
                }
                didUnlockBiometrics = false
                lastBackgroundTimestamp = Date()
            case .inactive:
                withAnimation(.linear(duration: 0.05)) {
                    showPrivacyView = true
                }
            case .active:
                if let lastBackgroundTimestamp = lastBackgroundTimestamp {
                    let timeInBackground = Date().timeIntervalSince(lastBackgroundTimestamp)
                    if timeInBackground >= 60 {
                        if biometricsEnabled, !didUnlockBiometrics {
                            appContext.requestBiometricUnlock { success in
                                didUnlockBiometrics = success
                                showPrivacyView = success
                            }
                        }
                    }
                } else {
                    didUnlockBiometrics = true
                }
                withAnimation(.linear(duration: 0.05)) {
                    showPrivacyView = false
                }
            @unknown default:
                withAnimation(.linear(duration: 0.05)) {
                    showPrivacyView = true
                }
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
