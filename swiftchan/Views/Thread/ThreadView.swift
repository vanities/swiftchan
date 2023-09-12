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
    @StateObject var viewModel: ThreadViewModel

    @StateObject private var presentationState = PresentationState()
    @StateObject private var threadAutorefresher = ThreadAutoRefresher()

    @State private var pullToRefreshShowing: Bool = false
    @State private var opacity: Double = 1
    @State private var showReply: Bool = false
    @State private var replyId: Int = 0
    @State private var scrollViewPosition: Int?

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    init(boardName: String, postNumber: PostNumber) {
        self._viewModel = StateObject(
            wrappedValue: ThreadViewModel(
                boardName: boardName,
                id: postNumber
            )
        )
    }

    @ViewBuilder
    var body: some View {
        switch viewModel.state {
        case .initial:
            ProgressView()
                .task {
                    await viewModel.getPosts()
                }
        case .loading:
            ProgressView()
        case .loaded:
            ZStack {
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
                            if !presentationState.presentingReplies && !showReply {
                                scrollToPost(reader: reader)
                            }
                        }
                        .opacity(opacity)
                        .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            Task {
                                await fetchAndPrefetchMedia()
                            }
                        }
                        //.scrollTargetLayout()
                    }
                    //.scrollPosition(id: $scrollViewPosition)
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
            .onAppear {
                viewModel.prefetch()
            }
            .onDisappear {
                viewModel.stopPrefetching()
            }
            .onReceive(threadAutorefresher.timer) { _ in
                if threadAutorefresher.incrementRefreshTimer() {
                    print("Thread auto refresh timer met, updating thread.")
                    Task {
                        await fetchAndPrefetchMedia()
                    }
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
            .toolbar(id: "toolbar-1") {
                ToolbarItem(id: "toolbar-item-1", placement: ToolbarItemPlacement.navigationBarTrailing) {
                    HStack {
                        // TODO: fix this from redrawing the whole posts in ThreadView,
                        // autoRefreshButton
                        Link(destination: viewModel.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .defaultCustomization(.hidden)
            }
            .onChange(of: showReply) { value in
                if value {
                    threadAutorefresher.cancelTimer()
                } else {
                    threadAutorefresher.setTimer()
                }
            }
            .navigationDestination(isPresented: $showReply) {
                PostView(index: replyId)
                    .environmentObject(viewModel)
                    .environmentObject(presentationState)
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
        case .error:
            Text("Thread contains no posts.")
                .foregroundColor(.red)

        }
    }

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
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                threadAutorefresher.pauseAutoRefresh.toggle()
            }
            .progressViewStyle(ThreadRefreshProgressViewStyle(paused: threadAutorefresher.pauseAutoRefresh))
        } else {
            EmptyView()
        }
    }

    private func fetchAndPrefetchMedia() async {
        await viewModel.getPosts()
        DispatchQueue.main.async {
            pullToRefreshShowing = false
        }
        viewModel.prefetch()
    }

    private func scrollToPost(reader: ScrollViewProxy) {
        if presentationState.presentingIndex != presentationState.galleryIndex,
           let mediaI = viewModel.postMediaMapping.firstIndex(where: { $0.value == presentationState.galleryIndex }) {
            reader.scrollTo(viewModel.postMediaMapping[mediaI].key, anchor: viewModel.media.count - presentationState.galleryIndex < 3 ? .bottom : .top)
        }
    }
}

#if DEBUG
struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        // let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        let viewModel = ThreadViewModel(boardName: "biz", id: 21374000)

        Group {
            ThreadView(boardName: viewModel.boardName, postNumber: viewModel.posts.first!.id)
                .environmentObject(viewModel)
                .environmentObject(AppState())

            NavigationView {
                ThreadView(boardName: viewModel.boardName, postNumber: viewModel.posts.first!.id)
                    .environmentObject(viewModel)
                    .environmentObject(AppState())
            }
        }
    }
}
#endif
