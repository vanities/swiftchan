//
//  SettingsView.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/7/21.
//

import SwiftUI
import ToastUI
import Defaults

struct SettingsView: View {
    @State var showCacheDeleteToast = false
    @State private var cacheResult: Result<Void, Error>?
    @Default(.fullImagesForThumbanails) var fullImageForThumbnails
    @Default(.showGifThumbnails) var showGifThumbnails

    var body: some View {
        return ScrollView(.vertical) {
            HStack {
                VStack(alignment: .leading) {
                    cache
                        .padding()
                    media
                        .padding()
                }
                Spacer()
            }
        }
        .navigationTitle(Text("Settings"))
        .toast(isPresented: $showCacheDeleteToast,
               dismissAfter: 0.5,
               content: {
            Toast(presentingToastResult: cacheResult)
        })
    }

    var cache: some View {
        let header = "Cache"
        return Section(content: {
            Button(
                role: .destructive,
                action: {
                    CacheManager.shared.deleteAll { result in
                        cacheResult = result
                        showCacheDeleteToast = true
                    }
                },
                label: {
                    Label("Delete Cache", systemImage: "trash")
                }
            )
        }, header: {
            Text(header).font(.title)
        })
    }

    var media: some View {
        let header = "Media"
        return Section(content: {
            Toggle("High Res Thumbnails", isOn: $fullImageForThumbnails)
            Toggle("Show Gifs Thumnails", isOn: $showGifThumbnails)
        }, header: {
            Text(header).font(.title)
        })
    }
}

#if DEBUG
    struct SettingsView_Previews: PreviewProvider {
        static var previews: some View {
            return SettingsView()
        }
    }
#endif
