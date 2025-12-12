//
//  ScreenshotViewModel.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import Combine

@MainActor
class ScreenshotViewModel: ObservableObject {
    @Published var screenshots: [ScreenshotRecord] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let screenshotMonitor = ScreenshotMonitorService.shared
    private let databaseService = DatabaseService.shared
    private let cloudKitService = CloudKitService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Monitor for new screenshots
        screenshotMonitor.$newScreenshotDetected
            .compactMap { $0 }
            .sink { [weak self] record in
                self?.handleNewScreenshot(record)
            }
            .store(in: &cancellables)
        
        loadScreenshots()
        screenshotMonitor.startMonitoring()
    }
    
    func loadScreenshots() {
        isLoading = true
        Task {
            do {
                let records = try databaseService.fetchAllScreenshots()
                await MainActor.run {
                    self.screenshots = records
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load screenshots: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleNewScreenshot(_ record: ScreenshotRecord) {
        Task {
            do {
                var newRecord = record
                newRecord.chainOfCustody.append(CustodyEvent(action: .created))
                
                // Save to database
                try databaseService.saveScreenshot(newRecord)
                
                // Upload to CloudKit
                try await cloudKitService.uploadScreenshot(newRecord)
                
                await MainActor.run {
                    self.screenshots.insert(newRecord, at: 0)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save screenshot: \(error.localizedDescription)"
                }
            }
        }
    }
}
