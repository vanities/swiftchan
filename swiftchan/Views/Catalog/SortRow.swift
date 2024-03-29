//
//  SortRow.swift
//  swiftchan
//
//  Created by vanities on 10/15/21.
//

import SwiftUI
import Defaults

struct RepliesSortRow: View {
    let viewModel: CatalogViewModel

    var body: some View {
        SortRow(
            viewModel: viewModel,
            enabledImageName: "arrowshape.turn.up.left.fill",
            disabledImageName: "arrowshape.turn.up.left",
            text: "Replies",
            defaultsKeyType: Defaults.Keys.sortRepliesBy
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
            defaultsKeyType: Defaults.Keys.sortFilesBy
        )
    }
}

struct SortRow: View {
    let viewModel: CatalogViewModel
    let enabledImageName: String
    let disabledImageName: String
    let text: String
    let defaultsKeyType: ((String) -> Defaults.Key<SortRow.SortType>)

    @State var imageName: String
    @State var sortState: SortType

    enum SortType: String, Equatable, CaseIterable, Defaults.Serializable {
        case descending
        case ascending
        case none
    }

    init(viewModel: CatalogViewModel,
         enabledImageName: String,
         disabledImageName: String,
         text: String,
         defaultsKeyType: @escaping ((String) -> Defaults.Key<SortRow.SortType>)
    ) {
        self.viewModel = viewModel
        self.enabledImageName = enabledImageName
        self.disabledImageName = disabledImageName
        self.text = text
        self.defaultsKeyType = defaultsKeyType

        self.imageName = Defaults[defaultsKeyType(viewModel.boardName)] == .none ? disabledImageName : enabledImageName
        self.sortState = Defaults[defaultsKeyType(viewModel.boardName)]
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
                Defaults[defaultsKeyType(viewModel
                                            .boardName)].next()

                withAnimation(.linear) {
                    sortState.next()
                }
            }
        }
        .onChange(of: sortState) {
            imageName = sortState == .none ? disabledImageName : enabledImageName
        }
    }
}

#if DEBUG
struct SortRow_Previews: PreviewProvider {
    static var previews: some View {
        let boardName = "fit"
        let viewModel = CatalogViewModel(boardName: boardName)
        Group {
            RepliesSortRow(viewModel: viewModel)
                .background(Color.white)
        }
    }
}
#endif
