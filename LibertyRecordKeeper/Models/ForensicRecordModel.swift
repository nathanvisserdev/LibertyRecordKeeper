//
//  ForensicRecord.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import CryptoKit
import NetworkExtension

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

/// Represents a forensic record with stateful logic
class ForensicRecordModel: ForensicRecord {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date
    var deviceIdentifier: String
    var checksumSHA256: String
    var fileURL: URL?
    var fileSize: Int64
    var metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    
    // Removed duplicate property definitions; inheriting from ForensicRecordDTO ensures properties are defined only once.
    // Added stateful logic and functions specific to the model.

    init(id: UUID, createdAt: Date, modifiedAt: Date, deviceIdentifier: String, checksumSHA256: String, fileURL: URL?, fileSize: Int64, metadata: ForensicMetadata, chainOfCustody: [CustodyEvent]) {
        self.id = id
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deviceIdentifier = deviceIdentifier
        self.checksumSHA256 = checksumSHA256
        self.fileURL = fileURL
        self.fileSize = fileSize
        self.metadata = metadata
        self.chainOfCustody = chainOfCustody
    }

    func updateChecksum() {
        // Logic to update checksum
    }

    func addCustodyEvent(event: CustodyEvent) {
        chainOfCustody.append(event)
    }
}

/// Audio Record
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
    let frameRate: Double
    let codec: String

    init(fileURL: URL, duration: TimeInterval, resolution: String, frameRate: Double, codec: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.duration = duration
        self.resolution = resolution
        self.frameRate = frameRate
        self.codec = codec
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

struct DocumentRecord: ForensicRecord {
    let id: UUID
    let createdAt: Date
    var modifiedAt: Date
    let deviceIdentifier: String
    let checksumSHA256: String
    let fileURL: URL?
    let fileSize: Int64
    let metadata: ForensicMetadata
    var chainOfCustody: [CustodyEvent]
    let documentType: String
    let description: String

    init(fileURL: URL, documentType: String, description: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.deviceIdentifier = ForensicMetadata.getDeviceModel()
        self.fileURL = fileURL
        self.documentType = documentType
        self.description = description
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
