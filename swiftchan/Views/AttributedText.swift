//
//  AttributedText.swift
//  swiftchan
//
//  Created by vanities on 2/10/21.
//

import SwiftUI

struct AttributedText: UIViewRepresentable, Buildable {

    let attributedString: NSMutableAttributedString
    @State var size: CGSize = .zero
    @State var lineLimit: Int = 0
    @State var lineBreakMode: NSLineBreakMode = .byWordWrapping
    @State var calculatedHeight: CGFloat = 100

    init(_ attributedString: NSMutableAttributedString) {
        self.attributedString = attributedString
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()

        view.attributedText = self.attributedString
        view.textContainer.lineBreakMode = .byTruncatingTail
        // view.textContainerInset = .zero
        // view.textContainer.lineFragmentPadding = 0
        view.isScrollEnabled = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.dataDetectorTypes = [.link]
        view.isUserInteractionEnabled = true
        view.isEditable = false

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            uiView.attributedText = self.attributedString
            uiView.textContainer.maximumNumberOfLines = self.lineLimit
            uiView.textContainer.lineBreakMode = self.lineBreakMode
        }
    }

    func lineLimit(_ value: Int) -> Self {
        mutating(keyPath: \.lineLimit, value: value)
    }

    func lineBreakMode(_ value: NSLineBreakMode) -> Self {
        mutating(keyPath: \.lineBreakMode, value: value)
    }
}

struct AttributedText_Previews: PreviewProvider {

    static var previews: some View {
        EmptyView()
        // AttributedText(NSMutableAttributedString(string: "I have a Rosewill Thor, and the lights on the front IO panel stay on when the computer is asleep, and they pulse, which is doubly annoying. Is there a way to configure case lights via BIOS or something to turn them off? I know there&#039;s a button to turn off the fan LEDs, but those aren&#039;t a problem, because those stay off when I put the computer to sleep. The problem are specifically the ones at the front IO panel."), height: .constant(200), linkPressed: {_ in })
            // .frame(width: 200, height: 200)
    }
}
