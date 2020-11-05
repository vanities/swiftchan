//
//  PostView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import URLImage

struct PostView: View {
    let boardName: String
    let post: Post
    let index: Int

    var body: some View {
        return
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .border(Color(.gray))
                VStack(alignment: .leading, spacing: 0 ) {
                    HStack(alignment: .top) {
                        if let imageURL = post.getMediaUrl(boardId: boardName) {
                            URLImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .frame(width: 100, height: 100)

                            }
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text(String(index))
                                Text("•")
                                Text("#" + String(post.number))
                            }
                            Text(post.getDatePosted())
                        }
                    }
                    if let comment = self.post.comment {
                        CommentView(message: comment)
                            .padding(.top, 10)
                    }

                }
                .padding(.all, 5)
            }
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(boardName: "fit",
                 post:
                    Post(number: 01234567890,
                         name: "Anonymous",
                         id: "1",
                         comment: "cool comment!",
                         capcode: "",
                         country: "",
                         time: 1604547871,
                         tim: 1358180697001,
                         ext: ".jpg"),
                 index: 0
        )
    }
}
