//
//  TextView.swift
//  swiftchan
//
//  Created by vanities on 2/20/21.
//
// Courtesy of https://gist.github.com/shaps80/8a3170160f80cfdc6e8179fa0f5e1621

import SwiftUI

struct TextView: View {

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var calculatedHeight: CGFloat = 44

    private var attributedText: NSMutableAttributedString = .init()
    private var placeholderFont: Font = .body
    private var placeholderAlignment: TextAlignment = .leading
    private var foregroundColor: UIColor = .label
    private var autocapitalization: UITextAutocapitalizationType = .sentences
    private var multilineTextAlignment: NSTextAlignment = .left
    private var font: UIFont = .preferredFont(forTextStyle: .body)
    private var returnKeyType: UIReturnKeyType?
    private var clearsOnInsertion: Bool = false
    private var autocorrection: UITextAutocorrectionType = .default
    private var truncationMode: NSLineBreakMode = .byTruncatingTail
    private var isSecure: Bool = false
    private var isEditable: Bool = true
    private var isSelectable: Bool = true
    private var isScrollingEnabled: Bool = false
    private var enablesReturnKeyAutomatically: Bool?
    private var autoDetectionTypes: UIDataDetectorTypes = []

    init (_ attributedText: NSMutableAttributedString, trailingLength: Int? = nil) {
        // swiftlint:disable force_cast
        if let trailingLength = trailingLength {
            let trailingComment = attributedText.attributedSubstring(
                from: NSRange(location: 0,
                              length: min(attributedText.length, trailingLength)
                )
            ).mutableCopy() as! NSMutableAttributedString

            if trailingComment.length ==  trailingLength {
                let trail = NSMutableAttributedString(string: "...")
                trail.addAttributes([.font: UIFont.preferredFont(forTextStyle: .body),
                                     .foregroundColor: UIColor.label],
                                    range: NSRange(location: 0, length: trail.length))
                trailingComment.append(trail)
            }
            self.attributedText = trailingComment
        } else {
            self.attributedText = attributedText
        }
        // swiftlint:enable force_cast
    }

    var body: some View {
        SwiftUITextView(attributedText: attributedText,
                        foregroundColor: foregroundColor,
                        font: font,
                        multilineTextAlignment: multilineTextAlignment,
                        autocapitalization: autocapitalization,
                        returnKeyType: returnKeyType,
                        clearsOnInsertion: clearsOnInsertion,
                        autocorrection: autocorrection,
                        truncationMode: truncationMode,
                        isSecure: isSecure,
                        isEditable: isEditable,
                        isSelectable: isSelectable,
                        isScrollingEnabled: isScrollingEnabled,
                        enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
                        autoDetectionTypes: autoDetectionTypes,
                        calculatedHeight: $calculatedHeight)
            .frame(
                minHeight: isScrollingEnabled ? 0 : calculatedHeight,
                maxHeight: isScrollingEnabled ? .infinity : calculatedHeight
            )
    }
}

extension TextView {

    func autoDetectDataTypes(_ types: UIDataDetectorTypes) -> TextView {
        var view = self
        view.autoDetectionTypes = types
        return view
    }

    func foregroundColor(_ color: UIColor) -> TextView {
        var view = self
        view.foregroundColor = color
        return view
    }

    func autocapitalization(_ style: UITextAutocapitalizationType) -> TextView {
        var view = self
        view.autocapitalization = style
        return view
    }

    func multilineTextAlignment(_ alignment: TextAlignment) -> TextView {
        var view = self
        view.placeholderAlignment = alignment
        switch alignment {
        case .leading:
            view.multilineTextAlignment = layoutDirection ~= .leftToRight ? .left : .right
        case .trailing:
            view.multilineTextAlignment = layoutDirection ~= .leftToRight ? .right : .left
        case .center:
            view.multilineTextAlignment = .center
        }
        return view
    }

    func font(_ font: UIFont) -> TextView {
        var view = self
        view.font = font
        return view
    }

    func placeholderFont(_ font: Font) -> TextView {
        var view = self
        view.placeholderFont = font
        return view
    }

    func fontWeight(_ weight: UIFont.Weight) -> TextView {
        font(font.weight(weight))
    }

    func clearOnInsertion(_ value: Bool) -> TextView {
        var view = self
        view.clearsOnInsertion = value
        return view
    }

    func disableAutocorrection(_ disable: Bool?) -> TextView {
        var view = self
        if let disable = disable {
            view.autocorrection = disable ? .no : .yes
        } else {
            view.autocorrection = .default
        }
        return view
    }

    func isEditable(_ isEditable: Bool) -> TextView {
        var view = self
        view.isEditable = isEditable
        return view
    }

    func isSelectable(_ isSelectable: Bool) -> TextView {
        var view = self
        view.isSelectable = isSelectable
        return view
    }

    func enableScrolling(_ isScrollingEnabled: Bool) -> TextView {
        var view = self
        view.isScrollingEnabled = isScrollingEnabled
        return view
    }

    func returnKey(_ style: UIReturnKeyType?) -> TextView {
        var view = self
        view.returnKeyType = style
        return view
    }

    func automaticallyEnablesReturn(_ value: Bool?) -> TextView {
        var view = self
        view.enablesReturnKeyAutomatically = value
        return view
    }

    func truncationMode(_ mode: Text.TruncationMode) -> TextView {
        var view = self
        switch mode {
        case .head: view.truncationMode = .byTruncatingHead
        case .tail: view.truncationMode = .byTruncatingTail
        case .middle: view.truncationMode = .byTruncatingMiddle
        @unknown default:
            fatalError("Unknown text truncation mode")
        }
        return view
    }

}

private struct SwiftUITextView: UIViewRepresentable {

    @Binding private var calculatedHeight: CGFloat

    private let attributedText: NSMutableAttributedString
    private let foregroundColor: UIColor
    private let autocapitalization: UITextAutocapitalizationType
    private let multilineTextAlignment: NSTextAlignment
    private let font: UIFont
    private let returnKeyType: UIReturnKeyType?
    private let clearsOnInsertion: Bool
    private let autocorrection: UITextAutocorrectionType
    private let truncationMode: NSLineBreakMode
    private let isSecure: Bool
    private let isEditable: Bool
    private let isSelectable: Bool
    private let isScrollingEnabled: Bool
    private let enablesReturnKeyAutomatically: Bool?
    private var autoDetectionTypes: UIDataDetectorTypes = []

    init(attributedText: NSMutableAttributedString,
         foregroundColor: UIColor,
         font: UIFont,
         multilineTextAlignment: NSTextAlignment,
         autocapitalization: UITextAutocapitalizationType,
         returnKeyType: UIReturnKeyType?,
         clearsOnInsertion: Bool,
         autocorrection: UITextAutocorrectionType,
         truncationMode: NSLineBreakMode,
         isSecure: Bool,
         isEditable: Bool,
         isSelectable: Bool,
         isScrollingEnabled: Bool,
         enablesReturnKeyAutomatically: Bool?,
         autoDetectionTypes: UIDataDetectorTypes,
         calculatedHeight: Binding<CGFloat>) {

        _calculatedHeight = calculatedHeight

        self.attributedText = attributedText
        self.foregroundColor = foregroundColor
        self.font = font
        self.multilineTextAlignment = multilineTextAlignment
        self.autocapitalization = autocapitalization
        self.returnKeyType = returnKeyType
        self.clearsOnInsertion = clearsOnInsertion
        self.autocorrection = autocorrection
        self.truncationMode = truncationMode
        self.isSecure = isSecure
        self.isEditable = isEditable
        self.isSelectable = isSelectable
        self.isScrollingEnabled = isScrollingEnabled
        self.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
        self.autoDetectionTypes = autoDetectionTypes
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.text = ""
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero
        view.backgroundColor = UIColor.clear
        view.adjustsFontForContentSizeCategory = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
            view.attributedText = attributedText
            view.textAlignment = multilineTextAlignment
            view.autocapitalizationType = autocapitalization
            view.autocorrectionType = autocorrection
            view.isEditable = isEditable
            view.isSelectable = isSelectable
            view.isScrollEnabled = isScrollingEnabled
            view.dataDetectorTypes = autoDetectionTypes

            SwiftUITextView.recalculateHeight(view: view, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        guard result.wrappedValue != newSize.height else { return }
        DispatchQueue.main.async { // call in next render cycle.
            result.wrappedValue = newSize.height
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 5) {
            TextView(NSMutableAttributedString(string: ""))
                .font(.system(.body, design: .serif))
                .placeholderFont(Font.system(.body, design: .serif))
                .border(Color.black, width: 1)
                .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
