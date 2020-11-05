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
    let thread: Thread

    var body: some View {
        return
            NavigationLink(
                destination: ThreadView(id: thread.number, boardName: boardName),
                label: {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .border(Color(.gray))
                        VStack(alignment: .leading, spacing: 0 ) {
                            Text(thread.subject ?? "")
                                .padding(.bottom, 5)
                            HStack(alignment: .top) {
                                URLImage(url: thread.getMediaUrl(boardId: boardName)) { image in
                                    image
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                }
                                VStack(alignment: .leading) {
                                    Text("#" + String(thread.number))
                                    Text(thread.name)
                                    HStack {
                                        Text(thread.getDatePosted())
                                        Text("•")
                                        Text(String(thread.replyCount) + "R | " + String(thread.imageCount) + "F")
                                    }
                                }
                            }
                            if let comment = self.thread.comment {
                                CommentView(message: comment)
                                .padding(.top, 10)

                            }
                        }
                        .padding(.all, 5)
                    }
                })
    }
}

struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        OPView(boardName: "fit",
               thread: Thread.init(number: 0123456789,
                                   sticky: 1,
                                   closed: 1,
                                   name: "Anonymous",
                                   id: "12345",
                                   subject: "SUBJECT",
                                   comment: "comment",
                                   trip: "",
                                   capcode: "",
                                   country: "",
                                   time: 1604547871,
                                   tim: 1358180697001,
                                   ext: ".jpg",
                                   replyCount: 5,
                                   imageCount: 10)
        )
    }
}
