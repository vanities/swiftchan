//
//  GalleryView.swift
//  swiftchan
//
//  Created by vanities on 11/5/20.
//

import SwiftUI
import Introspect

struct GalleryView: View, Buildable {
    @Binding var selection: Int
    var urls: [URL]
    var thumbnailUrls: [URL]

    @State var canShowPreview: Bool = true
    @State var showPreview: Bool = true

    func onMediaChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onMediaChanged, value: callback)
    }
    var onMediaChanged: ((Bool) -> Void)?

    var body: some View {
        let showPreviewTap = TapGesture(count: 1)
            .onEnded {
                withAnimation(.linear(duration: 0.2)) {
                    self.showPreview.toggle()
                }
            }

        return ZStack {
            // media
            TabView(selection: self.$selection) {
                ForEach(self.urls.indices, id: \.self) { index in
                    let url = self.urls[index]
                    MediaView(url: url,
                              selected: self.selection == index)
                        .onMediaChanged { change in
                            self.canShowPreview = !change
                            self.showPreview = !change
                            self.onMediaChanged?(change)
                        }
                        .tag(index)
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle())
            .introspectTabBarScrollView { v in
                v.isScrollEnabled = false
            }

            // preview
            if self.showPreview {
                VStack {
                    Spacer()
                    GalleryPreviewView(urls: self.thumbnailUrls,
                                       selection: self.$selection)
                        .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
        }
        .gesture(self.canShowPreview ? showPreviewTap : nil)
    }

}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryView(selection: .constant(0),
                        urls: URLExamples.imageSet,
                        thumbnailUrls: URLExamples.imageSet
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.webmSet,
                        thumbnailUrls: URLExamples.webmSet
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.gifSet,
                        thumbnailUrls: URLExamples.gifSet
            )
        }
    }
}
