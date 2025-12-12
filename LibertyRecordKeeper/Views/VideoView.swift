//
//  VideoView.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import SwiftUI
import AVKit

struct VideoView: View {
    @StateObject private var viewModel = VideoViewModel()
    @State private var selectedVideo: VideoRecord?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading videos...")
                } else {
                    List {
                        ForEach(viewModel.videos) { video in
                            VideoRow(video: video)
                                .onTapGesture {
                                    selectedVideo = video
                                }
                        }
                    }
                }
                
                Spacer()
                
                // Camera Controls
                HStack(spacing: 20) {
                    if !viewModel.isCameraReady {
                        Button("Setup Camera") {
                            viewModel.setupCamera()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else if viewModel.isRecording {
                        Button(action: {
                            viewModel.stopVideoRecording()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop Recording")
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            viewModel.startVideoRecording()
                        }) {
                            HStack {
                                Image(systemName: "video.circle")
                                Text("Record Video")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Videos")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedVideo) { video in
                if let url = video.fileURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .navigationTitle("Video")
                }
            }
        }
    }
}

struct VideoRow: View {
    let video: VideoRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.green)
                Text(formatDate(video.createdAt))
                    .font(.headline)
                Spacer()
                Text(formatDuration(video.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Resolution: \(video.resolution)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Codec: \(video.codec)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Size: \(formatFileSize(video.fileSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
