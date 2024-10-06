//
//  AppState.swift
//  swiftchan
//
//  Created by vanities on 11/25/20.
//

import SwiftUI
import Kingfisher
import FourChan
import LocalAuthentication

@Observable @MainActor
class AppState {
    var showingCatalogMenu: Bool = false
    var vlcPlayerControlModifier: VLCPlayerControlModifier?
    var showingBottomSheet = false
    var selectedBottomSheetPost: Post?
    var selectedTab: Tabs = .boards

    func requestBiometricUnlock(complete: ((Bool) -> Void)? = nil) {
        let context = LAContext()

        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            if context.biometryType != .none {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "To access your data") { (success, _) in
                    complete?(success)
                    UserDefaults.setDidUnlokcBiometrics(value: success)
                }
            }
        }
    }
}
