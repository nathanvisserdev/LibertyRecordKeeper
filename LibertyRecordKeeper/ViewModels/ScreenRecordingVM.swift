//
//  ScreenRecordingViewModel.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import Combine

@MainActor
class ScreenRecordingViewModel: ObservableObject {
    @Published var recordings: [ScreenRecordingRecord] = []
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let screenRecordingService = ScreenRecordingService.shared
    private let databaseService = DatabaseService.shared
    private let cloudKitService = CloudKitService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        screenRecordingService.$isRecording
            .assign(to: &$isRecording)
        
        loadRecordings()
    }
    
    func loadRecordings() {
        isLoading = true
        Task {
            do {
                let records = try databaseService.fetchAllScreenRecordings()
                await MainActor.run {
                    self.recordings = records
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load recordings: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func startRecording() {
        Task {
            do {
                try await screenRecordingService.startRecording()
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }
    
    func stopRecording() {
        Task {
            do {
                var record = try await screenRecordingService.stopRecording()
                
                // Add custody event
                record.chainOfCustody.append(CustodyEvent(action: .created))
                
                // Save to database
                try databaseService.saveScreenRecording(record)
                
                // Upload to CloudKit
                try await cloudKitService.uploadScreenRecording(record)
                
                await MainActor.run {
                    self.recordings.insert(record, at: 0)
                }
            } catch {
                errorMessage = "Failed to stop recording: \(error.localizedDescription)"
            }
        }
    }
    
    func viewRecording(_ record: ScreenRecordingRecord) {
        var updatedRecord = record
        updatedRecord.chainOfCustody.append(CustodyEvent(action: .viewed))
        
        // Update in database
        // Note: Would need an update method in DatabaseService
    }
}
