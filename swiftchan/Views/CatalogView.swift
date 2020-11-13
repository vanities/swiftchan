//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import Alamofire

struct CatalogView: View {
    @ObservedObject var viewModel: ViewModel

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center), GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return
            ScrollView {
                LazyVGrid(columns: columns,
                          alignment: .center,
                          spacing: 0) {
                    ForEach(self.viewModel.pages,
                            id: \.self.number) { page in
                        ForEach(page.threads, id: \.self.number) { thread in
                            OPView(boardName: self.viewModel.boardName,
                                   thread: thread)
                        }
                    }
                }
            }
            .navigationBarTitle(Text(self.viewModel.boardName), displayMode: .inline)
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogView.ViewModel(boardName: "fit")
        CatalogView(viewModel: viewModel)
    }
}
