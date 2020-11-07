//
//  ImageView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import URLImage

struct ImageView: View {
    let index: Int
    let url: URL
    let isSelected: Bool
    
    @State var scale: CGFloat = 1.0
    @State var offset = CGSize.zero
    @State var canDrag: Bool = false
    
    var body: some View {
        return URLImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
            
        }
        .tag(self.index)
        .scaleEffect(self.scale)
        .offset(self.offset)
        .gesture(MagnificationGesture()
                    .onChanged({ (value) in
                        self.scale = value
                    })
                    .onEnded({ (value) in
                        self.scale = value
                        if self.scale != 1 {
                            self.canDrag = true
                        }
                    })
        )
        // allow drag, only if zoomed in or out
        .simultaneousGesture(self.canDrag ? DragGesture()
                                .onChanged({ (value) in
                                    self.offset = value.translation
                                })
                                .onEnded({ (value) in
                                    self.offset = value.translation
                                }) : nil
        )
        .onTapGesture(count: 2, perform: {
            // zoom in
            if self.scale == 1 {
                withAnimation(.easeIn(duration: 0.2)) {
                    self.scale = 2
                }
            }
            // zoom back
            else {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.scale = 1
                    self.offset = CGSize(width: 0, height: 0)
                    self.canDrag = false
                }
            }
        })
        .onChange(of: self.isSelected) { selected in
            if !selected {
                self.scale = 1
                self.offset = CGSize(width: 0, height: 0)
            }
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView(
            index: 0,
            url:
                URL(string: "https://picsum.photos/1020/900")!,
            isSelected: true)
    }
}
