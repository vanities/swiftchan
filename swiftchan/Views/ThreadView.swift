//
//  ThreadView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import Alamofire

struct ThreadView: View {
    let id: Int
    let boardName: String

    @State var loaded: Bool = false
    @State var posts: [Post] = []
    @State var imagesUrls: [URL] = []
    @State var isPresentingGallery: Bool = false

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return
            ZStack {
                ScrollView {
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0,
                              content: {
                                ForEach(self.posts.indices, id: \.self) { index in
                                    PostView(boardName: self.boardName,
                                             post: self.posts[index],
                                             index: index,
                                             isPresentingGallery: self.$isPresentingGallery)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                }
                                .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height/3)
                              }
                    )
                }.sheet(isPresented: self.$isPresentingGallery) {
                    GalleryView(imageUrls: self.imagesUrls)
                }
            }
            .onAppear {
                if !self.loaded {
                    self.getThread()
                    self.loaded
                        .toggle()
                }

            }
    }
    private func getThread() {
        let url = "https://a.4cdn.org/" + self.boardName + "/thread/" + String(self.id) + ".json"

        AF.request(url)
            .validate()
            .responseDecodable(of: ThreadPage.self) { (response) in
                guard let data = response.value else { return }
                self.posts = data.posts

                for post in self.posts {
                    if let imageURL = post.getMediaUrl(boardId: boardName) {
                        self.imagesUrls.append(imageURL)
                    }
                }
            }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(id: 17018018,
                   boardName: "fit",
                   loaded: false,
                   posts: [
                    Post.example(sticky: 0,
                                 closed: 0,
                                 subject: "",
                                 comment: LoremLipsum.full
                    )
                   ]
        )
    }
}
