//
//  GalleryPreviewView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI

struct GalleryPreviewView: View {
    let mediaUrls: [URL] = []
    
    var body: some View {
        return ScrollView(.horizontal,
                          showsIndicators: false) {
            VStack(alignment: .center,
                   spacing: nil) {
                // horizontal, scrollable, media preview with
                // a callback to scroll tabview
            }
        }
    }
}

struct GalleryPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryPreviewView()
    }
}
