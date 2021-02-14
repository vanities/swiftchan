//
//  OPView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct OPView: View {
    @StateObject var threadViewModel: ThreadView.ViewModel

    let boardName: String
    let post: Post
    let comment: NSMutableAttributedString

    init(boardName: String, post: Post, comment: NSMutableAttributedString) {
        self.boardName = boardName
        self.post = post
        self.comment = comment
        self._threadViewModel = StateObject(wrappedValue:
                                                ThreadView.ViewModel(boardName: boardName,
                                                    id: post.no))
    }

    var body: some View {
        return NavigationLink(
            destination:
                ThreadView()
                .environmentObject(self.threadViewModel)
        ) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .border(Color(.gray))
                VStack(alignment: .leading, spacing: 0 ) {
                    // image
                    if let url = self.post.getMediaUrl(boardId: self.boardName),
                       let thumbnailUrl = self.post.getMediaUrl(boardId: self.boardName, thumbnail: true) {
                        ThumbnailMediaView(url: url,
                                           thumbnailUrl: thumbnailUrl,
                                           useThumbnailGif: false)

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
                    // comment
                    // AttributedText(self.comment, height: .constant(200), linkPressed: {_ in})
                    // swiftlint:disable force_cast
                    AttributedText(comment.attributedSubstring(from: NSRange(location: 0, length: min(comment.length, 200))).mutableCopy() as! NSMutableAttributedString)
                        .lineLimit(20)
                        .lineBreakMode(.byTruncatingTail)
                        .frameTextView(
                            self.comment,
                            maxWidth: UIScreen.main.bounds.width/2 - 10,
                            maxHeight: UIScreen.main.bounds.height/2
                    )
                    // swiftlint:enable force_cast

                }
                .padding(.all, 5)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        if let example = Post.example() {
            OPView(boardName: "fit", post: example, comment: NSMutableAttributedString())
        }
    }
}
