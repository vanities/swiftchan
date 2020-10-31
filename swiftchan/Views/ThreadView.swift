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

    var body: some View {
        return ScrollView {
            LazyVGrid(columns: [GridItem(.fixed(20))],
                      alignment: .center,
                      spacing: 20,
                      pinnedViews: [],
                      content: {
                        ForEach(self.posts, id: \.self.number) { post in
                            PostView(boardName: boardName, thread: post)
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
        Text("asdaa")
        //ThreadView()
    }
}
