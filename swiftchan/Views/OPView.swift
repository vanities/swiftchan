//
//  OPView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI

struct OPView: View {
    let boardName: String
    let post: Post

    var body: some View {
        return NavigationLink(
            destination:
                ThreadView(viewModel:
                            ThreadView.ViewModel(boardName: self.boardName,
                                                 id: self.post.number)
                ),
            label: {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .border(Color(.gray))
                    VStack(alignment: .leading, spacing: 0 ) {
                        // image
                        if let url = post.getMediaUrl(boardId: boardName),
                            let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {
                            ThumbnailMediaView(url: url,
                                               thumbnailUrl: thumbnailUrl,
                                               selected: true)
                        }
                        // sticky, closed, image count, thread count
                        HStack(alignment: .center) {
                            if let replyCount = post.replyCount {
                                Text("R: \(replyCount)")
                                    .italic()
                            }
                            if let imageCount = post.imageCount {
                                Text("F: \(imageCount)")
                                    .italic()
                            }
                            if let sticky = post.sticky,
                               sticky == 1 {
                                Image(systemName: "pin")
                                    .rotationEffect(.degrees(45))
                            }
                            if let closed = post.closed,
                               closed == 1 {
                                Image(systemName: "lock")
                            }
                        }
                        // subject
                        Text(post.subject ?? "")
                            .font(.system(size: 18))
                            .bold()
                            .lineLimit(1)
                            .padding(.bottom, 5)
                        //comment
                        if let comment = self.post.comment {
                            CommentView(message: comment)
                                .lineLimit(5)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.all, 5)
                }
            })
        .buttonStyle(PlainButtonStyle())
    }
}

struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        OPView(boardName: "fit",
               post: Post.example(sticky: 1,
                                    closed: 1,
                                    subject: LoremLipsum.full,
                                    comment: LoremLipsum.full
               )
        )
    }
}
