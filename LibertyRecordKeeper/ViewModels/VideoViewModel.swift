//
//  VideoViewModel.swift
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
class VideoViewModel: ObservableObject {
    @Published var videos: [VideoModel] = []
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var recordingMode: RecordingMode = .video // Default recording mode
    
    private let cameraService = CameraService.shared
    private let databaseService = DatabaseService.shared
    private let cloudKitService = CloudKitService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        cameraService.$isRecording
            .assign(to: &$isRecording)
        
        loadVideos()
    }
    
    func setupCamera() {
        Task {
            do {
                try await cameraService.setupCamera()
            } catch {
                errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            }
        }
    }
    
    func loadVideos() {
        isLoading = true
        Task {
            do {
                let records = try GetAllVideosService.fetchAllVideos(from: "/Users/nathanvisser/Library/Containers/Liberty.LibertyRecordKeeper/Data/Documents/Videos")
                await MainActor.run {
                    self.videos = records
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load videos: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func startRecording() {
        switch recordingMode {
        case .video:
            startVideoRecording()
        case .screen:
            startScreenRecording()
        case .audio:
            startAudioRecording()
        }
    }

    func stopRecording() {
        switch recordingMode {
        case .video:
            stopVideoRecording()
        case .screen:
            stopScreenRecording()
        case .audio:
            stopAudioRecording()
        }
    }
    
    func startVideoRecording() {
        Task {
            let hasPermission = await cameraService.checkAuthorization()
            guard hasPermission else {
                errorMessage = "Camera permissions are required to record video."
                return
            }

            do {
                isRecording = true
                try cameraService.startVideoRecording { [weak self] result in
                    Task { @MainActor in
                        self?.isRecording = false
                        switch result {
                        case .success(var record):
                            // Add custody event
                            record.chainOfCustody.append(CustodyEvent(action: .created))
                            
                            // Save to database
                            do {
                                try self?.databaseService.saveVideo(record)
                                
                                // Upload to CloudKit
                                try await self?.cloudKitService.uploadVideo(record)
                                
                                let videoModel = VideoModel(
                                    id: record.id,
                                    createdAt: record.createdAt,
                                    fileURL: record.fileURL!,
                                    fileSize: record.fileSize,
                                    resolution: record.resolution,
                                    duration: record.duration
                                )
                                self?.videos.insert(videoModel, at: 0)
                            } catch {
                                self?.errorMessage = "Failed to save video: \(error.localizedDescription)"
                            }
                            
                        case .failure(let error):
                            self?.errorMessage = "Failed to record video: \(error.localizedDescription)"
                        }
                    }
                }
            } catch {
                isRecording = false
                errorMessage = "Failed to start video recording: \(error.localizedDescription)"
            }
        }
    }
    
    func stopVideoRecording() {
        cameraService.stopVideoRecording()
        isRecording = false
    }
    
    func startScreenRecording() {
        isRecording = true
        // Implement screen recording logic here
        print("Screen recording started")
    }

    func stopScreenRecording() {
        isRecording = false
        // Implement screen recording stop logic here
        print("Screen recording stopped")
    }

    func startAudioRecording() {
        // Implement audio recording logic
    }

    func stopAudioRecording() {
        // Implement audio recording stop logic
    }
    
    func checkAndRequestPermissions() async -> Bool {
        let hasPermission = await cameraService.checkAuthorization()
        if hasPermission {
            do {
                try await cameraService.setupCamera()
            } catch {
                errorMessage = "Failed to setup camera: \(error.localizedDescription)"
                return false
            }
        }
        return hasPermission
    }
}
