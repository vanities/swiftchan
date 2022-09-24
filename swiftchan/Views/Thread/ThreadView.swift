//
//  ThreadView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import Defaults
import Combine
import BottomSheet

func createThreadUpdateTimer() -> Publishers.Autoconnect<Timer.TimerPublisher> {
    return Timer.publish(every: 1, on: .current, in: .common).autoconnect()
}

struct ThreadView: View {
    @Default(.autoRefreshEnabled) private var autoRefreshEnabled
    @Default(.autoRefreshThreadTime) private var autoRefreshThreadTime

    @EnvironmentObject private var appState: AppState
    @StateObject var viewModel: ThreadView.ViewModel

    @StateObject private var presentationState = PresentationState()
    @StateObject private var threadAutorefresher = ThreadAutoRefresher()

    @State private var pullToRefreshShowing: Bool = false
    @State private var opacity: Double = 1
    @State private var showReply: Bool = false
    @State private var replyId: Int = 0

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    init(post: SwiftchanPost) {
        self._viewModel = StateObject(
            wrappedValue: ThreadView.ViewModel(
                boardName: post.boardName,
                id: post.post.no
            )
        )
    }

    var body: some View {
        return ZStack {
            if viewModel.posts.count == 0 {
                Text("Thread contains no posts.")
                    .foregroundColor(.red)
            }

            ScrollViewReader { reader in
                ScrollView {
                    LazyVGrid(
                        columns: columns,
                        alignment: .center,
                        spacing: 0
                    ) {
                        ForEach(viewModel.posts.indices, id: \.self) { postIndex in
                            let post = viewModel.posts[postIndex]
                            if !post.isHidden(boardName: viewModel.boardName) {
                                PostView(index: postIndex)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    .padding(.all, 3)
                    .onChange(of: presentationState.galleryIndex) { _ in
                        scrollToPost(reader: reader)
                    }
                    .opacity(opacity)
                    .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        update()
                    }
                }
            }
        }
        .sheet(
            isPresented: $presentationState.presentingGallery,
            onDismiss: {
                // reneable this if it got disabled
                UIApplication.shared.isIdleTimerDisabled = false

            },
            content: {
                GalleryView(
                    index: presentationState.galleryIndex
                )
                .environmentObject(appState)
                .environmentObject(presentationState)
                .environmentObject(viewModel)
                .onAppear {
                    threadAutorefresher.cancelTimer()
                }
                .onDisappear {
                    threadAutorefresher.setTimer()
                }
            }
        )
        .onOpenURL { url in
            if case .post(let id) = Deeplinker.getType(url: url) {
                showReply = true
                replyId = viewModel.getPostIndexFromId(id)
            }
        }
        .task {
            viewModel.prefetch()
        }
        .onDisappear {
            viewModel.stopPrefetching()
        }
        .onReceive(threadAutorefresher.timer) { _ in
            if threadAutorefresher.incrementRefreshTimer() {
                print("Thread auto refresh timer met, updating thread.")
                update()
            }

        }
        .onChange(of: presentationState.presentingReplies) { presenting in
            if presenting {
                threadAutorefresher.cancelTimer()
            } else {
                threadAutorefresher.setTimer()
            }
        }
        .environmentObject(presentationState)
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                HStack {
                    // autoRefreshButton
                    Link(destination: viewModel.url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showReply) {
            PostView(index: replyId)
        }
        .bottomSheet(
            isPresented: $appState.showingBottomSheet,
            height: 100
        ) {
            if let post = appState.selectedBottomSheetPost,
               let index = viewModel.posts.firstIndex(of: post) {
                Button("Hide \(index == 0 ? "Thread" : "Post")") {
                    post.hide(boardName: viewModel.boardName)
                }
            }
        }
    }

    /*
     // TODO: fix this from redrawing the whole posts in ThreadView,
     // Seems to be happening on every update from the timer
     @ViewBuilder
     var autoRefreshButton: some View {
     if autoRefreshEnabled {
     ProgressView(
     value: Double(autoRefreshThreadTime) - threadAutorefresher.autoRefreshTimer,
     total: Double(autoRefreshThreadTime)
     ) {
     Text("\(Int(autoRefreshThreadTime) - Int(threadAutorefresher.autoRefreshTimer))")
     .animation(nil)
     }
     .progressViewStyle(CustomCircularProgressViewStyle(paused: threadAutorefresher.pauseAutoRefresh))
     .onTapGesture {
     UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
     threadAutorefresher.pauseAutoRefresh.toggle()
     }
     } else {
     EmptyView()
     }
     }
     */

    private func update() {
        Task {
            await viewModel.load()
            DispatchQueue.main.async {
                pullToRefreshShowing = false
                viewModel.prefetch()
            }
        }
    }

    private func scrollToPost(reader: ScrollViewProxy) {
        if presentationState.presentingIndex != presentationState.galleryIndex,
           let mediaI = viewModel.postMediaMapping.firstIndex(where: { $0.value == presentationState.galleryIndex }) {
            reader.scrollTo(viewModel.postMediaMapping[mediaI].key, anchor: viewModel.media.count - presentationState.galleryIndex < 3 ? .bottom : .top)
        }
    }
}

#if DEBUG
/*
 struct ThreadView_Previews: PreviewProvider {
 static var previews: some View {
 // let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
 let viewModel = ThreadView.ViewModel(boardName: "biz", id: 21374000)

 Group {
 ThreadView()
 .environmentObject(viewModel)
 .environmentObject(AppState())

 NavigationView {
 ThreadView()
 .environmentObject(viewModel)
 .environmentObject(AppState())
 }
 }
 }
 }
 */
#endif
