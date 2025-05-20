//
//  UINavigationController.swift
//  swiftchan
//
//  Created on 9/27/24.
//

import SwiftUI

// https://stackoverflow.com/a/76976498/10865324
extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
