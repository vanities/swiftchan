import SwiftUI

struct LabelView: View {

    @State private var height: CGFloat = .zero
    let attributedText: NSAttributedString
    var dynamicHeight: Bool

    init(_ attributedString: NSAttributedString,
         trailingLength: Int? = nil,
         dynamicHeight: Bool = false) {
        self.dynamicHeight = dynamicHeight
        // swiftlint:disable force_cast
        if let trailingLength = trailingLength {
            let trailingComment = attributedString.attributedSubstring(
                from: NSRange(location: 0,
                              length: min(attributedString.length, trailingLength)
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
            self.attributedText = attributedString
        }
        // swiftlint:enable force_cast
    }

    var body: some View {
        AttributedTextRepresentable(attributedText: attributedText,
                                    height: self.$height,
                                    dynamicHeight: self.dynamicHeight)
            .frame(maxHeight: 300)
    }

    struct AttributedTextRepresentable: UIViewRepresentable {

        let attributedText: NSAttributedString
        @Binding var height: CGFloat
        var dynamicHeight: Bool

        func makeUIView(context: Context) -> UILabel {
            let view = UILabel()

            view.numberOfLines = 0
            view.lineBreakMode = .byWordWrapping
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            return view
        }

        func updateUIView(_ view: UILabel, context: Context) {
            view.attributedText = self.attributedText

            // way1
            self.fitHeight(view)
        }

        func fitHeight(_ view: UILabel) {
            DispatchQueue.main.async {
                self.height = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude)).height
            }
        }
    }
}
