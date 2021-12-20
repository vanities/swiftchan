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

func createThreadUpdateTimer() -> Publishers.Autoconnect<Timer.TimerPublisher> {
    return Timer.publish(every: 1, on: .current, in: .common).autoconnect()
}

struct ThreadView: View {
    @Default(.autoRefreshEnabled) private var autoRefreshEnabled
    @Default(.autoRefreshThreadTime) private var autoRefreshThreadTime

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var viewModel: ViewModel

    @StateObject private var presentationState: PresentationState = PresentationState()

    @State private var pullToRefreshShowing: Bool = false
    @State private var opacity: Double = 1
    @State private var pauseAutoRefresh: Bool = false
    @State private var showReply: Bool = false
    @State private var replyId: Int = 0
    @State private var autoRefreshTimer: Double = 0
    @State private var timer = createThreadUpdateTimer()

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return ZStack {
            replyNavigation

            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: columns,
                        alignment: .center,
                        spacing: 0
                    ) {
                        ForEach(
                            viewModel.posts.indices,
                            id: \.self
                        ) { index in
                            if index < viewModel.comments.count {
                                PostView(index: index)
                            }
                        }
                    }
                    .padding(.all, 3)
                    .onChange(of: presentationState.presentingGallery) { _ in
                        scrollToPost(reader: reader)
                    }
                    .opacity(opacity)
                    .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        viewModel.load {
                            pullToRefreshShowing = false
                            viewModel.prefetch()
                        }
                    }

                    .navigationTitle(viewModel.posts.first?.sub?.clean ?? "")
                    .navigationBarItems(trailing:
                                            HStack {
                        autoRefreshButton
                        Link(destination: viewModel.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    )
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
                        timer.upstream.connect().cancel()
                    }
                    .onDisappear {
                        timer = createThreadUpdateTimer()
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
        .onReceive(timer) { _ in incrementRefreshTimer() }
        .onChange(of: presentationState.presentingReplies) { presenting in
            if presenting {
                timer.upstream.connect().cancel()
            } else {
                timer = createThreadUpdateTimer()
            }
        }
        .environmentObject(presentationState)
    }

    var replyNavigation: some View {
        NavigationLink(
            isActive: $showReply,
            destination: {
                PostView(index: replyId)
                    .environmentObject(viewModel)
                    .environmentObject(presentationState)
                    .onAppear {
                        timer.upstream.connect().cancel()
                    }
                    .onDisappear {
                        timer = createThreadUpdateTimer()
                    }
            },
            label: {}
        )
    }

    @ViewBuilder
    var autoRefreshButton: some View {
        if autoRefreshEnabled {
            ProgressView(value: Double(autoRefreshThreadTime)-autoRefreshTimer, total: Double(autoRefreshThreadTime)) {
                Text("\(Int(autoRefreshThreadTime-Int(autoRefreshTimer)))")
                    .animation(nil)
            }
            .progressViewStyle(CustomCircularProgressViewStyle(paused: pauseAutoRefresh))
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                pauseAutoRefresh.toggle()
            }
        } else {
            EmptyView()
        }
    }

    func scrollToPost(reader: ScrollViewProxy) {
        if !presentationState.presentingGallery,
           presentationState.presentingIndex != presentationState.galleryIndex,
           let mediaI = viewModel.postMediaMapping.firstIndex(where: { $0.value == presentationState.galleryIndex }) {
            DispatchQueue.main.async {
                reader.scrollTo(viewModel.postMediaMapping[mediaI].key, anchor: viewModel.media.count - presentationState.galleryIndex < 3 ? .bottom : .top)
                viewModel.media[presentationState.galleryIndex].isSelected = false
            }
        }
    }

    func incrementRefreshTimer() {
        guard !pauseAutoRefresh else { return }
        withAnimation(.linear(duration: 1)) {
            autoRefreshTimer += Int(autoRefreshTimer) >= autoRefreshThreadTime ? Double(-autoRefreshThreadTime) : 1
        }
        if autoRefreshTimer == 0 {
            viewModel.load {
                pullToRefreshShowing = false
                viewModel.prefetch()
            }
        }
    }
}

#if DEBUG
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
#endif

struct CustomCircularProgressViewStyle: ProgressViewStyle {
    var paused: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(paused ? .red : .blue, style: StrokeStyle(lineWidth: 2))
                .rotationEffect(.degrees(-90))
                .frame(width: 25)

            configuration.label
        }
    }
}
