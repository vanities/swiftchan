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
    @State private var showReply: Bool = false
    @State private var replyId: Int = 0

    let index: Int

    var body: some View {
        let boardName = viewModel.boardName
        let post = index < viewModel.posts.count ?
        viewModel.posts[index] : Post.example()!
        let comment = index < viewModel.comments.count ?
        viewModel.comments[index] : AttributedString("")
        let replies = viewModel.replies[index] ?? nil

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
                            thumbnailUrl: thumbnailUrl
                        )
                            .accessibilityIdentifier(AccessibilityIdentifiers.thumbnailMediaImage(index))
                            .frame(width: UIScreen.main.bounds.width/2)
                            .scaledToFill() // VStack
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    let mediaIndex = viewModel.postMediaMapping[index] ?? 0
                                    viewModel.media[mediaIndex].isSelected = true
                                    presentationState.galleryIndex = mediaIndex
                                    presentationState.presentingGallery = true
                                }
                            }
                            .padding(.leading, -5)
                    }
                    // index, postnumber, date
                    VStack(alignment: .leading) {
                        HStack {
                            Text(String(index))
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
                    .textSelection(.enabled)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 20)
                    .accessibilityIdentifier(AccessibilityIdentifiers.postText(index))

                // replies
                if let replies = replies {
                    NavigationLink(
                        destination: {
                            if let replies = viewModel.replies[index] {
                                RepliesView(replies: replies)
                                    .environmentObject(viewModel)
                                    .environmentObject(presentationState)
                                    .onAppear {
                                        presentationState.presentingReplies = true
                                    }
                                    .onDisappear {
                                        presentationState.presentingReplies = false
                                    }
                            }
                        },
                        label: {
                            Text("\(replies.count) \(replies.count == 1 ? "REPLY" : "REPLIES")")
                                .bold()
                                .padding(.top, 10)

                        }
                    )
                }
            }
            .padding(.all, 10)
        }
    }
}

#if DEBUG
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
#endif
