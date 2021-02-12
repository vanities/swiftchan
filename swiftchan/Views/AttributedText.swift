//
//  AttributedText.swift
//  swiftchan
//
//  Created by vanities on 2/10/21.
//

import SwiftUI

/*
struct AttributedText: UIViewRepresentable, Buildable {
  class HeightUITextView: UITextView {
    @Binding var height: CGFloat

    init(height: Binding<CGFloat>) {
      _height = height
      super.init(frame: .zero, textContainer: nil)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      let newSize = sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude))
      if height != newSize.height {
        height = newSize.height
      }
    }
  }

  class Coordinator: NSObject, UITextViewDelegate {
    var parent: AttributedText

    init(_ view: AttributedText) {
      parent = view
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
      parent.linkPressed(URL)
      return false
    }
  }

  let content: NSAttributedString
  @Binding var height: CGFloat
  var linkPressed: (URL) -> Void

    init(_ content: NSMutableAttributedString, height: Binding<CGFloat>, linkPressed: @escaping (URL) -> Void) {
        self.content = content
        self._height = height
        self.linkPressed = linkPressed
    }

  public func makeUIView(context: Context) -> UITextView {
    let textView = HeightUITextView(height: $height)
    textView.attributedText = content
    textView.backgroundColor = .clear
    textView.isEditable = false
    textView.isUserInteractionEnabled = true
    textView.delegate = context.coordinator
    textView.isScrollEnabled = false
    textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    textView.dataDetectorTypes = .link
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    return textView
  }

  public func updateUIView(_ textView: UITextView, context: Context) {
    if textView.attributedText != content {
      textView.attributedText = content

      // Compute the desired height for the content
      let fixedWidth = textView.frame.size.width
      let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))

      DispatchQueue.main.async {
        self.height = newSize.height
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
}
*/

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

        // view.adjustsFontForContentSizeCategory = true
        view.attributedText = self.attributedString
        // view.textContainer.lineBreakMode = .byWordWrapping
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
        // uiView.attributedText = self.attributedString
        DispatchQueue.main.async {
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
