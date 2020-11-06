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

    @Binding var isPresentingGallery: Bool

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
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.isPresentingGallery = true
                                }
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
                 post: Post.example(sticky: 1,
                                closed: 1,
                                subject: LoremLipsum.full,
                                comment: LoremLipsum.full
                 ),
                 index: 0,
                 isPresentingGallery: .constant(false)
        )
    }
}
