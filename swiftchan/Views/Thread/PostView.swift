//
//  PostView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct PostView: View {
    @EnvironmentObject var appState: AppState
    let boardName: String
    let post: Post
    let index: Int
    let comment: Text
    let replies: [Int]?

    @Binding var isPresenting: Bool
    @Binding var presentingSheet: PresentingSheet

    @Binding var galleryIndex: Int
    @Binding var commentRepliesIndex: Int

    var body: some View {
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(.systemBackground))
                .border(Color(.gray))
            VStack(alignment: .leading, spacing: 0) {
                if let subject = post.sub {
                    Text(subject.clean)
                        .bold()
                        .padding(.bottom, 5)
                }
                HStack(alignment: .top) {
                    if let url = post.getMediaUrl(boardId: boardName),
                       let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {

                        ThumbnailMediaView(
                            url: url,
                            thumbnailUrl: thumbnailUrl)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width/2)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.presentingSheet = .gallery
                                    self.isPresenting.toggle()
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
                comment
                    .padding(.top, 20)

                // replies
                if let replies = self.replies {
                    Text("\(replies.count) \(replies.count == 1 ? "REPLY" : "REPLIES")")
                        .bold()
                        .onTapGesture {
                            self.commentRepliesIndex = index
                            self.presentingSheet = .replies
                            self.isPresenting.toggle()
                        }
                        .padding(.top, 5)
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
                 comment: Text("comment!"),
                 replies: [0, 1],
                 isPresenting: .constant(false),
                 presentingSheet: .constant(.gallery),
                 galleryIndex: .constant(0),
                 commentRepliesIndex: .constant(0)
        )
    }
}
