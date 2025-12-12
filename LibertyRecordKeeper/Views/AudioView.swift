//
//  AudioView.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import SwiftUI
import AVKit

struct AudioView: View {
    @StateObject private var viewModel = AudioViewModel()
    @State private var selectedAudio: AudioRecord?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading audio recordings...")
                } else {
                    List {
                        ForEach(viewModel.recordings) { recording in
                            AudioRow(recording: recording)
                                .onTapGesture {
                                    selectedAudio = recording
                                }
                        }
                    }
                }
                
                Spacer()
                
                // Recording indicator
                if viewModel.isRecording {
                    VStack {
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(formatDuration(viewModel.recordingDuration))
                            .font(.title)
                            .monospacedDigit()
                        
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .animation(.easeInOut(duration: 1).repeatForever(), value: viewModel.isRecording)
                            
                            Text("REC")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
                
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
                                Image(systemName: "mic.circle")
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
            .navigationTitle("Audio Recordings")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedAudio) { audio in
                if let url = audio.fileURL {
                    AudioPlayerView(url: url, audio: audio)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AudioRow: View {
    let recording: AudioRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.purple)
                Text(formatDate(recording.createdAt))
                    .font(.headline)
                Spacer()
                Text(formatDuration(recording.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Format: \(recording.format)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Sample Rate: \(Int(recording.sampleRate)) Hz")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Size: \(formatFileSize(recording.fileSize))")
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

struct AudioPlayerView: View {
    let url: URL
    let audio: AudioRecord
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Recording")
                .font(.title)
            
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 150, height: 150)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Recorded: \(formatDate(audio.createdAt))")
                Text("Duration: \(formatDuration(audio.duration))")
                Text("Format: \(audio.format)")
                Text("Sample Rate: \(Int(audio.sampleRate)) Hz")
                Text("Size: \(formatFileSize(audio.fileSize))")
            }
            .padding()
            
            HStack(spacing: 30) {
                Button(action: {
                    if isPlaying {
                        player?.pause()
                    } else {
                        player?.play()
                    }
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    player?.seek(to: .zero)
                    isPlaying = false
                }) {
                    Image(systemName: "stop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .onAppear {
            player = AVPlayer(url: url)
        }
        .onDisappear {
            player?.pause()
        }
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
