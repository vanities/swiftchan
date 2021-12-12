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
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @Default(.autoRefreshEnabled) private var autoRefreshEnabled
    @Default(.autoRefreshThreadTime) private var autoRefreshThreadTime

    @StateObject private var presentedDismissGesture: DismissGesture = DismissGesture()
    @StateObject private var presentationState: PresentationState = PresentationState()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var viewModel: ViewModel

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
            NavigationLink(
                isActive: $showReply,
                destination: {
                    PostView(index: replyId)
                        .environmentObject(viewModel)
                        .environmentObject(presentationState)
                        .environmentObject(presentedDismissGesture)
                        .onAppear {
                            timer.upstream.connect().cancel()
                        }
                        .onDisappear {
                            timer = createThreadUpdateTimer()
                        }
                },
                label: {})

            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0) {

                        ForEach(viewModel.posts.indices, id: \.self) { index in
                            if index < viewModel.comments.count {
                                PostView(index: index)
                            }
                        }
                    }
                    .padding(.all, 3)
                    .onChange(of: presentedDismissGesture.dismiss) { dismissing in
                        DispatchQueue.main.async {
                            if dismissing,
                               presentationState.presentingIndex != presentationState.galleryIndex,
                               presentationState.presentingSheet == .gallery,
                               let mediaI = viewModel.postMediaMapping.firstIndex(where: { $0.value == presentationState.galleryIndex }) {
                                reader.scrollTo(viewModel.postMediaMapping[mediaI].key, anchor: viewModel.media.count - presentationState.galleryIndex < 3 ? .bottom : .top)
                                viewModel.media[presentationState.galleryIndex].isSelected = false
                            }
                        }
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
            .onChange(of: presentedDismissGesture.draggingOffset) { value in
                DispatchQueue.main.async {
                    withAnimation(.linear) {
                        opacity = Double(value / UIScreen.main.bounds.height)
                    }
                }
            }
        }
        .onOpenURL { url in
            if case .post(let id) = Deeplinker.getType(url: url) {
                showReply = true
                replyId = getPostIndexFromId(id)
            }
        }
        .task {
            viewModel.prefetch()
        }
        .onDisappear {
            viewModel.stopPrefetching()
        }
        .onReceive(timer) { _ in
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
        .onChange(of:presentedDismissGesture.presenting) { presenting in
            if presenting {
                timer.upstream.connect().cancel()
            } else {
                timer = createThreadUpdateTimer()
            }
        }
        .environmentObject(presentationState)
        .environmentObject(presentedDismissGesture)
    }

    func getPostIndexFromId(_ id: String) -> Int {
        var index = 0
        for post in viewModel.posts {
            if id.contains(String(post.id)) {
                return index
            }
            index += 1
        }
        return 0
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
