//
//  SettingsView.swift
//  swiftchan
//
//  Created on 11/7/21.
//

import SwiftUI
import ToastUI

struct SettingsView: View {
    @AppStorage("fullImageForThumbnails") var fullImageForThumbnails = true
    @AppStorage("showGifThumbnails") var showGifThumbnails = true
    @AppStorage("showGalleryPreview") var showGalleryPreview = false
    @AppStorage("autoRefreshEnabled") var autoRefreshEnabled = true
    @AppStorage("autoRefreshThreadTime") var autoRefreshThreadTime = 10
    @AppStorage("biometricsEnabled") var biometricsEnabled = false
    @AppStorage("showNSFWBoards") var showNSFWBoards = false
    @AppStorage("rememberThreadPositions") var rememberThreadPositions = true
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = false

    @State private var showCacheDeleteToast = false
    @State private var cacheResult: Result<Void, Error>?

    var body: some View {
        List {
            boardSection
            mediaSection
            threadSection
            biometricsSection
            cacheSection
        }
        .navigationTitle("Settings")
        .toast(isPresented: $showCacheDeleteToast, dismissAfter: 0.5) {
            Toast(presentingToastResult: cacheResult)
        }
    }

    var cacheSection: some View {
        Section(header: Text("Cache").font(.title)) {
            Button(role: .destructive, action: {
                CacheManager.shared.deleteAll { result in
                    cacheResult = result
                    showCacheDeleteToast = true
                }
            }) {
                Label("Delete Cache", systemImage: "trash").bold()
            }
        }
    }

    var boardSection: some View {
        Section(header: Text("Board").font(.title)) {
            Toggle("Hide Tab Bar on Boards", isOn: $hideTabOnBoards)
            Toggle("Show NSFW Boards", isOn: $showNSFWBoards)
        }
    }

    var mediaSection: some View {
        Section(header: Text("Media").font(.title)) {
            Toggle("High Res Thumbnails", isOn: $fullImageForThumbnails)
            Toggle("Show Gifs Thumbnails", isOn: $showGifThumbnails)
            Toggle("Tap Gallery to Show Gallery Preview", isOn: $showGalleryPreview)
        }
    }

    var threadSection: some View {
        Section(header: Text("Thread").font(.title)) {
            Toggle("Auto Refresh Enabled", isOn: $autoRefreshEnabled)
            Toggle("Remember Thread Position", isOn: $rememberThreadPositions)
            HStack {
                Text("Auto Refresh Time")
                Spacer()
                TextField("Auto Refresh Time", value: $autoRefreshThreadTime, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
        }
    }

    var biometricsSection: some View {
        Section(header: Text("Biometrics").font(.title)) {
            Toggle("Enabled", isOn: $biometricsEnabled)
        }
    }
}

#if DEBUG
#Preview {
    SettingsView()
}
#endif

