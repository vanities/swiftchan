//
//  AppState.swift
//  swiftchan
//
//  Created on 11/25/20.
//

import SwiftUI
import Kingfisher
import FourChan
import LocalAuthentication

@Observable @MainActor
class AppState {
    var showingCatalogMenu: Bool = false
    var showingBottomSheet = false
    var selectedBottomSheetPost: Post?
    var selectedTab: Tabs = .boards

    func requestBiometricUnlock(complete: (@Sendable (Bool) -> Void)? = nil) {
        let context = LAContext()

        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            if context.biometryType != .none {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "To access your data") { (success, _) in
                    Task { @MainActor in
                        complete?(success)
                        UserDefaults.setDidUnlokcBiometrics(value: success)
                    }
                }
            }
        }
    }
}
