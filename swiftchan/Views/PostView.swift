//
//  PostView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import URLImage
import WebKit

struct PostView: View {
    let boardName: String
    let thread: Post

    var body: some View {
        return
            NavigationLink(
                destination: ThreadView(id: thread.number, boardName: boardName),
                label: {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .border(Color(.black))
                        VStack(alignment: .leading, spacing: 0 ) {
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
                                    }
                                }
                            }
                            WebView(text: thread.comment ?? "")
                                .padding(.top, 10)

                        }
                        .padding(.all, 5)
                    }
                })
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView(boardName: "fit")
    }
}
