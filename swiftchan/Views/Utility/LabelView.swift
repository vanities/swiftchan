import SwiftUI

struct LabelView: View {

    @State private var size: CGSize = .zero
    let attributedString: NSAttributedString
    var dynamicHeight: Bool = true

    init(_ attributedString: NSAttributedString,
         trailingLength: Int? = nil,
         dynamicHeight: Bool = false) {
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
            self.attributedString = trailingComment
        } else {
            self.attributedString = attributedString
        }
        // swiftlint:enable force_cast
    }

    var body: some View {
        AttributedTextRepresentable(attributedString: attributedString, size: $size, dynamicHeight: dynamicHeight)
            .frame(height: self.dynamicHeight ? self.size.height : 300)
    }

    struct AttributedTextRepresentable: UIViewRepresentable {

        let attributedString: NSAttributedString
        @Binding var size: CGSize
        var dynamicHeight: Bool

        func makeUIView(context: Context) -> UILabel {
            let label = UILabel()

            label.lineBreakMode = .byClipping
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.numberOfLines = 0

            return label
        }

        func updateUIView(_ uiView: UILabel, context: Context) {
            uiView.attributedText = attributedString
            guard dynamicHeight == true else { return }

            DispatchQueue.main.async {
                size = uiView.sizeThatFits(CGSize(width: uiView.frame.width, height: .greatestFiniteMagnitude))
            }
        }
    }
}
