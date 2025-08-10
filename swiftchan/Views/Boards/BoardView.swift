//
//  BoardView.swift
//  swiftchan
//
//  Created on 10/30/20.
//

import SwiftUI
import FourChan

struct BoardView: View {
    let name: String
    let nsfw: Bool
    let title: String
    let description: String

    var body: some View {
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.clear)
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(self.name + " - " + self.title)

                        if nsfw {
                            NSFWTagView()
                        }
                    }
                    .font(DrawingConstants.titleFont)
                    Text(self.description)
                        .font(DrawingConstants.descriptionFont)
                        .lineLimit(nil)
                }
            }
            .padding(
                EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)
            )
            HStack(alignment: .center) {
                Spacer()
                VStack(alignment: .trailing) {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .padding(.trailing, 7)
                    Spacer()
                }
            }
        }
        .border(Colors.Board.border)
        .background(.regularMaterial)
    }

    struct DrawingConstants {
        static let titleFont = Font.system(size: 17, weight: .bold, design: .monospaced)
        static let descriptionFont = Font.system(size: 15, weight: .regular, design: .rounded)
    }
}

#if DEBUG
#Preview {
    Group {
        VStack(alignment: .leading) {
            ForEach(Board.examples(), id: \.self.id) { board in
                BoardView(
                    name: board.board,
                    nsfw: board.isNSFW,
                    title: board.title,
                    description: board.descriptionText
                )
                .frame(height: 200)
            }
        }
        .padding(.horizontal, 10)

        VStack(alignment: .leading) {
            ForEach(Board.examples(), id: \.self.id) { board in
                BoardView(
                    name: board.board,
                    nsfw: true,
                    title: board.title,
                    description: board.descriptionText
                )
                .frame(height: 200)
            }
        }
        .padding(.horizontal, 10)
    }
}
#endif
