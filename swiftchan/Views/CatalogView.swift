//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

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
                            id: \.self.id) { page in
                        ForEach(page.threads.indices, id: \.self) { index in
                            OPView(boardName: self.viewModel.boardName,
                                   post: page.threads[index],
                                   comment: self.viewModel.comments[index])
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
