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
import UIKit

func createThreadUpdateTimer() -> Publishers.Autoconnect<Timer.TimerPublisher> {
    return Timer.publish(every: 1, on: .current, in: .common).autoconnect()
}

struct ThreadView: View {
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("autoRefreshThreadTime") private var autoRefreshThreadTime = 10
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = false
    @AppStorage("rememberThreadPositions") var rememberThreadPositions = true
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
    @State private var savedIndex: Int?
    @State private var lastVisibleIndex: Int?
    @State private var savedOffset: CGFloat?
    @State private var scrollViewRef: UIScrollView?
    @State private var didRestoreOffset = false

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
        let savedIndex = UserDefaults.getThreadPosition(boardName: boardName, threadId: Int(postNumber))
        self._savedIndex = State(wrappedValue: savedIndex)

        if let offset = UserDefaults.getThreadOffset(boardName: boardName, threadId: Int(postNumber)) {
            self._savedOffset = State(wrappedValue: CGFloat(offset))
        } else {
            self._savedOffset = State(initialValue: nil)
        }
        print("ThreadView init: board=\(boardName), threadId=\(postNumber), savedIndex=\(String(describing: savedIndex)), savedOffset=\(String(describing: _savedOffset.wrappedValue))")
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
                                        .onAppear {
                                            lastVisibleIndex = postIndex
                                            print("Last visible index updated to \(postIndex)")
                                        }
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
                    .introspect(
                        .scrollView,
                        on: .iOS(.v15, .v16, .v17)
                    ) { scrollView in
                        scrollViewRef = scrollView
                        print("Got scroll view reference")
                        restoreSavedPosition(reader: reader)
                    }
                    .onDisappear {
                        print("ScrollView onDisappear - saving position")
                        savePosition()
                    }
                    .onAppear {
                        print("ScrollView onAppear")
                        restoreSavedPosition(reader: reader)
                    }
                    .onChange(of: viewModel.posts.count) { _, _ in
                        print("Posts count changed, attempting to restore")
                        restoreSavedPosition(reader: reader)
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
                        print("Gallery onAppear - canceling autorefresh")
                        threadAutorefresher.cancelTimer()
                    }
                    .onDisappear {
                        print("Gallery onDisappear - starting autorefresh")
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
                print("ThreadView onAppear - prefetching")
                viewModel.prefetch()
            }
            .onDisappear {
                viewModel.stopPrefetching()
                savePosition()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase != .active {
                    savePosition()
                }
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

    private func restoreSavedPosition(reader: ScrollViewProxy) {
        guard rememberThreadPositions, let scrollView = scrollViewRef else { return }
        guard !didRestoreOffset else { return }

        print("Attempting restore: savedOffset=\(String(describing: savedOffset)), savedIndex=\(String(describing: savedIndex))")

        if let offset = savedOffset {
            print("Restoring using offset \(offset)")
            applyOffset(offset, to: scrollView)
            didRestoreOffset = true
        } else if let index = savedIndex, index < viewModel.posts.count {
            print("Restoring using index \(index)")
            DispatchQueue.main.async {
                reader.scrollTo(index, anchor: .top)
                didRestoreOffset = true
            }
        }
    }

    private func savePosition() {
        if rememberThreadPositions {
            if let index = lastVisibleIndex {
                print("Saving index \(index)")
                UserDefaults.setThreadPosition(
                    boardName: viewModel.boardName,
                    threadId: viewModel.id,
                    index: index
                )
            }
            if let scrollView = scrollViewRef {
                let offset = scrollView.contentOffset.y
                print("Saving offset \(offset)")
                UserDefaults.setThreadOffset(
                    boardName: viewModel.boardName,
                    threadId: viewModel.id,
                    offset: Double(offset)
                )
            } else {
                print("No scrollView reference to save offset")
            }
        } else {
            print("Removing saved position and offset")
            UserDefaults.removeThreadPosition(boardName: viewModel.boardName, threadId: viewModel.id)
            UserDefaults.removeThreadOffset(boardName: viewModel.boardName, threadId: viewModel.id)
        }
    }

    private func applyOffset(_ offset: CGFloat, to scrollView: UIScrollView) {
        let delays: [Double] = [0.0, 0.1, 0.4, 0.8, 1.2]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                print("Applying offset \(offset) after delay \(delay)")
                scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
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
