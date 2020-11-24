//
//  FavoriteStar.swift
//  swiftchan
//
//  Created by vanities on 11/23/20.
//

import SwiftUI

struct FavoriteStar: View {
    @EnvironmentObject var userSettings: UserSettings
    let viewModel: CatalogView.ViewModel

    var body: some View {
        Image(systemName: self.userSettings.favoriteBoards.contains(self.viewModel.boardName) ? "star.fill" : "star").onTapGesture {
            let favorited = self.userSettings.favoriteBoards.contains(self.viewModel.boardName)

            if favorited {
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
        let viewModel = CatalogView.ViewModel(boardName: "fit")
        FavoriteStar(viewModel: viewModel)
    }
}
