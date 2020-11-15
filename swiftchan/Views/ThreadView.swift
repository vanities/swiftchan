//
//  ThreadView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import Alamofire

struct ThreadView: View {
    @ObservedObject var viewModel: ViewModel

    @State var isPresentingGallery: Bool = false
    @State var galleryIndex: Int = 0

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return
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
                                             galleryIndex: self.$galleryIndex)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                }
                                .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height/3)
                              }
                    )
                }.sheet(isPresented: self.$isPresentingGallery) {
                    GalleryView(selection: self.$galleryIndex, urls: self.viewModel.mediaUrls)
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
