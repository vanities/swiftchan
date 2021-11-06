//
//  BoardView.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import SwiftUI
import FourChan

struct BoardView: View {
    let name: String
    let title: String
    let description: String

    var body: some View {
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.clear)
            HStack {
                VStack(alignment: .leading) {
                    Text(self.name + " - " + self.title)
                        .font(Font.system(size: 17, weight: .bold, design: .monospaced))
                    Text(self.description)
                        .font(Font.system(size: 15, weight: .regular, design: .rounded))
                        .lineLimit(nil)
                }
            }
            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
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
    }
}

#if DEBUG
struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        return VStack(alignment: .leading) {
            ForEach(Board.examples(), id: \.self.id) { board in
                BoardView(name: board.board,
                          title: board.title,
                          description: board.descriptionText)
            }
        }
    }
}
#endif
