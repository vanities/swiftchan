//
//  SortRow.swift
//  swiftchan
//
//  Created by vanities on 10/15/21.
//

import SwiftUI

struct RepliesSort: View {
    let viewModel: CatalogView.CatalogViewModel

    var body: some View {
        SortRow(imageName: "arrowshape.turn.up.left.fill", text: "Replies", viewModel: viewModel)
    }
}

struct SortRow: View {
    var imageName: String
    var text: String

    enum SortType {
        case ascending
        case descending
        case none
    }

    @EnvironmentObject var userSettings: UserSettings
    let viewModel: CatalogView.CatalogViewModel
    @State var sort: SortType = .none

    var favorited: Bool {
        userSettings.favoriteBoards.contains(viewModel.boardName)
    }

    var body: some View {
        ZStack {
            MultiActionItem(
                icon: Image(systemName: imageName)
                    .foregroundColor(Colors.Other.star),
                iconAnimation: EmptyView(),
                text: Text(text)
            ) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

                //if userSettings
            }
        }
    }
}

struct SortRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogView.CatalogViewModel(boardName: "fit")
        RepliesSort(viewModel: viewModel)
            .environmentObject(UserSettings())
    }
}
