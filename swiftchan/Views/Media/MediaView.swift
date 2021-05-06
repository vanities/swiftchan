//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI

struct MediaView: View {
    @State var isSelected: Bool
    @Binding var selected: Int
    let url: URL
    let id: Int

    var onMediaChanged: ((Bool) -> Void)?

    init(selected: Binding<Int>, url: URL, id: Int) {
        self._selected = selected
        self.url = url
        self.id = id

        self._isSelected = State(initialValue: selected.wrappedValue == id)
    }

    @ViewBuilder
    var body: some View {
        switch MediaDetector.detect(url: url) {
        case .image:
            ImageView(url: self.url, canGesture: true, isSelected: self.$isSelected)
                .onZoomChanged { zoomed in
                    self.onMediaChanged?(zoomed)
                }
                .onChange(of: self.selected) { value in
                    self.isSelected = value == self.id
                }
        case .webm:
            VLCContainerView(url: self.url,
                             play: self.$isSelected
            )
            .onSeekChanged { seeking in
                self.onMediaChanged?(seeking)
            }
            .onChange(of: self.selected) { value in
                self.isSelected = value == self.id
            }
        case .gif:
            ImageView(url: self.url, canGesture: true, isSelected: self.$isSelected)
        case .none:
            EmptyView()
        }
    }
}

extension MediaView: Buildable {
    func onMediaChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onMediaChanged, value: callback)
    }
}

struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MediaView(
                selected: .constant(0),
                url: URLExamples.image,
                id: 0
            )
            MediaView(
                selected: .constant(0),
                url: URLExamples.gif,
                id: 0
            )
            MediaView(
                selected: .constant(0),
                url: URLExamples.webm,
                id: 0
            )
        }
    }
}
