//
//  View.swift
//  swiftchan
//
//  Created by vanities on 11/21/20.
//

import SwiftUI
import Introspect

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
}
