//
//  ContentView.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-12.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedVideo: VideoRecord? // State for selected video

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side: Video list
                CommandCenterView(selectedVideo: $selectedVideo) // Pass binding to CommandCenterView
                    .frame(width: geometry.size.width * 0.3) // 30% of the width
                    .background(Color.gray.opacity(0.2))

                // Right side: Media player
                MediaPlayer(video: selectedVideo) // Pass selected video to MediaPlayer
                    .frame(width: geometry.size.width * 0.7) // 70% of the width
                    .background(Color.black)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct CommandCenterView: View {
    @Binding var selectedVideo: VideoRecord?

    var body: some View {
        VStack {
            if let video = selectedVideo {
                Text("Video: \(video.fileURL?.lastPathComponent ?? "Unknown")")
                Text("Size: \(video.fileSize) bytes")
                Text("Resolution: \(video.resolution)")
                Text("Duration: \(video.duration) seconds")
                Text("Frame Rate: \(video.frameRate) fps")
                Text("Codec: \(video.codec)")
            } else {
                Text("No video selected")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
