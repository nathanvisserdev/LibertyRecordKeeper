//
//  CommandCenterViewModel.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import Combine

enum RecordingMode: String {
    case video = "Video"
    case screen = "Screen"
    case audio = "Audio"
}

@MainActor
class CommandCenterViewModel: ObservableObject {
    @Published var mediaRecords: [MediaRecord] = []
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var recordingMode: RecordingMode = .video // Default recording mode

    private let commandCenterModel: CommandCenterModel

    init(commandCenterModel: CommandCenterModel) {
        self.commandCenterModel = commandCenterModel
        loadMedia()
    }

    func loadMedia() {
        isLoading = true
        Task {
            do {
                let records = try await commandCenterModel.fetchMedia()
                await MainActor.run {
                    self.mediaRecords = records
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load media: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func startRecording() {
        switch recordingMode {
        case .video:
            commandCenterModel.startVideoRecording()
        case .screen:
            commandCenterModel.startScreenRecording()
        case .audio:
            commandCenterModel.startAudioRecording()
        }
        isRecording = true
    }

    func stopRecording() {
        switch recordingMode {
        case .video:
            commandCenterModel.stopVideoRecording()
        case .screen:
            commandCenterModel.stopScreenRecording()
        case .audio:
            commandCenterModel.stopAudioRecording()
        }
        isRecording = false
    }

    func checkAndRequestPermissions() async -> Bool {
        return await commandCenterModel.checkPermissions()
    }
}
