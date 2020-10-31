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

    var body: some View {
        return
            ScrollView {
                LazyVGrid(columns: [GridItem(.fixed(20))],
                          alignment: .center,
                          spacing: 20,
                          pinnedViews: [],
                          content: {
                            ForEach(self.pages, id: \.self.number) { page in
                                ForEach(page.threads, id: \.self.number) { thread in
                                    OPView(boardName: boardName, thread: thread)
                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    }
                                    .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height/3)
                            }
                          }
                )
            }
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
        CatalogView(boardName: "fit")
    }
}
