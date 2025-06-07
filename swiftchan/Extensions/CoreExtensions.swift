//
//  CoreExtensions.swift
//  swiftchan
//
//  Created on 11/26/20.
//

import SwiftUI

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
        return Media.detect(url: self) == .webm
    }
    func isImage() -> Bool {
        return Media.detect(url: self) == .image
    }
    func isGif() -> Bool {
        return Media.detect(url: self) == .gif
    }
    static let appScheme: String = "swiftchan"

    enum DetailType: String {
        case reply = "/reply"
        case board = "/board"
        case none
    }

    func getDetailType() -> DetailType {
        return DetailType(rawValue: path) ?? .none
    }

    static func inThreadReply(id: String) -> Self {
        Self(string: "swiftchan:\(URL.DetailType.reply.rawValue)?id=\(id)")!
    }

    static func board(name: String) -> Self {
        Self(string: "swiftchan:\(URL.DetailType.board.rawValue)?name=\(name)")!
    }

}

extension CaseIterable where Self: Equatable {
    mutating func next() {
        let allCases = Self.allCases
        // just a sanity check, as the possibility of a enum case to not be
        // present in `allCases` is quite low
        guard let selfIndex = allCases.firstIndex(of: self) else { return }
        let nextIndex = Self.allCases.index(after: selfIndex)
        self = allCases[nextIndex == allCases.endIndex ? allCases.startIndex : nextIndex]
    }
}

//https://stackoverflow.com/questions/31443645/simplest-way-to-throw-an-error-exception-with-a-custom-message-in-swift/40629365#40629365
extension String: @retroactive Error {}

extension UIScreen {
    static var height: CGFloat {
        self.main.bounds.height
    }
    static var halfHeight: CGFloat {
        self.height / 2
    }
    static var width: CGFloat {
        self.main.bounds.width
    }
    static var halfWidth: CGFloat {
        self.width / 2
    }
}

extension Collection where Element: Identifiable {
    func index(matching element: Element) -> Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
}

extension URLSession {
    func download(from url: URL, delegate: URLSessionTaskDelegate? = nil, progress parent: Progress) async throws -> (URL, URLResponse) {
        try await download(for: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad), progress: parent)
    }

    func download(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil, progress: Progress) async throws -> (URL, URLResponse) {
        let bufferSize = 65_536
        let estimatedSize: Int64 = 1_000_000

        let (asyncBytes, response) = try await bytes(for: request, delegate: delegate)
        let expectedLength = response.expectedContentLength                             // note, if server cannot provide expectedContentLength, this will be -1
        await MainActor.run { [expectedLength, estimatedSize] in
            progress.totalUnitCount = expectedLength > 0 ? expectedLength : estimatedSize
        }

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        guard let output = OutputStream(url: fileURL, append: false) else {
            throw URLError(.cannotOpenFile)
        }
        output.open()

        var buffer = Data()
        if expectedLength > 0 {
            buffer.reserveCapacity(min(bufferSize, Int(expectedLength)))
        } else {
            buffer.reserveCapacity(bufferSize)
        }

        var count: Int64 = 0
        for try await byte in asyncBytes {
            try Task.checkCancellation()

            count += 1
            buffer.append(byte)

            if buffer.count >= bufferSize {
                try output.write(buffer)
                buffer.removeAll(keepingCapacity: true)

                if expectedLength < 0 || count > expectedLength {
                    await MainActor.run { [count, estimatedSize] in
                        progress.totalUnitCount = count + estimatedSize
                    }
                }
                await MainActor.run { [count] in
                    progress.completedUnitCount = count
                }
            }
        }

        if !buffer.isEmpty {
            try output.write(buffer)
        }

        output.close()

        await MainActor.run { [count] in
            progress.totalUnitCount = count
            progress.completedUnitCount = count
        }

        return (fileURL, response)
    }
}

extension OutputStream {
    /// Write `Data` to `OutputStream`
    ///
    /// - parameter data:
    /// The `Data` to write.

    enum OutputStreamError: Error {
        case stringConversionFailure
        case bufferFailure
        case writeFailure
    }

    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws in
            guard var pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw OutputStreamError.bufferFailure
            }

            var bytesRemaining = buffer.count

            while bytesRemaining > 0 {
                let bytesWritten = write(pointer, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    throw OutputStreamError.writeFailure
                }

                bytesRemaining -= bytesWritten
                pointer += bytesWritten
            }
        }
    }
}

extension Date {
    static func isFourchanBday() -> Bool {
        var day = DateComponents()
        day.month = 10
        day.day = 1
        day.year = Calendar.current.component(.year, from: Date())
        if let date = Calendar.current.date(from: day) {
            return Calendar.current.isDateInToday(date)
        }
        return false
    }

    static func isChristmas() -> Bool {
        var christmasEve = DateComponents()
        christmasEve.month = 12
        christmasEve.day = 24
        christmasEve.year = Calendar.current.component(.year, from: Date())

        var christmas = DateComponents()
        christmas.month = 12
        christmas.day = 25
        christmas.year = Calendar.current.component(.year, from: Date())

        var christmasAfter = DateComponents()
        christmasAfter.month = 12
        christmasAfter.day = 26
        christmasAfter.year = Calendar.current.component(.year, from: Date())

        if let christmasEveDate = Calendar.current.date(from: christmasEve),
           let christmasDate = Calendar.current.date(from: christmas),
           let christmasAfterDate = Calendar.current.date(from: christmasAfter) {
            return Calendar.current.isDateInToday(christmasEveDate) ||
                Calendar.current.isDateInToday(christmasDate) ||
                Calendar.current.isDateInToday(christmasAfterDate)
        }
        return false
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
