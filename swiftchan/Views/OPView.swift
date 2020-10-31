//
//  OPView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import URLImage
import WebKit

struct OPView: View {
    let boardName: String
    let thread: Thread
    
    var body: some View {
        return
            NavigationLink(
                destination: Text("thread"),
                label: {
            ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(.systemBackground))
                .border(Color(.black))
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
                        HStack() {
                            Text(thread.getDatePosted())
                            Text("•")
                            Text(String(thread.replyCount) + "R | " + String(thread.imageCount) + "F")
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

struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView(boardName: "fit")
    }
}
