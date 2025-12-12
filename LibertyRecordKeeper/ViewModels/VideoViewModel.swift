//
//  VideoViewModel.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import Combine

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [VideoRecord] = []
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isCameraReady = false
    
    private let cameraService = CameraService.shared
    private let databaseService = DatabaseService.shared
    private let cloudKitService = CloudKitService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        cameraService.$isRecording
            .assign(to: &$isRecording)
        
        cameraService.$isCameraAvailable
            .assign(to: &$isCameraReady)
        
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
                let records = try databaseService.fetchAllVideos()
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
    
    func startVideoRecording() {
        do {
            try cameraService.startVideoRecording { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(var record):
                        // Add custody event
                        record.chainOfCustody.append(CustodyEvent(action: .created))
                        
                        // Save to database
                        do {
                            try self?.databaseService.saveVideo(record)
                            
                            // Upload to CloudKit
                            try await self?.cloudKitService.uploadVideo(record)
                            
                            self?.videos.insert(record, at: 0)
                        } catch {
                            self?.errorMessage = "Failed to save video: \(error.localizedDescription)"
                        }
                        
                    case .failure(let error):
                        self?.errorMessage = "Failed to record video: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            errorMessage = "Failed to start video recording: \(error.localizedDescription)"
        }
    }
    
    func stopVideoRecording() {
        cameraService.stopVideoRecording()
    }
}
