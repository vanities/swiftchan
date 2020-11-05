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
    let thread: Post

    var body: some View {
        return
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .border(Color(.black))
                VStack(alignment: .leading, spacing: 0 ) {
                    HStack(alignment: .top) {
                        if let imageURL = thread.getMediaUrl(boardId: boardName) {
                            URLImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .frame(width: 100, height: 100)

                            }
                        }
                        VStack(alignment: .leading) {
                            Text("#" + String(thread.number))
                            Text(thread.name)
                            HStack {
                                Text(thread.getDatePosted())
                            }
                        }
                    }
                    if let comment = self.thread.comment {
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
        CatalogView(boardName: "fit")
    }
}
