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
                    UIFontDescriptor.FeatureKey.type: kLowerCaseType,
                    UIFontDescriptor.FeatureKey.selector: kLowerCaseSmallCapsSelector
                ],
                [
                    UIFontDescriptor.FeatureKey.type: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.selector: kUpperCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func lowercaseSmallCaps() -> UIFont {
        return addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kLowerCaseType,
                    UIFontDescriptor.FeatureKey.selector: kLowerCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func uppercaseSmallCaps() -> UIFont {
        return addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.selector: kUpperCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func monospacedDigit() -> UIFont {
        return addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
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

extension Color {

    static func randomColor(seed: String) -> Color {

        var total: Int = 0
        for u in seed.unicodeScalars {
            total += Int(UInt32(u))
        }

        srand48(total * 200)
        let red = drand48()

        srand48(total)
        let green = drand48()

        srand48(total / 200)
        let blue = drand48()

        return Color(red: red, green: green, blue: blue)
    }
}

extension Color {

    // Check if the color is light or dark, as defined by the injected lightness threshold.
    // Some people report that 0.7 is best. I suggest to find out for yourself.
    // A nil value is returned if the lightness couldn't be determined.
    func isLight(threshold: Float = 0.5) -> Bool {
        let originalCGColor = self.cgColor

        // Now we need to convert it to the RGB colorspace. UIColor.white / UIColor.black are greyscale and not RGB.
        // If you don't do this then you will crash when accessing components index 2 below when evaluating greyscale colors.
        let RGBCGColor = originalCGColor?.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        guard let components = RGBCGColor?.components else {
            return true
        }
        guard components.count >= 3 else {
            return false
        }

        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
        return (brightness > threshold)
    }
}

extension String {
    func replacePattern(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSRange(location: 0, length: self.count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return self
        }
    }

    var fixZeroWidthSpace: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacePattern(pattern: "%E2%80%8B", replaceWith: "") ?? ""
    }
}

extension URL {
    func isWebm() -> Bool {
        return MediaDetector.detect(url: self) == .webm
    }
    func isImage() -> Bool {
        return MediaDetector.detect(url: self) == .image
    }
    func isGif() -> Bool {
        return MediaDetector.detect(url: self) == .gif
    }
}
