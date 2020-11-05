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

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return ScrollView {
            LazyVGrid(columns: columns,
                      alignment: .center,
                      spacing: 0,
                      content: {
                        ForEach(self.posts.indices) { index in
                            PostView(boardName: boardName, post: self.posts[index], index: index)
                                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        }
                        .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height/3)
                      }
            )
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
                let op = data.posts.dropFirst()
                self.posts = data.posts
            }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(id: 17018018,
                   boardName: "fit",
                   loaded: false,
                   posts: [
                    Post(number: 01234567890,
                         name: "Anonymous",
                         id: "1",
                         comment: "cool comment!",
                         capcode: "",
                         country: "",
                         time: 1604547871,
                         tim: 1358180697001,
                         ext: ".jpg"),
                   ]
        )
    }
}
