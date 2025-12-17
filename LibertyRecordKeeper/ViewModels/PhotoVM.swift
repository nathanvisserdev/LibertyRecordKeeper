//
//  PhotoViewModel.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import Combine

@MainActor
class PhotoViewModel: ObservableObject {
    @Published var photos: [PhotoRecord] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isCameraReady = false
    
    private let cameraService = CameraService.shared
    private let databaseService = DatabaseService.shared
    private let cloudKitService = CloudKitService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        cameraService.$isCameraAvailable
            .assign(to: &$isCameraReady)
        
        loadPhotos()
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
    
    func loadPhotos() {
        isLoading = true
        Task {
            do {
                let records = try databaseService.fetchAllPhotos()
                await MainActor.run {
                    self.photos = records
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load photos: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func capturePhoto() {
        do {
            try cameraService.capturePhoto { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(var record):
                        // Add custody event
                        record.chainOfCustody.append(CustodyEvent(action: .created))
                        
                        // Save to database
                        do {
                            try self?.databaseService.savePhoto(record)
                            
                            // Upload to CloudKit
                            try await self?.cloudKitService.uploadPhoto(record)
                            
                            self?.photos.insert(record, at: 0)
                        } catch {
                            self?.errorMessage = "Failed to save photo: \(error.localizedDescription)"
                        }
                        
                    case .failure(let error):
                        self?.errorMessage = "Failed to capture photo: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            errorMessage = "Failed to start photo capture: \(error.localizedDescription)"
        }
    }
}
