//
//  ContentView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import Defaults

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @Default(.biometricsEnabled) var biometricsEnabled
    @Default(.didUnlockBiometrics) var didUnlockBiometrics

    @StateObject private var appState = AppState()
    @StateObject private var appContext = AppContext()
    @State var showPrivacyView = false

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
        .environmentObject(appState)
        .environmentObject(appContext)
        .onChange(of: biometricsEnabled) { enabled in
            if enabled {
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
        .onChange(of: scenePhase) { value in
            switch value {
            case .background:
                withAnimation {
                    showPrivacyView = true
                }
                didUnlockBiometrics = false
            case .inactive:
                withAnimation {
                    showPrivacyView = true
                }
            case .active:
                if biometricsEnabled, !didUnlockBiometrics {
                    appContext.requestBiometricUnlock { success in
                        didUnlockBiometrics = success
                        showPrivacyView = success
                    }
                }
                withAnimation {
                    showPrivacyView = false
                }
            @unknown default:
                withAnimation {
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
