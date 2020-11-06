//
//  GalleryView.swift
//  swiftchan
//
//  Created by vanities on 11/5/20.
//

import SwiftUI
import URLImage
import Introspect

struct GalleryView: View {
    @State var selection: Int = 0
    var imageUrls: [URL]

    @State var scale: CGFloat = 1.0
    @State var offset = CGSize.zero

    var body: some View {
        return ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            TabView(selection: self.$selection) {
                ForEach(self.imageUrls.indices, id: \.self) { index in
                    URLImage(url: self.imageUrls[index]) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                    }
                    .tag(index)
                    .scaleEffect(self.scale)
                    .offset(self.offset)
                    .gesture(MagnificationGesture()
                                .onChanged({ (value) in
                                    self.scale = value
                                })
                                .onEnded({ (value) in
                                    self.scale = value
                                })

                    )
                    .simultaneousGesture(DragGesture()
                                .onChanged({ (value) in
                                    self.offset = value.translation
                                })
                                .onEnded({ (value) in
                                    self.offset = value.translation
                                })
                    )
                    .onTapGesture(count: 1, perform: {
                        self.scale = 1
                        self.offset = CGSize(width: 0, height: 0)
                    })
                }
            }
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .tabViewStyle(PageTabViewStyle())
            .onChange(of: self.selection) { _ in
                self.scale = 1
                self.offset = CGSize(width: 0, height: 0)
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView(imageUrls: Array.init(
                        repeating: URL(string: "https://picsum.photos/1020/900")!,
                        count: 5)
        )
    }
}
