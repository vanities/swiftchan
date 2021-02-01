//
//  RepliesView.swift
//  swiftchan
//
//  Created by vanities on 11/19/20.
//

import SwiftUI

struct RepliesView: View {
    @EnvironmentObject var viewModel: ThreadView.ViewModel
    let replies: [Int]

    @State var postIndex: Int = 0
    @State var commentRepliesIndex: Int = 0
    @State var isPresenting = false
    @State var presentingSheet: PresentingSheet = .replies

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return
            ZStack(alignment: .center) {
                Blur(style: .regular).ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0) {
                        ForEach(self.replies, id: \.self) { index in
                            PostView(
                                     index: index,
                                     isPresenting: self.$isPresenting,
                                     presentingSheet: self.$presentingSheet,
                                     galleryIndex: self.$postIndex,
                                     commentRepliesIndex: self.$commentRepliesIndex
                            )
                            // random id, different from the thread ones
                            .id(UUID())
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height - safeAreaPadding)
    }
}

struct RepliesView_Previews: PreviewProvider {

    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        RepliesView(replies: [0, 1])
            .environmentObject(viewModel)
    }
}
