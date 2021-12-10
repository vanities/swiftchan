//
//  RepliesView.swift
//  swiftchan
//
//  Created by vanities on 11/19/20.
//

import SwiftUI

struct RepliesView: View {
    let replies: [Int]

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns,
                      alignment: .center,
                      spacing: 0) {
                ForEach(replies, id: \.self) { index in
                    PostView(index: index)
                }
            }
        }
    }
}

#if DEBUG
struct RepliesView_Previews: PreviewProvider {

    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        RepliesView(replies: [0, 1])
            .environmentObject(viewModel)
    }
}
#endif
