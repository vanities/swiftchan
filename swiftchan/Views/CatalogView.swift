//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import Alamofire
import URLImage

struct CatalogView: View {
    let boardName: String

    @State var loaded: Bool = false

    @State var pages: [Page] = []
    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center), GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return
            ScrollView {
                LazyVGrid(columns: columns,
                          alignment: .center,
                          spacing: 0) {
                    ForEach(self.pages, id: \.self.number) { page in
                        ForEach(page.threads, id: \.self.number) { thread in
                            OPView(boardName: boardName,
                                   thread: thread)
                        }
                    }
                }
            }
            .navigationBarTitle(Text(self.boardName), displayMode: .inline)
            .onAppear {
                if !self.loaded {
                    self.getCatalog()
                    self.loaded
                        .toggle()
                }
            }
    }

    private func getCatalog() {
        let url = "https://a.4cdn.org/" + self.boardName + "/catalog.json"

        AF.request(url)
            .validate()
            .responseDecodable(of: [Page].self) { (response) in
                guard let data = response.value else { return }
                self.pages = data
            }
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView(boardName: "fit", pages: [
            Page(number: 0, threads: [
                Post.example(sticky: 1,
                               closed: 1,
                               subject: LoremLipsum.full,
                               comment: LoremLipsum.full
                ),
                Post.example(sticky: 0,
                               closed: 0,
                               subject: "",
                               comment: LoremLipsum.full
                ),
            ])
        ]
        )
    }
}
