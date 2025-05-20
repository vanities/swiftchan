//
//  ContentView.swift
//  swiftchan
//
//  Created on 10/31/20.
//

import SwiftUI
import FourChan


struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("biometricsEnabled") private var biometricsEnabled = false
    @AppStorage("didUnlockBiometrics") private var didUnlockBiometrics = true

    @State private var appState = AppState()
    @State private var showPrivacyView = false
    @State private var lastBackgroundTimestamp: Date?

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            Tab("Boards", systemImage: "list.bullet", value: .boards) {
                BoardsView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .privacyView(enabled: $showPrivacyView)
        .environment(appState)
        .onChange(of: biometricsEnabled) {
            if biometricsEnabled {
                showPrivacyView = true
                appState.requestBiometricUnlock()
            }
        }
        .onAppear {
            if biometricsEnabled {
                showPrivacyView = true
                appState.requestBiometricUnlock()
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
                    if timeInBackground >= 60, biometricsEnabled, !didUnlockBiometrics {
                        appState.requestBiometricUnlock { success in
                            didUnlockBiometrics = success
                            showPrivacyView = !success
                        }
                    } else {
                        withAnimation(.linear(duration: 0.05)) {
                            showPrivacyView = false
                        }
                    }
                } else {
                    didUnlockBiometrics = true
                    withAnimation(.linear(duration: 0.05)) {
                        showPrivacyView = false
                    }
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
#Preview {
    ContentView()
}
#endif
