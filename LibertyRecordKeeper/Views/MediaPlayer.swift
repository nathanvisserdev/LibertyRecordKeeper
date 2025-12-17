//
//  MediaPlayer.swift
//  LibertyRecordKeeper
//
//  Created on 12/17/2025.
//

import SwiftUI
import AVKit

struct MediaPlayer: View {
    var video: VideoRecord? // Optional video to play

    var body: some View {
        ZStack {
            Color.gray // Background color to indicate the area
                .edgesIgnoringSafeArea(.all)

            if let video = video, let url = video.fileURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Select a video to play")
                    .foregroundColor(.white)
                    .font(.title)
            }
        }
    }
}