//
//  OPView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct OPView: View {
    let boardName: String
    let post: Post
    let comment: Text

    var body: some View {
        return NavigationLink(
            destination:
                ThreadView()
                .environmentObject(
                    ThreadView.ViewModel(boardName: self.boardName,
                                         id: self.post.no)
                )) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .border(Color(.gray))
                VStack(alignment: .leading, spacing: 0 ) {
                    // image
                    if let url = post.getMediaUrl(boardId: boardName),
                       let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {
                        ThumbnailMediaView(url: url,
                                           thumbnailUrl: thumbnailUrl)

                    }
                    // sticky, closed, image count, thread count
                    HStack(alignment: .center) {
                        if let replyCount = post.replies {
                            Text("R: \(replyCount)")
                                .italic()
                        }
                        if let imageCount = post.images {
                            Text("F: \(imageCount)")
                                .italic()
                        }
                        if let sticky = post.sticky,
                           sticky == 1 {
                            Image(systemName: "pin")
                                .rotationEffect(.degrees(45))
                                .foregroundColor(.yellow)
                        }
                        if let closed = post.closed,
                           closed == 1 {
                            Image(systemName: "lock")
                                .foregroundColor(.red)
                        }
                    }
                    // subject
                    Text(post.sub?.clean ?? "")
                        .font(.system(size: 18))
                        .bold()
                        .lineLimit(nil)
                        .padding(.bottom, 5)
                    //comment
                    comment
                        .lineLimit(20)
                }
                .padding(.all, 5)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        OPView(boardName: "fit", post: Post.example(), comment: Text(""))
    }
}
