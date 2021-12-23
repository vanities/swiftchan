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
    @State var backgrounding: Bool = false

    var authorized: Bool {
        return (biometricsEnabled && didUnlockBiometrics) || !biometricsEnabled
    }

    var body: some View {
        ZStack {
            if (biometricsEnabled && didUnlockBiometrics) ||
                !biometricsEnabled {
                BoardsView()
                    .blur(radius: backgrounding || !authorized ? 10 : 0)
            }

            // privacy splash
            Image("swallow")
                .renderingMode(.template)
                .resizable()
                .zIndex(1)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.primary)
                .frame(width: 100)
                .opacity(backgrounding || !authorized ? 1 : 0)

        }
        .environmentObject(appState)
        .environmentObject(appContext)
        .onChange(of: biometricsEnabled) { enabled in
            if enabled {
                appContext.requestBiometricUnlock()
            }
        }
        .onAppear {
            if biometricsEnabled {
                appContext.requestBiometricUnlock()
            }
        }
        .onChange(of: scenePhase) { value in
            switch value {
            case .background, .inactive:
                withAnimation(.linear(duration: 0.1)) {
                    backgrounding = true
                }
                didUnlockBiometrics = false
            case .active:
                if biometricsEnabled, !didUnlockBiometrics {
                    appContext.requestBiometricUnlock { success in
                        didUnlockBiometrics = success
                    }
                }
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
