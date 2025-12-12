//
//  ScreenRecordingView.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import SwiftUI
import AVKit

struct ScreenRecordingView: View {
    @StateObject private var viewModel = ScreenRecordingViewModel()
    @State private var selectedRecording: ScreenRecordingRecord?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading recordings...")
                } else {
                    List {
                        ForEach(viewModel.recordings) { recording in
                            RecordingRow(recording: recording)
                                .onTapGesture {
                                    selectedRecording = recording
                                    viewModel.viewRecording(recording)
                                }
                        }
                    }
                }
                
                Spacer()
                
                // Recording Controls
                HStack(spacing: 20) {
                    if viewModel.isRecording {
                        Button(action: {
                            viewModel.stopRecording()
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
                            viewModel.startRecording()
                        }) {
                            HStack {
                                Image(systemName: "record.circle")
                                Text("Start Recording")
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
            .navigationTitle("Screen Recordings")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedRecording) { recording in
                if let url = recording.fileURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .navigationTitle("Screen Recording")
                }
            }
        }
    }
}

struct RecordingRow: View {
    let recording: ScreenRecordingRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.blue)
                Text(formatDate(recording.createdAt))
                    .font(.headline)
                Spacer()
                Text(formatDuration(recording.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Resolution: \(recording.resolution)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Size: \(formatFileSize(recording.fileSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Checksum: \(String(recording.checksumSHA256.prefix(16)))...")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
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
