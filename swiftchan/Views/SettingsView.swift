//
//  SettingsView.swift
//  swiftchan
//
//  Created on 11/7/21.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("fullImageForThumbnails") var fullImageForThumbnails = true
    @AppStorage("showGifThumbnails") var showGifThumbnails = true
    @AppStorage("showGalleryPreview") var showGalleryPreview = false
    @AppStorage("autoRefreshEnabled") var autoRefreshEnabled = false
    @AppStorage("autoRefreshThreadTime") var autoRefreshThreadTime = 10
    @AppStorage("showRefreshProgressBar") var showRefreshProgressBar = false
    @AppStorage("biometricsEnabled") var biometricsEnabled = false
    @AppStorage("showNSFWBoards") var showNSFWBoards = false
    @AppStorage("rememberThreadPositions") var rememberThreadPositions = true
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = true

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
        .toast(isPresented: $showCacheDeleteToast, dismissAfter: 1.5) {
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
                .onChange(of: autoRefreshEnabled) { _, newValue in
                    // Auto-disable progress bar when auto refresh is turned off
                    if !newValue {
                        showRefreshProgressBar = false
                    }
                }
            if autoRefreshEnabled {
                Toggle("Show Refresh Progress Bar", isOn: $showRefreshProgressBar)
            }
            HStack {
                Text("Auto Refresh Time (seconds)")
                Spacer()
                TextField("Auto Refresh Time", value: $autoRefreshThreadTime, formatter: {
                    let formatter = NumberFormatter()
                    formatter.minimum = 5
                    formatter.maximum = 300
                    return formatter
                }())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }
                    .onChange(of: autoRefreshThreadTime) { _, newValue in
                        // Ensure minimum of 5 seconds
                        if newValue < 5 {
                            autoRefreshThreadTime = 5
                        } else if newValue > 300 {
                            autoRefreshThreadTime = 300
                        }
                    }
            }
            if autoRefreshThreadTime < 10 {
                Text("Minimum recommended: 10 seconds")
                    .font(.caption)
                    .foregroundColor(.orange)
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
