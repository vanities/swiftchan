//
//  PostView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct PostView: View {
    let boardName: String
    let post: Post
    let index: Int

    @Binding var isPresentingGallery: Bool
    @Binding var galleryIndex: Int

    var body: some View {
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(.systemBackground))
                .border(Color(.gray))
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    if let url = post.getMediaUrl(boardId: boardName),
                       let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray)
                            ThumbnailMediaView(
                                url: url,
                                thumbnailUrl: thumbnailUrl)

                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.width/2)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.isPresentingGallery = true
                                self.galleryIndex = index
                            }
                        }
                    }
                    // index, postnumber, date
                    VStack(alignment: .leading) {
                        HStack {
                            Text(String(self.index))
                            Text("•")
                            Text("#" + String(self.post.no))
                        }
                        Text(self.post.getDatePosted())
                    }
                }
                // comment
                if let comment = self.post.com {
                    CommentView(message: comment)
                        .padding(.top, 20)
                }

            }
            .padding(.all, 5)
        }
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(boardName: "fit",
                 post: Post.example(),
                 index: 0,
                 isPresentingGallery: .constant(false),
                 galleryIndex: .constant(0)
        )
    }
}
