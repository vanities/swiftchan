//
//  ThreadView.swift
//  swiftchan
//
//  Created on 10/31/20.
//

import SwiftUI
import FourChan
import Combine
import SpriteKit

func createThreadUpdateTimer() -> Publishers.Autoconnect<Timer.TimerPublisher> {
    return Timer.publish(every: 1, on: .current, in: .common).autoconnect()
}

struct ThreadView: View {
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("autoRefreshThreadTime") private var autoRefreshThreadTime = 10
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) private var appState

    @State private var presentationState = PresentationState()
    @State private var threadAutorefresher = ThreadAutoRefresher()
    @State var viewModel: ThreadViewModel
    @State private var opacity: Double = 1
    @State private var showReply: Bool = false
    @State private var replyId: Int = 0
    @State private var showThread: Bool = false
    @State private var threadDestination = ThreadDestination(board: "", id: 0)

    var scene: SKScene {
        let scene = SnowScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }


    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    init(boardName: String, postNumber: PostNumber) {
        self._viewModel = State(
            wrappedValue: ThreadViewModel(
                boardName: boardName,
                id: postNumber
            )
        )
    }

    @ViewBuilder
    var body: some View {
        @Bindable var appState = appState

        switch viewModel.state {
        case .initial:
            Text(viewModel.progressText)
                .task {
                    await viewModel.getPosts()
                }
        case .loading:
            Text(viewModel.progressText)
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
                                        .environment(viewModel)
                                }
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.all, 3)
                        .onChange(of: presentationState.galleryIndex) { _, _  in
                            if !presentationState.presentingReplies && !showReply {
                                scrollToPost(reader: reader)
                            }
                        }
                        .opacity(opacity)
                    }
                }
            }
            .overlay {
                if Date.isChristmas() {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .disabled(true)
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
                    .environment(appState)
                    .environment(presentationState)
                    .environment(viewModel)
                    .onAppear {
                        threadAutorefresher.cancelTimer()
                    }
                    .onDisappear {
                        threadAutorefresher.setTimer()
                    }
                }
            )
            .onOpenURL { url in
                switch Deeplinker.getType(url: url) {
                case .post(let id):
                    showReply = true
                    replyId = viewModel.getPostIndexFromId(id)
                case .thread(let board, let id):
                    threadDestination = ThreadDestination(board: board, id: Int(id) ?? 0)
                    showThread = true
                default:
                    break
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
            .onChange(of: presentationState.presentingReplies) {
                if presentationState.presentingReplies {
                    threadAutorefresher.cancelTimer()
                } else {
                    threadAutorefresher.setTimer()
                }
            }
            .refreshable {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                Task {
                    await fetchAndPrefetchMedia()
                }
            }
            .environment(presentationState)
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
            .onChange(of: showReply) {
                if showReply {
                    threadAutorefresher.cancelTimer()
                } else {
                    threadAutorefresher.setTimer()
                }
            }
            .onChange(of: showThread) {
                if showThread {
                    threadAutorefresher.cancelTimer()
                } else {
                    threadAutorefresher.setTimer()
                }
            }
            .navigationDestination(isPresented: $showReply) {
                PostView(index: replyId)
                    .environment(viewModel)
                    .environment(presentationState)
            }
            .navigationDestination(isPresented: $showThread) {
                ThreadView(boardName: threadDestination.board, postNumber: threadDestination.id)
            }
            .sheet(isPresented: $appState.showingBottomSheet) {
                if let post = appState.selectedBottomSheetPost,
                   let index = viewModel.posts.firstIndex(of: post) {
                    Button("Hide \(index == 0 ? "Thread" : "Post")") {
                        post.hide(boardName: viewModel.boardName)
                    }
                    .presentationDetents([.fraction(0.1)])
                }
            }
            .toolbar(hideTabOnBoards ? .hidden : .automatic, for: .tabBar)
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
#Preview {
    // let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
    let viewModel = ThreadViewModel(boardName: "biz", id: 21374000)

    return Group {
        ThreadView(boardName: viewModel.boardName, postNumber: viewModel.posts.first!.id)
            .environment(viewModel)
            .environment(AppState())

        NavigationView {
            ThreadView(boardName: viewModel.boardName, postNumber: viewModel.posts.first!.id)
                .environment(viewModel)
                .environment(AppState())
        }
    }
}
#endif
