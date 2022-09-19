//
//  BoardSection.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/27/21.
//

import SwiftUI
import FourChan

struct BoardSection: View {
    let headerText: String
    let list: [Board]

    var body: some View {
        Group {
            Section(header: Text(headerText)
                        .font(Font.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.leading, 5)
                        .padding(.bottom, 5)
            ) {

                ForEach(list) { board in
                    NavigationLink(value: board.board) {
                        BoardView(
                            name: board.board,
                            nsfw: board.isNSFW,
                            title: board.title,
                            description: board.meta_description.clean
                        )
                        .padding(.horizontal, 5)
                        .id("\(headerText)-\(board.board)")
                        .accessibilityIdentifier(AccessibilityIdentifiers.boardButton( board.board))
                    }
                }
            }
        }
    }
}
