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

    @StateObject var presentedDismissGesture: DismissGesture = DismissGesture()
    @StateObject var presentationState: PresentationState = PresentationState()

    @State var postIndex: Int = 0
    @State var commentRepliesIndex: Int = 0
    @State var isPresenting = false
    @State var presentingSheet: PresentedPost.PresentType = .replies

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return
            ZStack(alignment: .center) {
                Blur(style: .regular).ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns,
                              alignment: .center,
                              spacing: 0) {
                        ForEach(replies, id: \.self) { index in
                            PostView(index: index)
                                .environmentObject(presentationState)
                                .environmentObject(presentedDismissGesture)
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height - 100)
    }
}

struct RepliesView_Previews: PreviewProvider {

    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        RepliesView(replies: [0, 1])
            .environmentObject(viewModel)
    }
}
