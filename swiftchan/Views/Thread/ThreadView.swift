//
//  ThreadView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct ThreadView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var presentedDismissGesture: DismissGesture = DismissGesture()
    @StateObject var presentationState: PresentationState = PresentationState()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ViewModel

    @State private var pullToRefreshShowing: Bool = false
    @State private var opacity: Double = 1

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return ZStack {
            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                    // performance..
                    /*
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0) {
 */
                        ForEach(viewModel.posts.indices, id: \.self) { index in
                            if index < viewModel.comments.count {
                                PostView(index: index)
                                    .id(index)
                            }
                        }
                    }
                    .padding(.all, 3)
                    .onChange(of: presentedDismissGesture.dismiss) { dismissing in
                        DispatchQueue.main.async {
                            if dismissing,
                               presentationState.presentingIndex != presentationState.galleryIndex,
                               let mediaI = viewModel.postMediaMapping.firstIndex(where: { $0.value == presentationState.galleryIndex }) {
                                reader.scrollTo(viewModel.postMediaMapping[mediaI].key, anchor: viewModel.mediaUrls.count - presentationState.galleryIndex < 3 ? .bottom : .top)
                            }
                        }
                    }
                    .opacity(opacity)
                    .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                        let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                        softVibrate.impactOccurred()
                        viewModel.load {
                            pullToRefreshShowing = false
                            viewModel.prefetch()
                        }
                    }

                    .navigationTitle(viewModel.posts.first?.sub?.clean ?? "")
                    .navigationBarItems(trailing:
                                            Link(destination: viewModel.url) {
                                                Image(systemName: "square.and.arrow.up")
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
            .onChange(of: presentedDismissGesture.presenting, perform: { value in
                if value && appState.fullscreenView == nil {
                    appState.fullscreenView = AnyView(
                        PresentedPost()
                            .onDisappear {
                                opacity = 1
                                presentedDismissGesture.dismiss = false
                                presentedDismissGesture.canDrag = true
                                presentedDismissGesture.dragging = false
                            }
                            .environmentObject(viewModel)
                            .environmentObject(presentationState)
                            .environmentObject(presentedDismissGesture)
                    )
                } else {
                    appState.fullscreenView = nil
                }
            })
        }
        .onAppear {
            viewModel.prefetch()
        }
        .environmentObject(presentationState)
        .environmentObject(presentedDismissGesture)
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
