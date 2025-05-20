//
//  PrivacyView.swift
//  swiftchan
//
//  Created on 5/29/22.
//

import SwiftUI

extension View {
    public func privacyView(enabled: Binding<Bool>) -> some View {
        modifier(PrivacyView(enabled: enabled))
    }
}

struct PrivacyView: ViewModifier {
    @Binding var enabled: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: enabled ? 10 : 0)
            Image("swallow")
                .renderingMode(.template)
                .resizable()
                .zIndex(2)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.primary)
                .frame(width: 100)
                .opacity(enabled ? 1 : 0)
        }
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AsyncImage(url: URLExamples.image)
                .privacyView(enabled: .constant(true))
        }
    }
}
