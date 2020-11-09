//
//  OPView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import URLImage

struct OPView: View {
    let boardName: String
    let thread: Post

    var body: some View {
        return NavigationLink(
            destination: ThreadView(id: thread.number, boardName: boardName),
            label: {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .border(Color(.gray))
                    VStack(alignment: .leading, spacing: 0 ) {
                        // image
                        if let url = thread.getMediaUrl(boardId: boardName) {
                            if MediaDetector.isImage(url: url) {
                                URLImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                            } else if MediaDetector.isWebm(url: url) {
                                VLCVideoView(url: url, preview: true,
                                             play: .constant(false)
                                             )
                            }
                        }
                        // sticky, closed, image count, thread count
                        HStack(alignment: .center) {
                            if let replyCount = thread.replyCount {
                                Text("R: \(replyCount)")
                                    .italic()
                            }
                            if let imageCount = thread.imageCount {
                                Text("F: \(imageCount)")
                                    .italic()
                            }
                            if let sticky = thread.sticky,
                               sticky == 1 {
                                Image(systemName: "pin")
                                    .rotationEffect(.degrees(45))
                            }
                            if let closed = thread.closed,
                               closed == 1 {
                                Image(systemName: "lock")
                            }
                        }
                        // subject
                        Text(thread.subject ?? "")
                            .font(.system(size: 18))
                            .bold()
                            .lineLimit(1)
                            .padding(.bottom, 5)
                        //comment
                        if let comment = self.thread.comment {
                            CommentView(message: comment)
                                .lineLimit(5)
                                .padding(.top, 10)
                        }
                        //
                    }
                    .padding(.all, 5)
                }
            })
    }
}

struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        OPView(boardName: "fit",
               thread: Post.example(sticky: 1,
                                    closed: 1,
                                    subject: LoremLipsum.full,
                                    comment: LoremLipsum.full
               )
        )
    }
}
