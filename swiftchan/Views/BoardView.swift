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
        ZStack {
            Rectangle()
                .fill(Color(.systemBackground))
                .border(Color(.black))
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(self.name + " - " + self.title)
                    Text(self.description)
                        .lineLimit(nil)
                }
                Image(systemName: "chevron.right")
            }
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        return BoardView(name: "3",
                         title: "3DCG",
                         description: "/3/ - 3DCG is 4chan's board for 3D modeling and imagery." )
    }
}
