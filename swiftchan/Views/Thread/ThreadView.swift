//
//  ThreadView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct ThreadView: View {
    @StateObject var presentedDismissGesture: DismissGesture = DismissGesture()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ViewModel

    @State private var presentingSheet: PresentedPost.PresentType = .gallery

    @State var galleryIndex: Int = 0
    @State var commentRepliesIndex: Int = 0
    @State var presentingIndex: Int = 0

    @State private var pullToRefreshShowing: Bool = false
    @State private var opacity: Double = 1

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return ZStack {
            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                    /*
                    // performance..
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0) {
 */
                        ForEach(self.viewModel.posts.indices, id: \.self) { index in
                            if index < self.viewModel.comments.count {
                                PostView(index: index,
                                         isPresenting: self.$presentedDismissGesture.presenting,
                                         presentingSheet: self.$presentingSheet,
                                         galleryIndex: self.$galleryIndex,
                                         commentRepliesIndex: self.$commentRepliesIndex
                                )
                                .id(index)
                            }
                        }
                        .frame(minWidth: UIScreen.main.bounds.width)
                    }
                    .padding(.all, 3)
                    .onChange(of: self.galleryIndex) { index in
                        DispatchQueue.main.async {
                            if self.presentingIndex != index,
                               let mediaI = self.viewModel.postMediaMapping.firstIndex(where: { $0.value == self.galleryIndex }) {
                                reader.scrollTo(self.viewModel.postMediaMapping[mediaI].key, anchor: self.viewModel.mediaUrls.count - index < 3 ? .bottom : .top)
                            }
                        }
                    }
                    .opacity(self.opacity)
                    .pullToRefresh(isRefreshing: self.$pullToRefreshShowing) {
                        let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                        softVibrate.impactOccurred()
                        self.viewModel.load {
                            self.pullToRefreshShowing = false
                        }
                    }
                    .navigationBarItems(
                        leading: HStack {
                            Text(self.viewModel.boardName)
                                .offset(x: -7)
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .contentShape(Rectangle())
                                    .frame(width: UIScreen.main.bounds.width/2 - 100, height: 30)
                                    .onTapGesture {
                                        withAnimation(.linear) {
                                            reader.scrollTo(0)
                                        }
                                    }
                                if let title = self.viewModel.posts[0].sub?.clean {
                                    Text(title.trunc(length: 25))
                                        .frame(width: UIScreen.main.bounds.width - 100)
                                        .offset(x: -7)
                                }
                            }
                        },
                        trailing: Link(destination: self.viewModel.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    )
                }
            }
            .onChange(of: self.presentedDismissGesture.draggingOffset) { value in
                DispatchQueue.main.async {
                    withAnimation(.linear) {
                        self.opacity = Double(value / UIScreen.main.bounds.height)
                    }
                }
            }
            .onChange(of: self.presentedDismissGesture.presenting, perform: { value in
                if value && self.appState.fullscreenView == nil {
                    self.appState.fullscreenView = AnyView(
                        PresentedPost(presentingSheet: self.presentingSheet,
                                      galleryIndex: self.$galleryIndex,
                                      commentRepliesIndex: self.commentRepliesIndex)
                            .onDisappear {
                                self.opacity = 1
                                self.presentedDismissGesture.dismiss = false
                                self.presentedDismissGesture.canDrag = true
                                self.presentedDismissGesture.dragging = false
                            }
                            .environmentObject(self.viewModel)
                            .environmentObject(self.presentedDismissGesture)
                    )
                } else {
                    self.appState.fullscreenView = nil
                }
            })
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        // let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        let viewModel = ThreadView.ViewModel(boardName: "biz", id: 21374000)

        ThreadView()
            .environmentObject(viewModel)
            .environmentObject(AppState())
    }
}
