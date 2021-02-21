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

public extension UIFont {

    enum Leading {
        case loose
        case tight
    }

    private func addingAttributes(_ attributes: [UIFontDescriptor.AttributeName: Any]) -> UIFont {
        return UIFont(descriptor: fontDescriptor.addingAttributes(attributes), size: pointSize)
    }

    static func system(size: CGFloat, weight: UIFont.Weight, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size).fontDescriptor
            .addingAttributes([
                UIFontDescriptor.AttributeName.traits: [
                    UIFontDescriptor.TraitKey.weight: weight.rawValue
                ]
            ]).withDesign(design)!
        return UIFont(descriptor: descriptor, size: size)
    }

    static func system(_ style: UIFont.TextStyle, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).withDesign(design)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func weight(_ weight: UIFont.Weight) -> UIFont {
        return addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight.rawValue
            ]
        ])
    }

    func italic() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func bold() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func leading(_ leading: Leading) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(leading == .loose ? .traitLooseLeading : .traitTightLeading)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func smallCaps() -> UIFont {
        return addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kLowerCaseType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kLowerCaseSmallCapsSelector
                ],
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kUpperCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func lowercaseSmallCaps() -> UIFont {
        return addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kLowerCaseType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kLowerCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func uppercaseSmallCaps() -> UIFont {
        return addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kUpperCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func monospacedDigit() -> UIFont {
        return addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
                ]
            ]
        ])
    }

}
extension String {
  /*
   Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
   - Parameter length: Desired maximum lengths of a string
   - Parameter trailing: A 'String' that will be appended after the truncation.
    
   - Returns: 'String' object.
  */
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
}
