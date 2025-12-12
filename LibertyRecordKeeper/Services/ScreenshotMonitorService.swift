//
//  ScreenshotMonitorService.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
import CoreGraphics
#endif

class ScreenshotMonitorService: ObservableObject {
    static let shared = ScreenshotMonitorService()
    
    @Published var newScreenshotDetected: ScreenshotRecord?
    
    private var lastPhotoCount = 0
    private var monitorTimer: Timer?
    
    private init() {}
    
    #if os(iOS)
    func startMonitoring() {
        // On iOS, monitor for screenshot notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    @objc private func screenshotTaken() {
        // On iOS, we can't directly access the screenshot file
        // We need to prompt the user to import it or use Photos framework
        // For now, we'll create a placeholder record
        Task {
            await handleScreenshotDetected()
        }
    }
    
    private func handleScreenshotDetected() async {
        // In a real implementation, you would:
        // 1. Request Photos library access
        // 2. Fetch the most recent screenshot
        // 3. Copy it to app's documents directory
        // 4. Create a ScreenshotRecord
        
        // Placeholder implementation
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotsFolder = documentsPath.appendingPathComponent("Screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: screenshotsFolder, withIntermediateDirectories: true)
        
        let fileName = "Screenshot_\(Date().timeIntervalSince1970).png"
        let screenshotURL = screenshotsFolder.appendingPathComponent(fileName)
        
        // You would copy the actual screenshot here
        // For now, creating a record with placeholder data
        let screen = UIScreen.main
        let resolution = "\(Int(screen.bounds.width * screen.scale))x\(Int(screen.bounds.height * screen.scale))"
        
        let record = ScreenshotRecord(
            fileURL: screenshotURL,
            resolution: resolution,
            format: "PNG"
        )
        
        await MainActor.run {
            self.newScreenshotDetected = record
        }
    }
    #elseif os(macOS)
    func startMonitoring() {
        // On macOS, monitor the Desktop and Screenshots folders
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForNewScreenshots()
        }
    }
    
    private func checkForNewScreenshots() {
        let fileManager = FileManager.default
        
        // Check default screenshot locations
        let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
        let picturesURL = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first
        
        var screenshotLocations: [URL] = []
        
        if let desktop = desktopURL {
            screenshotLocations.append(desktop)
        }
        
        if let pictures = picturesURL {
            let screenshotsFolder = pictures.appendingPathComponent("Screenshots")
            screenshotLocations.append(screenshotsFolder)
        }
        
        for location in screenshotLocations {
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: location,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: [.skipsHiddenFiles]
                )
                
                // Filter for recent screenshots (within last 5 seconds)
                let recentScreenshots = contents.filter { url in
                    guard url.pathExtension.lowercased() == "png",
                          url.lastPathComponent.contains("Screen Shot") ||
                          url.lastPathComponent.contains("Screenshot") else {
                        return false
                    }
                    
                    if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                       let creationDate = attributes[.creationDate] as? Date {
                        return Date().timeIntervalSince(creationDate) < 5.0
                    }
                    
                    return false
                }
                
                for screenshotURL in recentScreenshots {
                    copyAndCatalogScreenshot(screenshotURL)
                }
                
            } catch {
                continue
            }
        }
    }
    
    private func copyAndCatalogScreenshot(_ sourceURL: URL) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotsFolder = documentsPath.appendingPathComponent("Screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: screenshotsFolder, withIntermediateDirectories: true)
        
        let fileName = "Screenshot_\(Date().timeIntervalSince1970).png"
        let destinationURL = screenshotsFolder.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            if let image = NSImage(contentsOf: destinationURL) {
                let size = image.size
                let resolution = "\(Int(size.width))x\(Int(size.height))"
                
                let record = ScreenshotRecord(
                    fileURL: destinationURL,
                    resolution: resolution,
                    format: "PNG"
                )
                
                DispatchQueue.main.async {
                    self.newScreenshotDetected = record
                }
            }
        } catch {
            // Failed to copy screenshot
        }
    }
    #endif
    
    func stopMonitoring() {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self)
        #elseif os(macOS)
        monitorTimer?.invalidate()
        monitorTimer = nil
        #endif
    }
}
