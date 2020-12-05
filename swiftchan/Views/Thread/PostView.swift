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
    @Binding var presentingSheet: PresentingSheet

    @Binding var galleryIndex: Int
    @Binding var commentRepliesIndex: Int

    var body: some View {
        let boardName = self.viewModel.boardName
        let post = self.viewModel.posts[index]
        let comment = self.viewModel.comments[index]
        let replies = self.viewModel.replies[index] ?? nil

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
                            thumbnailUrl: thumbnailUrl,
                            useThumbnailGif: false)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width/2)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.galleryIndex = self.viewModel.postMediaMapping[index] ?? 0
                                    self.presentingSheet = .gallery
                                    self.isPresenting.toggle()
                                }
                            }
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
                        HStack {
                            if let name = post.name {
                                Text(name)
                            }
                            if let trip = post.trip {
                                Text(trip)
                                    .italic()
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                }
                // comment
                comment
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
                        .padding(.top, 5)
                }
            }
            .padding(.all, 5)
        }
    }
}

extension PostView: Identifiable {
    var id: Int { return self.index }

}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        PostView(index: 0,
                 isPresenting: .constant(false),
                 presentingSheet: .constant(.gallery),
                 galleryIndex: .constant(0),
                 commentRepliesIndex: .constant(0)
        )
        .environmentObject(viewModel)
        .environmentObject(AppState())
    }
}
