//
//  AttributedTextView.swift
//  swiftchan
//
//  Created by vanities on 2/21/21.
//

import SwiftUI

struct AttributedTextView: View {

    @State private var calculatedHeight: CGFloat = 44

    private var attributedText: NSMutableAttributedString = .init()

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
                        calculatedHeight: $calculatedHeight)
            .frame(
                minHeight: calculatedHeight,
                maxHeight: calculatedHeight
            )
    }
}

private struct SwiftUITextView: UIViewRepresentable {

    @Binding private var calculatedHeight: CGFloat
    private let attributedText: NSMutableAttributedString

    init(attributedText: NSMutableAttributedString,
         calculatedHeight: Binding<CGFloat>) {

        _calculatedHeight = calculatedHeight
        self.attributedText = attributedText
    }

    func makeUIView(context: Context) -> UILabel {
        let view = UILabel()
        view.adjustsFontForContentSizeCategory = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.attributedText = attributedText
        SwiftUITextView.recalculateHeight(view: view, result: $calculatedHeight)
        return view
    }

    func updateUIView(_ view: UILabel, context: Context) {
            // view.attributedText = attributedText
        // SwiftUITextView.recalculateHeight(view: view, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UILabel, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        guard result.wrappedValue != newSize.height else { return }
        DispatchQueue.main.async { // call in next render cycle.
            result.wrappedValue = newSize.height
        }
    }
}

struct AttributedTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 5) {
            AttributedTextView(NSMutableAttributedString(string: ""))
                .border(Color.black, width: 1)
                .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
