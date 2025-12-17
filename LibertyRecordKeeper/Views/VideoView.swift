//
//  CommandCenterView.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import SwiftUI
import AVKit

struct CommandCenterView: View {
    @StateObject private var viewModel: CommandCenterViewModel
    @Binding var selectedMedia: MediaRecord? // Binding for selected media

    init(commandCenterModel: CommandCenterModel, selectedMedia: Binding<MediaRecord?>) {
        _viewModel = StateObject(wrappedValue: CommandCenterViewModel(commandCenterModel: commandCenterModel))
        _selectedMedia = selectedMedia
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading media...")
                } else {
                    List(viewModel.mediaRecords) { media in
                        VStack(alignment: .leading) {
                            Text(media.fileURL.lastPathComponent)
                                .font(.headline)
                            Text("Size: \(media.fileSize) bytes")
                                .font(.subheadline)
                            Text("Created: \(media.createdAt)")
                                .font(.subheadline)
                        }
                        .onTapGesture {
                            selectedMedia = media
                        }
                    }
                }

                Spacer()

                // Command Controls
                VStack(spacing: 10) {
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            Task {
                                let hasPermission = await viewModel.checkAndRequestPermissions()
                                if !hasPermission {
                                    viewModel.errorMessage = "Permissions are required to use this feature."
                                    return
                                }
                                viewModel.startRecording()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                            Text(viewModel.isRecording ? "Stop Recording" : "Record \(viewModel.recordingMode.rawValue)")
                        }
                        .foregroundColor(viewModel.isRecording ? .red : .white)
                        .padding()
                        .background(viewModel.isRecording ? Color.red.opacity(0.2) : Color.blue)
                        .cornerRadius(10)
                    }

                    Menu {
                        Button("Record Video") {
                            viewModel.recordingMode = .video
                        }
                        Button("Record Screen") {
                            viewModel.recordingMode = .screen
                        }
                        Button("Record Audio") {
                            viewModel.recordingMode = .audio
                        }
                    } label: {
                        Text("Select Recording Mode")
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Command Center")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct MediaRow: View {
    let media: MediaRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.green)
                Text(formatDate(media.createdAt))
                    .font(.headline)
                Spacer()
                Text(formatDuration(media.duration ?? 0))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Resolution: \(media.resolution)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Codec: \(media.codec)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Size: \(formatFileSize(media.fileSize))")
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
