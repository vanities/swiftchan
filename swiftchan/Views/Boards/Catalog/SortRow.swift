//
//  SortRow.swift
//  swiftchan
//
//  Created by vanities on 10/15/21.
//

import SwiftUI

struct RepliesSortRow: View {
    let viewModel: CatalogViewModel

    var body: some View {
        SortRow(
            viewModel: viewModel,
            enabledImageName: "arrowshape.turn.up.left.fill",
            disabledImageName: "arrowshape.turn.up.left",
            text: "Replies",
            defaultsKeyType: "sortRepliesBy"
        )
    }
}

struct FilesSortRow: View {
    let viewModel: CatalogViewModel

    var body: some View {
        SortRow(
            viewModel: viewModel,
            enabledImageName: "photo.fill",
            disabledImageName: "photo",
            text: "Files",
            defaultsKeyType: "sortFilesBy"
        )
    }
}

struct SortRow: View {
    let viewModel: CatalogViewModel
    let enabledImageName: String
    let disabledImageName: String
    let text: String
    let defaultsKeyType: String

    @State var imageName: String
    @State var sortState: SortType

    enum SortType: String, Equatable, CaseIterable, Codable {
        case descending
        case ascending
        case none

        func nextState() -> Self {
            // Get all cases in the enum
            let allCases = Self.allCases
            // Find the current index
            if let currentIndex = allCases.firstIndex(of: self) {
                // Calculate the next index (wrap around using modulo)
                let nextIndex = (currentIndex + 1) % allCases.count
                // Return the next state
                return allCases[nextIndex]
            }
            // Return the current state if something goes wrong (though it shouldn't)
            return self
        }
    }

    init(viewModel: CatalogViewModel,
         enabledImageName: String,
         disabledImageName: String,
         text: String,
         defaultsKeyType: String
    ) {
        self.viewModel = viewModel
        self.enabledImageName = enabledImageName
        self.disabledImageName = disabledImageName
        self.text = text
        self.defaultsKeyType = defaultsKeyType

        switch defaultsKeyType {
        case "sortRepliesBy":
            let type = UserDefaults.getSortRepliesBy(boardName: viewModel.boardName)
            self.imageName = type == .none ? disabledImageName : enabledImageName
            self.sortState = type
            break
        case "sortFilesBy":
            let type = UserDefaults.getSortFilesBy(boardName: viewModel.boardName)
            self.imageName = type == .none ? disabledImageName : enabledImageName
            self.sortState = type
            break
        default:
            self.imageName = "none"
            self.sortState = .none
            break
        }
    }

    @ViewBuilder
    var body: some View {
        ZStack {
            MultiActionItem(
                icon: Image(systemName: imageName)
                    .foregroundColor(Color.primary)
                    .scaleEffect(sortState == .none ? 1.5 : 1)
                    .offset(y: sortState == .none ? 0 : 10)
                ,

                iconAnimation:
                    Image(systemName: "arrowtriangle.up.fill")
                    .foregroundColor(sortState == .ascending ? .green : .red)
                    .rotationEffect(Angle(degrees: sortState == .ascending ? 0 : 180))
                    .opacity(sortState == .none ? 0 : 1)
                    .scaleEffect(sortState == .none ? 0 : 1)
                    .offset(y: -10),
                text: Text("Sort by \(text)")
            ) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

                switch defaultsKeyType {
                case "sortRepliesBy":
                    UserDefaults.setSortRepliesBy(boardName: viewModel.boardName, type: UserDefaults.getSortRepliesBy(boardName: viewModel.boardName).nextState())
                    break
                case "sortFilesBy":
                    UserDefaults.setSortFilesBy(boardName: viewModel.boardName, type: UserDefaults.getSortFilesBy(boardName: viewModel.boardName).nextState())
                    break
                default:
                    break
                }

                withAnimation(.linear) {
                    sortState.next()
                }
            }
        }
        .onChange(of: sortState) {
            imageName = sortState == .none ? disabledImageName : enabledImageName
        }
        .onAppear {
            print(UserDefaults.getSortRepliesBy(boardName: viewModel.boardName))
        }
    }
}

#if DEBUG
#Preview {
    let boardName = "fit"
    let viewModel = CatalogViewModel(boardName: boardName)
    Group {
        RepliesSortRow(viewModel: viewModel)
            .background(Color.white)
    }
}
#endif
