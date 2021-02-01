//
//  CoreExtensions.swift
//  swiftchan
//
//  Created by vanities on 11/26/20.
//

import SwiftUI

let window = UIApplication.shared.windows[0]
let topPadding = window.safeAreaInsets.top
let bottomPadding = window.safeAreaInsets.bottom
let safeAreaPadding = topPadding + bottomPadding

internal func getFlag(from countryCode: String) -> String {

    return countryCode
        .unicodeScalars
        .map({ 127397 + $0.value })
        .compactMap(UnicodeScalar.init)
        .map(String.init)
        .joined()
}

extension CGPoint {

    var angle: Angle? {
        guard x != 0 || y != 0 else { return nil }
        guard x != 0 else { return y > 0 ? Angle(degrees: 90) : Angle(degrees: 270) }
        guard y != 0 else { return x > 0 ? Angle(degrees: 0) : Angle(degrees: 180) }
        var angle = atan(abs(y) / abs(x)) * 180 / .pi
        switch (x, y) {
        case (let x, let y) where x < 0 && y < 0:
            angle = 180 + angle
        case (let x, let y) where x < 0 && y > 0:
            angle = 180 - angle
        case (let x, let y) where x > 0 && y < 0:
            angle = 360 - angle
        default:
            break
        }

        return .init(degrees: Double(angle))
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

}

extension Angle {
    var isAlongXAxis: Bool {
        let degrees = ((Int(self.degrees.rounded()) % 360) + 360) % 360
        return degrees >= 330 || degrees <= 30 || (degrees >= 150 && degrees <= 210)
    }

    var isAlongYAxis: Bool {
        let degrees = ((Int(self.degrees.rounded()) % 360) + 360) % 360
        return degrees < 330 || degrees > 30 || (degrees < 150 && degrees > 210)
    }
}
