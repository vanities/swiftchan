//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI

import MobileVLCKit

struct VLCPlayerControlsView : View {
    @Binding private(set) var player: VLCMediaPlayer
    @Binding private(set) var state: VLCMediaPlayerState
    @Binding private(set) var videoPos: VLCTime
    @Binding private(set) var remainingTime: VLCTime
    @Binding private(set) var seeking: Bool
    
    @State private var playerPaused = true
    
    var body: some View {
        return HStack {
            // Play/pause button
            Button(action: togglePlayPause) {
                Image(systemName: self.state == .paused ? "play" : "pause")
                    .padding(.trailing, 10)
            }
            // Current video time
            Text(videoPos.description)
            // Slider for seeking / showing video progress
           // Slider(value: $videoPos, in: 0...1, onEditingChanged: sliderEditingChanged)
            // Video duration
            Text(remainingTime.description)
        }
        .padding(.leading, 10)
        .padding(.trailing, 10)
    }
    
    private func togglePlayPause() {
        pausePlayer(!playerPaused)
    }
    
    private func pausePlayer(_ pause: Bool) {
        print(self.state.rawValue)
        playerPaused = pause
        if self.state == .playing {
            self.player.stop()
        }
        else {
            self.player.play()
        }
    }

    /*
    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            // Set a flag stating that we're seeking so the slider doesn't
            // get updated by the periodic time observer on the player
            seeking = true
            pausePlayer(true)
        }
        
        // Do the seek if we're finished
        if !editingStarted {
            let targetTime = CMTime(seconds: videoPos * videoDuration,
                                    preferredTimescale: 600)
            player.seek(to: targetTime) { _ in
                // Now the seek is finished, resume normal operation
                self.seeking = false
                self.pausePlayer(false)
            }
        }
    }
 */
}
