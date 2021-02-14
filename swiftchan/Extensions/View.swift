//
//  View.swift
//  swiftchan
//
//  Created by vanities on 11/21/20.
//

import SwiftUI
import Introspect

// not used
extension View {
    public func introspectTabBarScrollView(customize: @escaping (UIScrollView) -> Void) -> some View {
        return inject(UIKitIntrospectionView(
            selector: { introspectionView in
                guard let viewHost = Introspect.findViewHost(from: introspectionView) else {
                    return nil
                }
                return Introspect.previousSibling(containing: UIScrollView.self, from: viewHost)
            },
            customize: customize
        ))
    }

    public func frameTextView(_ text: NSMutableAttributedString,
                              maxWidth: CGFloat,
                              maxHeight: CGFloat) -> some View {
        let width = min(maxWidth, UIScreen.main.bounds.width)
        let height = min(maxHeight, CGFloat.greatestFiniteMagnitude)
        let constraintBox = CGSize(width: width, height: height)
        let size = text.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral.size
        return frame(width: size.width, height: size.height+40)
    }
}
