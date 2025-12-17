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
                    List(viewModel.videos) { video in
                        VStack(alignment: .leading) {
                            Text(video.fileURL.lastPathComponent)
                                .font(.headline)
                            Text("Size: \(video.fileSize) bytes")
                                .font(.subheadline)
                            Text("Created: \(video.createdAt)")
                                .font(.subheadline)
                        }
                    }
                }
                
                Spacer()
                
                // Camera Controls
                HStack(spacing: 20) {
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopVideoRecording()
                        } else {
                            Task {
                                let hasPermission = await viewModel.checkAndRequestPermissions()
                                if !hasPermission {
                                    viewModel.errorMessage = "Camera permissions are required to use this feature."
                                    return
                                }
                                viewModel.startVideoRecording()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "video.circle")
                            Text(viewModel.isRecording ? "Stop Recording" : "Record Video")
                        }
                        .foregroundColor(viewModel.isRecording ? .red : .white)
                        .padding()
                        .background(viewModel.isRecording ? Color.red.opacity(0.2) : Color.blue)
                        .cornerRadius(10)
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
