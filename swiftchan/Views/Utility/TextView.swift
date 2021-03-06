//
//  TextView.swift
//  swiftchan
//
//  Created by vanities on 2/20/21.
//
// Courtesy of https://gist.github.com/shaps80/8a3170160f80cfdc6e8179fa0f5e1621

import SwiftUI

struct TextView: View {
    @State var height: CGFloat = 200
    let attributedText: NSAttributedString
    var dynamicHeight: Bool = true

    init (_ attributedText: NSAttributedString, trailingLength: Int? = nil,
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
            self.attributedText = trailingComment.attributedSubstring(
                from: NSRange(location: 0, length: trailingComment.length)
            )
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
            // .frameTextView(self.attributedText, maxWidth: geo.size.width, maxHeight: .greatestFiniteMagnitude)
            .frame(height: self.dynamicHeight ? height : 150)
    }
}

struct SwiftUITextView: UIViewRepresentable {

    @Binding var height: CGFloat
    let dynamicHeight: Bool
    let attributedText: NSAttributedString

    init(attributedText: NSAttributedString,
         height: Binding<CGFloat>,
         dynamicHeight: Bool) {
        self._height = height
        self.attributedText = attributedText
        self.dynamicHeight = dynamicHeight
    }

    func makeUIView(context: Context) -> UITextView {
        // WHY IS THIS GETTING SPAMMED?!
        let view = UITextView()

        view.attributedText = attributedText
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero
        view.backgroundColor = UIColor.clear
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        view.isEditable = false
        view.alwaysBounceVertical = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.dataDetectorTypes = .link

        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        self.fitHeight(view)
    }

    func fitHeight(_ view: UITextView) {
        guard dynamicHeight == true else { return }
        let newHeight = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude)).height
        // guard self.height != newHeight else { return }
        DispatchQueue.main.async {
            self.height = newHeight
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 5) {
            TextView(NSAttributedString(string: """
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

struct GeometryGetter: View {
    @Binding var rect: CGRect

    var body: some View {
        return GeometryReader { geometry in
            self.makeView(geometry: geometry)
        }
    }

    func makeView(geometry: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            self.rect = geometry.frame(in: .global)
        }

        return Rectangle().fill(Color.clear)
    }
}
