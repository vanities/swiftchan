//
//  FavoriteStar.swift
//  swiftchan
//
//  Created by vanities on 11/23/20.
//

import SwiftUI
import ConfettiSwiftUI

struct FavoriteStar: View {
    @EnvironmentObject var userSettings: UserSettings
    let viewModel: CatalogView.CatalogViewModel
    @State var counter: Int = 0

    var favorited: Bool {
        userSettings.favoriteBoards.contains(viewModel.boardName)
    }

    var body: some View {
        ZStack {
            MultiActionItem(
                icon: Image(systemName: favorited ? "star.fill" : "star")
                    .foregroundColor(Colors.Other.star)
                    .scaleEffect(favorited ? 1.3 : 1),
                iconAnimation: ConfettiCannon(counter: $counter, num: 1, confettis: [.text("⭐️"), .text("⭐️"), .text("⭐️"), .text("⭐️")], confettiSize: 5, rainHeight: 50, radius: 50, repetitions: 3, repetitionInterval: 0.01),
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
                        counter += 1
                        userSettings.favoriteBoards.append(viewModel.boardName)
                    }
                }
            }
        }
    }
}

struct FavoriteStar_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogView.CatalogViewModel(boardName: "fit")
        FavoriteStar(viewModel: viewModel)
    }
}
