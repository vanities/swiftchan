//
//  NSFWTagView.swift
//  swiftchan
//
//  Created by Adam Mischke on 5/29/22.
//

import SwiftUI

struct NSFWTagView: View {
    var body: some View {
        Text(DrawingConstants.text)
            .italic()
            .foregroundColor(DrawingConstants.foregroundColor)
            .padding(.vertical, DrawingConstants.backgroundVerticalPadding)
            .padding(.horizontal, DrawingConstants.backgroundHorizontalPadding)
            .background(Rectangle().foregroundColor(DrawingConstants.backgroundColor))
    }

    struct DrawingConstants {
        static let text = "NSFW"
        static let foregroundColor = Color.white
        static let backgroundColor = Color.red
        static let backgroundVerticalPadding: CGFloat = 2
        static let backgroundHorizontalPadding: CGFloat = 5
    }
}

struct NSFWTagView_Previews: PreviewProvider {
    static var previews: some View {
        NSFWTagView()
    }
}
