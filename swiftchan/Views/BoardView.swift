//
//  BoardView.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import SwiftUI

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
                    Text(self.description)
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
        .border(Color.gray)
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        return VStack(alignment: .leading) {
            ForEach(Board.examples(), id: \.self) { board in
                BoardView(name: board.name,
                          title: board.title,
                          description: board.description)
            }
        }
    }
}
