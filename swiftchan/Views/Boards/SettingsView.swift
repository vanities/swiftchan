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
    @Default(.fullImagesForThumbanails) var fullImageForThumbnails
    @Default(.showGifThumbnails) var showGifThumbnails
    @Default(.showGalleryPreview) var showGalleryPreview
    @Default(.showOPPreview) var showOPPreview
    @Default(.autoRefreshEnabled) var autoRefreshEnabled
    @Default(.autoRefreshThreadTime) var autoRefreshThreadTime
    @Default(.biometricsEnabled) var biometricsEnabled
    @Default(.showNSFWBoards) var showNSFWBoards

    @EnvironmentObject private var appContext: AppContext
    @State var showCacheDeleteToast = false
    @State private var cacheResult: Result<Void, Error>?

    var body: some View {
        return ScrollView(.vertical) {
            HStack {
                VStack(alignment: .leading) {
                    cache
                        .padding()
                    board
                        .padding()
                    media
                        .padding()
                    thread
                        .padding()
                    biometrics
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

    var board: some View {
        let header = "Board"
        return Section(content: {
            Toggle("Show NSFW Boards", isOn: $showNSFWBoards)
        }, header: {
            Text(header).font(.title)
        })
    }

    var media: some View {
        let header = "Media"
        return Section(content: {
            Toggle("High Res Thumbnails", isOn: $fullImageForThumbnails)
            Toggle("Show Gifs Thumbnails", isOn: $showGifThumbnails)
            Toggle("Tap Gallery to show Gallery Preview", isOn: $showGalleryPreview)
            Toggle("Tap OP thumnail to show Fullscreen Preview", isOn: $showOPPreview)
        }, header: {
            Text(header).font(.title)
        })
    }

    var thread: some View {
        let header = "Thread"
        return Section(content: {
            Toggle("Auto Refresh Enabled", isOn: $autoRefreshEnabled)
            HStack {
                Text("Auto Refresh Time")
                Spacer()
                TextField("Auto Refresh Time", value: $autoRefreshThreadTime, formatter: NumberFormatter())
                .frame(width: 50)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
            }
        }, header: {
            Text(header).font(.title)
        })
    }

    var biometrics: some View {
        let header = "Biometrics"
        return Section(content: {
            Toggle("enabled", isOn: $biometricsEnabled)
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
