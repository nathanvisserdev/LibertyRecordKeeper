//
//  ContentView.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-12.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VideoView()
                .tabItem {
                    Label("Videos", systemImage: "video")
                }
                .tag(1)

            AudioView()
                .tabItem {
                    Label("Audio", systemImage: "waveform")
                }
                .tag(3)

            ScreenRecordingView()
                .tabItem {
                    Label("Screen Recordings", systemImage: "record.circle")
                }
                .tag(0)

            PhotoView()
                .tabItem {
                    Label("Photos", systemImage: "photo")
                }
                .tag(2)

            ScreenshotView()
                .tabItem {
                    Label("Screenshots", systemImage: "camera")
                }
                .tag(4)
        }
        .background(Color.black) // Set background color to black
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full space is taken up
    }
}

#Preview {
    ContentView()
}
