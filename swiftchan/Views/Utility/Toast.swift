//
//  Toast.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/7/21.
//

import SwiftUI
import ToastUI

struct Toast<T>: View {
    let presentingToastResult: Result<T, Error>?

    @ViewBuilder
    var body: some View {
        switch presentingToastResult {
        case .success(_):
            ToastView("Success!", content: {}, background: {Color.clear})
                .toastViewStyle(SuccessToastViewStyle())
                .accessibilityIdentifier(AccessibilityIdentifiers.successToastText)
        case .failure(_):
            ToastView("Failure", content: {}, background: {Color.clear})
                .toastViewStyle(ErrorToastViewStyle())
        case .none:
            ToastView("Failure", content: {}, background: {Color.clear})
                .toastViewStyle(ErrorToastViewStyle())

        }
    }
}
