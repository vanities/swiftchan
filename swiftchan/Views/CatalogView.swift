//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import Alamofire

struct CatalogView: View {
    let boardName: String
    
    @State var loaded: Bool = false
    
    @State var pages: [Page] = []
    
    var body: some View {
        return LazyVGrid(columns: [GridItem(.fixed(20))],
                         alignment: .center,
                         spacing: 20,
                         pinnedViews: [],
                         content: {
                            /*
                            ForEach(self.pages, id: \.self) {
                            }
 */
                            Text("Placeholder")
                            Text("Placeholder")
                         }
        )
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
                guard let pages = response.value else { return }
                self.pages = pages
            }
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView(boardName: "fit")
    }
}
