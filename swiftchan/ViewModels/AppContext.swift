//
//  AppContext.swift
//  swiftchan
//
//  Created by Adam Mischke on 12/22/21.
//

import Foundation
import SwiftUI
import LocalAuthentication
import Defaults

class AppContext: ObservableObject {
    func requestBiometricUnlock(complete: ((Bool) -> Void)? = nil) {
        let context = LAContext()

        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            if context.biometryType != .none {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "To access your data") { (success, _) in
                    DispatchQueue.main.async {
                        complete?(success)
                        Defaults[.didUnlockBiometrics] = success
                    }
                }
            }
        }
    }
}
