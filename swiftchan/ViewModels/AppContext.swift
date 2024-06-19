//
//  AppContext.swift
//  swiftchan
//
//  Created by Adam Mischke on 12/22/21.
//

import SwiftUI
import LocalAuthentication

@Observable
class AppContext {
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
