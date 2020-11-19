//
//  CommentView.swift
//  swiftchan
//
//  Created by vanities on 11/1/20.
//

import SwiftUI

struct CommentView: View {
    let message: String
    @State var comment: Text = Text("")

    var body: some View {
        return comment
            .onAppear( perform:
                self.setCommentViews
            )
    }

    func setCommentViews() {
        let parser = CommentParser(comment: self.message)
        self.comment = parser.getComment()
    }

}

struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        return
            CommentView(message: "<a href=\"#p530723473\" class=\"quotelink\">&gt;&gt;530723473</a><br>this is a quotelink<br><span class=\"quote\">&gt;This is a quote</span><br>")
            .frame(width: 500, height: 500, alignment: .center)
    }
}
