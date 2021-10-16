//
//  SortRow.swift
//  swiftchan
//
//  Created by vanities on 10/15/21.
//

import SwiftUI

struct SortRow: View {
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
                icon: Image(systemName: favorited ? "star.fill" : "star")
                    .foregroundColor(Colors.Other.star)
                    .scaleEffect(favorited ? 1.3 : 1),
                iconAnimation: EmptyView(),
                text: Text("Favorite")
            ) {
                let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                softVibrate.impactOccurred()

                if self.favorited {
                    if let index = userSettings.favoriteBoards.firstIndex(of: viewModel.boardName) {
                        withAnimation {
                            _ = userSettings.favoriteBoards.remove(at: index)
                        }
                    }
                } else {
                    withAnimation {
                        userSettings.favoriteBoards.append(viewModel.boardName)
                    }
                }
            }
        }
    }
}

struct SortRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogView.CatalogViewModel(boardName: "fit")
        SortRow(viewModel: viewModel)
            .environmentObject(UserSettings())
    }
}
