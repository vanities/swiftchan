//
//  ThreadView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI

struct ThreadView: View {
    @ObservedObject var viewModel: ViewModel

    @State var isPresentingGallery: Bool = false
    @State var postIndex: Int = 0
    @State var galleryIndex: Int = 0

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return GeometryReader { geo in
            ZStack {
                ScrollView {
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0,
                              content: {
                                ForEach(self.viewModel.posts.indices, id: \.self) { index in
                                    PostView(boardName: self.viewModel.boardName,
                                             post: self.viewModel.posts[index],
                                             index: index,
                                             isPresentingGallery: self.$isPresentingGallery,
                                             galleryIndex: self.$postIndex)
                                        .onChange(of: self.isPresentingGallery, perform: { _ in
                                            if self.postIndex == index {
                                                self.galleryIndex = self.viewModel.postMediaMapping[index] ?? 0

                                            }
                                        })
                                }
                                .frame(minWidth: UIScreen.main.bounds.width,
                                       minHeight: geo.size.height/3)
                              }
                    )
                }.sheet(isPresented: self.$isPresentingGallery) {
                    GalleryView(selection: self.$galleryIndex,
                                urls: self.viewModel.mediaUrls,
                                thumbnailUrls: self.viewModel.thumbnailMediaUrls
                    )
                }
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "fit", id: 5551578)
        ThreadView(viewModel: viewModel)
    }
}
