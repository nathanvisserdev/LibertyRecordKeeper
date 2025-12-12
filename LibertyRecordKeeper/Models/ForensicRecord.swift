//
//  ForensicRecord.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import CryptoKit

/// Base protocol for all forensic records with chain of custody
protocol ForensicRecord: Identifiable, Codable {
    var id: UUID { get }
    var createdAt: Date { get }
    var modifiedAt: Date { get }
    var deviceIdentifier: String { get }
    var checksumSHA256: String { get }
    var fileURL: URL? { get }
    var fileSize: Int64 { get }
    var metadata: ForensicMetadata { get }
    var chainOfCustody: [CustodyEvent] { get set }
}

/// Forensic metadata for legal admissibility
struct ForensicMetadata: Codable, Hashable {
    let captureDate: Date
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let timezone: String
    let latitude: Double?
    let longitude: Double?
    let locationAccuracy: Double?
    let userIdentifier: String
    
    init() {
        self.captureDate = Date()
        self.deviceModel = Self.getDeviceModel()
        self.osVersion = Self.getOSVersion()
        self.appVersion = Self.getAppVersion()
        self.timezone = TimeZone.current.identifier
        self.latitude = nil
        self.longitude = nil
        self.locationAccuracy = nil
        self.userIdentifier = Self.getUserIdentifier()
    }
    
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    static func getOSVersion() -> String {
        #if os(iOS)
        return "iOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        #elseif os(macOS)
        return "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        #endif
    }
    
    static func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    static func getUserIdentifier() -> String {
        // Use device identifier for user
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(macOS)
        // Get hardware UUID on macOS
        var uuid: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        var ts = timespec()
        gethostuuid(&uuid, &ts)
        return UUID(uuid: uuid).uuidString
        #endif
    }
}

/// Chain of custody event
struct CustodyEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let action: CustodyAction
    let userIdentifier: String
    let deviceIdentifier: String
    
    enum CustodyAction: String, Codable {
        case created
        case viewed
        case exported
        case synced
        case verified
    }
    
    init(action: CustodyAction) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.userIdentifier = ForensicMetadata.getUserIdentifier()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
    }
}

/// Screen Recording Record
struct ScreenRecordingRecord: ForensicRecord {
    let id: UUID
    let createdAt: Date
    var modifiedAt: Date
    let deviceIdentifier: String
    let checksumSHA256: String
    let fileURL: URL?
    let fileSize: Int64
    let metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    
    let duration: TimeInterval
    let resolution: String
    let frameRate: Double
    
    init(fileURL: URL, duration: TimeInterval, resolution: String, frameRate: Double) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.duration = duration
        self.resolution = resolution
        self.frameRate = frameRate
        self.metadata = ForensicMetadata()
        self.chainOfCustody = [CustodyEvent(action: .created)]
        
        // Calculate file size and checksum
        if let data = try? Data(contentsOf: fileURL) {
            self.fileSize = Int64(data.count)
            let hash = SHA256.hash(data: data)
            self.checksumSHA256 = hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            self.fileSize = 0
            self.checksumSHA256 = ""
        }
    }
}

/// Video Record
struct VideoRecord: ForensicRecord {
    let id: UUID
    let createdAt: Date
    var modifiedAt: Date
    let deviceIdentifier: String
    let checksumSHA256: String
    let fileURL: URL?
    let fileSize: Int64
    let metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    
    let duration: TimeInterval
    let resolution: String
    let codec: String
    
    init(fileURL: URL, duration: TimeInterval, resolution: String, codec: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.duration = duration
        self.resolution = resolution
        self.codec = codec
        self.metadata = ForensicMetadata()
        self.chainOfCustody = [CustodyEvent(action: .created)]
        
        if let data = try? Data(contentsOf: fileURL) {
            self.fileSize = Int64(data.count)
            let hash = SHA256.hash(data: data)
            self.checksumSHA256 = hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            self.fileSize = 0
            self.checksumSHA256 = ""
        }
    }
}

/// Photo Record
struct PhotoRecord: ForensicRecord {
    let id: UUID
    let createdAt: Date
    var modifiedAt: Date
    let deviceIdentifier: String
    let checksumSHA256: String
    let fileURL: URL?
    let fileSize: Int64
    let metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    
    let resolution: String
    let format: String
    
    init(fileURL: URL, resolution: String, format: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.resolution = resolution
        self.format = format
        self.metadata = ForensicMetadata()
        self.chainOfCustody = [CustodyEvent(action: .created)]
        
        if let data = try? Data(contentsOf: fileURL) {
            self.fileSize = Int64(data.count)
            let hash = SHA256.hash(data: data)
            self.checksumSHA256 = hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            self.fileSize = 0
            self.checksumSHA256 = ""
        }
    }
}

/// Audio Recording Record
struct AudioRecord: ForensicRecord {
    let id: UUID
    let createdAt: Date
    var modifiedAt: Date
    let deviceIdentifier: String
    let checksumSHA256: String
    let fileURL: URL?
    let fileSize: Int64
    let metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    
    let duration: TimeInterval
    let format: String
    let sampleRate: Double
    
    init(fileURL: URL, duration: TimeInterval, format: String, sampleRate: Double) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.duration = duration
        self.format = format
        self.sampleRate = sampleRate
        self.metadata = ForensicMetadata()
        self.chainOfCustody = [CustodyEvent(action: .created)]
        
        if let data = try? Data(contentsOf: fileURL) {
            self.fileSize = Int64(data.count)
            let hash = SHA256.hash(data: data)
            self.checksumSHA256 = hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            self.fileSize = 0
            self.checksumSHA256 = ""
        }
    }
}

/// Screenshot Record
struct ScreenshotRecord: ForensicRecord {
    let id: UUID
    let createdAt: Date
    var modifiedAt: Date
    let deviceIdentifier: String
    let checksumSHA256: String
    let fileURL: URL?
    let fileSize: Int64
    let metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    
    let resolution: String
    let format: String
    
    init(fileURL: URL, resolution: String, format: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.resolution = resolution
        self.format = format
        self.metadata = ForensicMetadata()
        self.chainOfCustody = [CustodyEvent(action: .created)]
        
        if let data = try? Data(contentsOf: fileURL) {
            self.fileSize = Int64(data.count)
            let hash = SHA256.hash(data: data)
            self.checksumSHA256 = hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            self.fileSize = 0
            self.checksumSHA256 = ""
        }
    }
}

/// AI Chat Log Record
struct AIChatLogRecord: ForensicRecord {
    let id: UUID
    let createdAt: Date
    var modifiedAt: Date
    let deviceIdentifier: String
    let checksumSHA256: String
    let fileURL: URL?
    let fileSize: Int64
    let metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    
    let conversationTitle: String
    let messageCount: Int
    
    init(fileURL: URL, conversationTitle: String, messageCount: Int) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.conversationTitle = conversationTitle
        self.messageCount = messageCount
        self.metadata = ForensicMetadata()
        self.chainOfCustody = [CustodyEvent(action: .created)]
        
        if let data = try? Data(contentsOf: fileURL) {
            self.fileSize = Int64(data.count)
            let hash = SHA256.hash(data: data)
            self.checksumSHA256 = hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            self.fileSize = 0
            self.checksumSHA256 = ""
        }
    }
}
