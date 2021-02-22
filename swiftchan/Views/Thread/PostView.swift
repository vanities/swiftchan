//
//  PostView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct PostView: View {
    @EnvironmentObject var viewModel: ThreadView.ViewModel
    @EnvironmentObject var appState: AppState
    let index: Int

    @Binding var isPresenting: Bool
    @Binding var presentingSheet: PresentedPost.PresentType

    @Binding var galleryIndex: Int
    @Binding var commentRepliesIndex: Int

    var body: some View {
        let boardName = self.viewModel.boardName
        let post = index < self.viewModel.posts.count ?
            self.viewModel.posts[index] : Post.example()!
        let comment = index < self.viewModel.comments.count ?
            self.viewModel.comments[index] : NSMutableAttributedString(string: "")
        let replies = self.viewModel.replies[index] ?? nil

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(.systemBackground))
                .border(Color(.gray))

            // subject
            VStack(alignment: .leading, spacing: 0) {
                if let subject = post.sub {
                    Text(subject.clean)
                        .bold()
                        .font(Font.system(.title3))
                        .padding(.bottom, 15)
                }

                // media
                HStack(alignment: .top) {
                    if let url = post.getMediaUrl(boardId: boardName),
                       let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {

                        ThumbnailMediaView(
                            url: url,
                            thumbnailUrl: thumbnailUrl,
                            useThumbnailGif: false
                        )
                        .frame(width: UIScreen.main.bounds.width/2)
                        .scaledToFit()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.galleryIndex = self.viewModel.postMediaMapping[index] ?? 0
                                self.presentingSheet = .gallery
                                self.isPresenting.toggle()
                            }
                        }
                        .padding(.leading, -5)
                    }
                    // index, postnumber, date
                    VStack(alignment: .leading) {
                        HStack {
                            Text(String(self.index))
                            Text("•")
                            Text("#" + String(post.no))
                        }
                        Text(post.getDatePosted())
                        HStack {
                            if let capcode = post.capcode {
                                Text(capcode)
                                    .foregroundColor(.orange)
                                    .bold()
                            }
                        }
                        HStack {
                            if let country = post.country {
                                Text(getFlag(from: country))
                            }
                            if let countryName = post.country_name {
                                Text(countryName)
                                    .bold()
                            }
                        }
                        if let id = post.pid {
                            let color = Color.randomColor(seed: id)
                            Text(id.description)
                                .foregroundColor(color.isLight() ? .black : .white)
                                .background(color.padding(.all, -1))
                        }
                        HStack {
                            // Anonymous
                            if let name = post.name {
                                Text(name)
                                    .bold()
                                    .foregroundColor(.gray)
                            }
                            if let trip = post.trip {
                                Text(trip)
                                    .italic()
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                    .padding(.leading, 1)
                }
                // comment
                TextView(comment)
                    .autoDetectDataTypes(.link)
                    .enableScrolling(false)
                    .isEditable(false)
                    .isSelectable(true)
                    .padding(.top, 20)

                // replies
                if let replies = replies {
                    Text("\(replies.count) \(replies.count == 1 ? "REPLY" : "REPLIES")")
                        .bold()
                        .onTapGesture {
                            self.commentRepliesIndex = index
                            self.presentingSheet = .replies
                            self.isPresenting.toggle()
                        }
                        .zIndex(-1)
                        .padding(.top, 10)
                }
            }
            .padding(.all, 10)
        }
    }
}

extension PostView: Identifiable {
    var id: Int { return self.index }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        // let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        let viewModel = ThreadView.ViewModel(boardName: "biz", id: 21374000)

        return PostView(index: 0,
                 isPresenting: .constant(false),
                 presentingSheet: .constant(.gallery),
                 galleryIndex: .constant(0),
                 commentRepliesIndex: .constant(0)
        )
        .environmentObject(viewModel)
        .environmentObject(AppState())
    }
}
