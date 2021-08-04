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
    @EnvironmentObject var presentationState: PresentationState
    @EnvironmentObject var presentedDismissGesture: DismissGesture

    let index: Int

    var body: some View {
        let boardName = self.viewModel.boardName
        let post = index < self.viewModel.posts.count ?
        self.viewModel.posts[index] : Post.example()!
        let comment = index < self.viewModel.comments.count ?
        self.viewModel.comments[index] : AttributedString("")
        let replies = self.viewModel.replies[index] ?? nil

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Colors.Post.background)
                .cornerRadius(5)
                .border(Colors.Post.border)

            VStack(alignment: .leading, spacing: 0) {
                // subject
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
                        // .scaledToFit()
                            .scaledToFill() // VStack
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.presentationState.galleryIndex = self.viewModel.postMediaMapping[index] ?? 0
                                    self.presentationState.presentingSheet = .gallery
                                    self.presentedDismissGesture.presenting.toggle()
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
                                    .foregroundColor(Colors.Post.capcode)
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
                                .background(
                                    Rectangle()
                                        .fill(color)
                                        .cornerRadius(5)
                                        .padding(.horizontal, -5)
                                )
                                .offset(x: 5)

                        }
                        // Anonymous
                        if let name = post.name {
                            Text(name)
                                .bold()
                                .foregroundColor(Colors.Post.name)
                        }
                        // trip
                        if let trip = post.trip {
                            Text(trip)
                                .italic()
                                .foregroundColor(Colors.Post.trip)
                        }
                    }
                    .padding(.leading, 1)
                }
                // comment
                Text(comment)
                    .lineLimit(nil)
                    .textSelection(.enabled)
                    .id(index)
                    .padding(.top, 20)
                    .accessibilityLabel(AccessibilityLabels.postComment)

                // replies
                if let replies = replies {
                    Text("\(replies.count) \(replies.count == 1 ? "REPLY" : "REPLIES")")
                        .bold()
                        .onTapGesture {
                            self.presentationState.commentRepliesIndex = index
                            self.presentationState.presentingSheet = .replies
                            self.presentedDismissGesture.presenting.toggle()
                        }
                        .zIndex(-1)
                        .padding(.top, 10)
                }
            }
            .padding(.all, 10)
        }

    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        // let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        let viewModel = ThreadView.ViewModel(boardName: "biz", id: 21374000)

        return PostView(index: 0)
            .environmentObject(viewModel)
            .environmentObject(AppState())
            .environmentObject(DismissGesture())
            .environmentObject(PresentationState())
    }
}
