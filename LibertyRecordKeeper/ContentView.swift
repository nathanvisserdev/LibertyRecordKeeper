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
            ScreenRecordingView()
                .tabItem {
                    Label("Screen Recordings", systemImage: "record.circle")
                }
                .tag(0)
            
            VideoView()
                .tabItem {
                    Label("Videos", systemImage: "video")
                }
                .tag(1)
            
            PhotoView()
                .tabItem {
                    Label("Photos", systemImage: "photo")
                }
                .tag(2)
            
            AudioView()
                .tabItem {
                    Label("Audio", systemImage: "waveform")
                }
                .tag(3)
            
            ScreenshotView()
                .tabItem {
                    Label("Screenshots", systemImage: "camera.viewfinder")
                }
                .tag(4)
            
            AIChatLogsView()
                .tabItem {
                    Label("AI Chat Logs", systemImage: "text.bubble")
                }
                .tag(5)
        }
    }
}

#Preview {
    ContentView()
}
