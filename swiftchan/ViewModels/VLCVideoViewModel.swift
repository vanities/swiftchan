//
//  VLCVideoViewModel.swift
//  swiftchan
//
//  Created by vanities on 2/1/21.
//
import SwiftUI
import MobileVLCKit

class VLCVideoViewModel: ObservableObject {
    @Published var vlcVideo: VLCVideo = VLCVideo()
}
