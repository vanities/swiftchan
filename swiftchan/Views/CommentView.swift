//
//  CommentView.swift
//  swiftchan
//
//  Created by vanities on 11/1/20.
//

import SwiftUI
import SwiftSoup

struct CommentView: View {
    let message: String
    
    var body: some View {
        self.getComment()
    }
    @State var commentViews: [AnyView] = []
    
    func getComment() -> AnyView {
        do {
            let document = self.parseComment()
            if let document = document {
                let text = try document.text()
                let components = text.components(separatedBy: " ")
                for s in components {
                    if s.starts(with: ">>") {
                        commentViews.append(AnyView(
                            Text(s)
                                .foregroundColor(.green)
                        ))
                    }

                }

                return AnyView(
                    VStack {
                        Text("heelo\najnd")
                        Text(text)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                    }
                )
            }
        } catch Exception.Error(let type, let message) {
            print(message)
        } catch {
            print("error")
        }
        return AnyView(Text(""))
    }
    
    func parseComment() -> Document? {
        do {
            return try SwiftSoup.parse(message.replacingOccurrences(of: "<br>", with: "\a"))
        } catch Exception.Error(let type, let message) {
            print(message)
        } catch {
            print("error")
        }
        return nil
    }
}

struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        CommentView(message: "<a href=\"#p530723473\" class=\"quotelink\">&gt;&gt;530723473</a><br>this is a quotelink<br><span class=\"quote\">&gt;This is a quote</span><br>")
            .frame(width: 500, height: 500, alignment: .center)
    }
}
