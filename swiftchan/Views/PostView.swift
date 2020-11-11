//
//  PostView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import URLImage
import UIKit

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
                        ZStack {
                            Rectangle()
                                .fill(Color.gray)
                            if let url = post.getMediaUrl(boardId: boardName) {
                                // media
                                if MediaDetector.isImage(url: url) {
                                    URLImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)

                                    }
                                } else if MediaDetector.isWebm(url: url) {
                                    /*
                                    VLCContainerView(url: url,
                                                     autoPlay: false,
                                                     play: false)
 */

                                }
                            }
                        }
                        .frame(width: 100, height: 100)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.isPresentingGallery = true
                            }
                        }
                        // index, postnumber, date
                        VStack(alignment: .leading) {
                            HStack {
                                Text(String(self.index))
                                Text("•")
                                Text("#" + String(self.post.number))
                            }
                            Text(self.post.getDatePosted())
                        }
                    }
                    // comment
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
