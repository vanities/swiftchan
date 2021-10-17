//
//  SortRow.swift
//  swiftchan
//
//  Created by vanities on 10/15/21.
//

import SwiftUI
import Defaults

struct RepliesSort: View {
    enum SortImageName: String {
        case enabled = "arrowshape.turn.up.left.fill"
        case disabled = "arrowshape.turn.up.left"
    }

    let viewModel: CatalogView.CatalogViewModel
    @State var sortState: SortRow.SortType
    @State var imageName: SortImageName

    init(viewModel: CatalogView.CatalogViewModel) {
        self.viewModel = viewModel
        self.sortState = Defaults.sortFilesBoard(boardName: viewModel.boardName)
        self.imageName = Defaults.sortFilesBoard(boardName: viewModel.boardName) == .none ? .disabled : .enabled
    }

    var body: some View {

        SortRow(
            imageName: imageName.rawValue,
            text: "Replies",
            sortState: $sortState
        )
            .environmentObject(viewModel)
            .onChange(of: sortState) { value in
                imageName = value == .none ? .disabled : .enabled
            }
    }
}

struct SortRow: View {
    let imageName: String
    let text: String
    @Binding var sortState: SortType
    @EnvironmentObject var viewModel: CatalogView.CatalogViewModel

    enum SortType: String, Equatable, CaseIterable, Defaults.Serializable {
        case descending
        case ascending
        case none
    }

    @ViewBuilder
    var body: some View {
        ZStack {
            MultiActionItem(
                icon: Image(systemName: imageName)
                    .foregroundColor(Colors.Other.star)
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
                text: Text(text)
            ) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                Defaults[.sortFilesBoard(boardName: viewModel.boardName)].next()

                withAnimation(.linear) {
                    sortState.next()
                }
            }

        }
    }
}

struct SortRow_Previews: PreviewProvider {
    static var previews: some View {
        let boardName = "fit"
        let viewModel = CatalogView.CatalogViewModel(boardName: boardName)
        Group {
            RepliesSort(viewModel: viewModel)
                .onAppear {
                    Defaults[Defaults.Key<SortRow.SortType>(
                        "sortFilesBoard\(boardName)",
                        default: .none
                    )] = .none
                }

            RepliesSort(viewModel: viewModel)
                .onAppear {
                    Defaults[Defaults.Key<SortRow.SortType>(
                        "sortFilesBoard\(boardName)",
                        default: .none
                    )] = .ascending
                }

            RepliesSort(viewModel: viewModel)
                .onAppear {
                    Defaults[Defaults.Key<SortRow.SortType>(
                        "sortFilesBoard\(boardName)",
                        default: .none
                    )] = .descending
                }
        }
    }
}
