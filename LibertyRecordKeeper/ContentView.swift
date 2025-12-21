//
//  ContentView.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-12.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedVideo: VideoRecord? // State for selected video
    @State private var selectedView: ViewType = .surveillance // Default view
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var securitySettingsViewModel = SecuritySettingsViewModel(twoFactorService: TwoFactorAuthService())
#if os(macOS)
    @State private var showSettings = false
#endif
    var body: some View {
        VStack {
            // Menu for selecting views
            Menu("View > Orientation") {
                Button("Surveillance View") { selectedView = .surveillance }
                Button("Split Screen View") { selectedView = .splitScreen }
                Button("Quadruplex View") { selectedView = .quadruplex }
                Button("Multiplex View") { selectedView = .multiplex }
            }
            .padding()

            // Settings navigation
#if os(macOS)
            Button("Settings") {
                showSettings = true
            }
            .padding(.bottom)
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: settingsViewModel, securitySettingsViewModel: securitySettingsViewModel)
            }
#else
            NavigationLink(destination: SettingsView(viewModel: settingsViewModel, securitySettingsViewModel: securitySettingsViewModel)) {
                Text("Settings")
            }
            .padding(.bottom)
#endif

            // Display the selected view
            GeometryReader { geometry in
                switch selectedView {
                case .surveillance:
                    SurveillanceView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .splitScreen:
                    SplitScreenView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .quadruplex:
                    QuadruplexView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .multiplex:
                    MultiplexView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

enum ViewType {
    case surveillance, splitScreen, quadruplex, multiplex
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
