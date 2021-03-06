//
//  FavoriteStar.swift
//  swiftchan
//
//  Created by vanities on 11/23/20.
//

import SwiftUI

struct FavoriteStar: View {
    @EnvironmentObject var userSettings: UserSettings
    let viewModel: CatalogView.CatalogViewModel

    var favorited: Bool {
        self.userSettings.favoriteBoards.contains(self.viewModel.boardName)
    }

    var body: some View {
        Image(systemName: self.favorited ? "star.fill" : "star")
            .onTapGesture {
                let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                softVibrate.impactOccurred()

                if self.favorited {
                    if let index = self.userSettings.favoriteBoards.firstIndex(of: self.viewModel.boardName) {
                        self.userSettings.favoriteBoards.remove(at: index)
                    }
                } else {
                    self.userSettings.favoriteBoards.append(self.viewModel.boardName)
                }
            }
            .foregroundColor(.yellow)
    }
}

struct FavoriteStar_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogView.CatalogViewModel(boardName: "fit")
        FavoriteStar(viewModel: viewModel)
    }
}
