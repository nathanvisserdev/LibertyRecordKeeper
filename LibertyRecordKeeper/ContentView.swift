//
//  ContentView.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-12.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedVideo: VideoRecord? // State for selected video
    @State private var leftPanelWidth: CGFloat = 300 // Initial width for the left panel

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side: Video list
                VideoView(selectedVideo: $selectedVideo) // Pass binding to VideoView
                    .frame(width: leftPanelWidth)
                    .background(Color.gray.opacity(0.2))
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                let newWidth = leftPanelWidth + value.translation.width
                                if newWidth > 150 && newWidth < geometry.size.width * 0.7 {
                                    leftPanelWidth = newWidth
                                }
                            }
                    )

                // Right side: Media player
                MediaPlayer(video: selectedVideo) // Pass selected video to MediaPlayer
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct VideoView: View {
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
