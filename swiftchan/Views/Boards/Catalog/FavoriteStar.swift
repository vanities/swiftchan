//
//  FavoriteStar.swift
//  swiftchan
//
//  Created on 11/23/20.
//

import SwiftUI
import ConfettiSwiftUI

struct FavoriteStar: View {
    @AppStorage("favoriteBoards") var favoriteBoardsDefault: [String] = []
    let viewModel: CatalogViewModel
    @State var counter: Int = 0

    var favorited: Bool {
        favoriteBoardsDefault.contains(viewModel.boardName)
    }

    var body: some View {
        ZStack {
            MultiActionItem(
                icon: Image(systemName: favorited ? "star.fill" : "star")
                    .foregroundColor(Colors.Other.star)
                    .scaleEffect(favorited ? 1.3 : 1),
                iconAnimation: ConfettiCannon(trigger: $counter, num: 1, confettis: [.text("⭐️"), .text("⭐️"), .text("⭐️"), .text("⭐️")], confettiSize: 5, rainHeight: 50, radius: 50, repetitions: 3, repetitionInterval: 0.01),
                text: Text("Favorite")
            ) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                if self.favorited {
                    if let index = favoriteBoardsDefault.firstIndex(of: viewModel.boardName) {
                        withAnimation {
                            _ = favoriteBoardsDefault.remove(at: index)
                        }
                    }
                } else {
                    withAnimation {
                        counter += 1
                        favoriteBoardsDefault.append(viewModel.boardName)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct FavoriteStar_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogViewModel(boardName: "fit")
        FavoriteStar(viewModel: viewModel)
    }
}
#endif
