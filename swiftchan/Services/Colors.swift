//
//  Colors.swift
//  Colors
//
//  Created by vanities on 7/23/21.
//

import SwiftUI

class Colors {
    class Op {
        static var background = Color(UIColor.systemBackground)
        static var border = Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
        static var lockColor = Color(#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))
        static var pinColor = Color(#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1))
    }

    class Post {
        static var background = Color(UIColor.systemBackground)
        static var border = Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
        static var trip = Color(#colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1))
        static var name = Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
        static var capcode = Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))

    }

    class Text {
        static var reply = Color(#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1))
        static var link = Color(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1))
        static var crossThreadReply = Color(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1))
        static var plain = Color.primary
        static var quote = Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
        static var deadLink = Color(#colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1))
    }

    class Board {
        static var border = Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
    }

    class Other {
        static var star = Color(#colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1))
    }

    class Background {
        static var gray = Color(#colorLiteral(red: 0.1231701747, green: 0.1231701747, blue: 0.1231701747, alpha: 1))
        static var white = Color(#colorLiteral(red: 0.9498993754, green: 0.9449323416, blue: 0.9320884347, alpha: 1))
    }
}
