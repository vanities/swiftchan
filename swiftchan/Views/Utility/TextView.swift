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
    @State private var height: CGFloat = 44
    var attributedText: NSMutableAttributedString
    var dynamicHeight: Bool = true

    init (_ attributedText: NSMutableAttributedString, trailingLength: Int? = nil,
          dynamicHeight: Bool = true) {
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
        self.dynamicHeight = dynamicHeight
        // swiftlint:enable force_cast
    }

    var body: some View {
        SwiftUITextView(attributedText: attributedText,
                        height: self.$height,
                        dynamicHeight: dynamicHeight)
            .frame(height: self.dynamicHeight ? self.height : 200)
    }
}

struct SwiftUITextView: UIViewRepresentable {

    @Binding var height: CGFloat
    var dynamicHeight: Bool
    private let attributedText: NSMutableAttributedString

    init(attributedText: NSMutableAttributedString,
         height: Binding<CGFloat>,
         dynamicHeight: Bool) {

        self._height = height
        self.attributedText = attributedText
        self.dynamicHeight = dynamicHeight
    }

    func makeUIView(context: Context) -> UITextView {
        // WHY IS THIS GETTING SPAMMED?!
        // print("make")
        let view = UITextView(frame: .zero)
        DispatchQueue.main.async {
            view.textContainer.lineFragmentPadding = 0
            view.textContainerInset = .zero
            view.backgroundColor = UIColor.clear
            view.adjustsFontForContentSizeCategory = true
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            view.isEditable = false
            view.isSelectable = true
            view.isScrollEnabled = false
            view.dataDetectorTypes = .link
        }

        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        guard dynamicHeight == true else { return  }
        view.attributedText = attributedText

        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        guard self.height != newSize.height else { return }
        DispatchQueue.main.async { // << fixed
            self.height = view.sizeThatFits(newSize).height
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 5) {
            TextView(NSMutableAttributedString(string: """
No.21374000 Sticky Closed

                        This board is for the discussion of topics related to business, economics, financial markets, securities, currencies (including cryptocurrencies), commodities, etc -- as well as topics relating to starting and running a business.

                        Discussions of government policy must be strictly limited to economic policies (fiscal and monetary). Discussions of a political nature should be posted on >>>/pol/. Global Rule 3 is also obviously in effect.

                        Note: /biz/ is NOT a place for ADVERTISING or SOLICITING. Do NOT use it to promote your business, ventures, or anything you may have an interest in. Anything that looks remotely like advertising or soliciting will be removed. Begging/asking (including tipping) for cryptocurrencies or asking for money/capital is also strictly forbidden.
"""))
                .border(Color.black, width: 1)
                .padding()
        }
        // .previewLayout(.sizeThatFits)
    }
}
