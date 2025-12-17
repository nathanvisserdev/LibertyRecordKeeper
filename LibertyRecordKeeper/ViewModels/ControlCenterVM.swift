//
//  ControlCenterVM.swift
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
class ControlCenterVM: ObservableObject {
    @Published var mediaRecords: [MediaRecord] = []
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var recordingMode: RecordingMode = .video // Default recording mode

    private let controlCenterModel: ControlCenterModel

    init(controlCenterModel: ControlCenterModel) {
        self.controlCenterModel = controlCenterModel
        loadMedia()
    }

    func loadMedia() {
        isLoading = true
        Task {
            do {
                let records = try await controlCenterModel.fetchMedia()
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
            controlCenterModel.startVideoRecording()
        case .screen:
            controlCenterModel.startScreenRecording()
        case .audio:
            controlCenterModel.startAudioRecording()
        }
        isRecording = true
    }

    func stopRecording() {
        switch recordingMode {
        case .video:
            controlCenterModel.stopVideoRecording()
        case .screen:
            controlCenterModel.stopScreenRecording()
        case .audio:
            controlCenterModel.stopAudioRecording()
        }
        isRecording = false
    }

    func checkAndRequestPermissions() async -> Bool {
        return await controlCenterModel.checkPermissions()
    }
}
