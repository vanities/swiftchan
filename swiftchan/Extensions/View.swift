//
//  View.swift
//  swiftchan
//
//  Created on 11/21/20.
//

import SwiftUI
import SwiftUIIntrospect

// not used
extension View {
    @ViewBuilder func `if`<Content: View>(_ conditional: Bool, @ViewBuilder _ content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }

    @ViewBuilder func `if`<Truthy: View, Falsy: View>(
        _ conditional: Bool = true,
        @ViewBuilder _ truthy: (Self) -> Truthy,
        @ViewBuilder else falsy: (Self) -> Falsy
    ) -> some View {
        if conditional {
            truthy(self)
        } else {
            falsy(self)
        }
    }

    @ViewBuilder func ifLet<Content: View, T>(_ conditional: T?, @ViewBuilder _ content: (_ value: T, Self) -> Content) -> some View {
        if let value = conditional {
            content(value, self)
        } else {
            self
        }
    }
}
