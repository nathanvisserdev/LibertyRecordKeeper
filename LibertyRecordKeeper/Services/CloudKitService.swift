//
//  CloudKitService.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import CloudKit

enum CloudKitError: Error {
    case notAuthenticated
    case uploadFailed
    case downloadFailed
    case deleteFailed
}

class CloudKitService {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private init() {
        let containerIdentifier = "iCloud.com.Liberty.LibertyRecordKeeper"
        print("Initializing CloudKit container with identifier: \(containerIdentifier)")
        container = CKContainer(identifier: containerIdentifier)
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async throws -> Bool {
        print("Checking iCloud account status...")
        let status = try await container.accountStatus()
        print("iCloud account status: \(status)")
        return status == .available
    }
    
    // MARK: - Screen Recordings
    
    func uploadScreenRecording(_ record: ScreenRecordingRecord) async throws {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: "ScreenRecording", recordID: recordID)
        
        ckRecord["createdAt"] = record.createdAt as CKRecordValue
        ckRecord["modifiedAt"] = record.modifiedAt as CKRecordValue
        ckRecord["deviceIdentifier"] = record.deviceIdentifier as CKRecordValue
        ckRecord["checksumSHA256"] = record.checksumSHA256 as CKRecordValue
        ckRecord["fileSize"] = record.fileSize as CKRecordValue
        ckRecord["duration"] = record.duration as CKRecordValue
        ckRecord["resolution"] = record.resolution as CKRecordValue
        ckRecord["frameRate"] = record.frameRate as CKRecordValue
        
        if let fileURL = record.fileURL {
            let asset = CKAsset(fileURL: fileURL)
            ckRecord["file"] = asset
        }
        
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        ckRecord["metadata"] = String(data: metadataJSON, encoding: .utf8) as CKRecordValue?
        
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        ckRecord["chainOfCustody"] = String(data: custodyJSON, encoding: .utf8) as CKRecordValue?
        
        do {
            _ = try await privateDatabase.save(ckRecord)
        } catch {
            throw CloudKitError.uploadFailed
        }
    }
    
    // MARK: - Videos
    
    func uploadVideo(_ record: VideoRecord) async throws {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: "Video", recordID: recordID)
        
        ckRecord["createdAt"] = record.createdAt as CKRecordValue
        ckRecord["modifiedAt"] = record.modifiedAt as CKRecordValue
        ckRecord["deviceIdentifier"] = record.deviceIdentifier as CKRecordValue
        ckRecord["checksumSHA256"] = record.checksumSHA256 as CKRecordValue
        ckRecord["fileSize"] = record.fileSize as CKRecordValue
        ckRecord["duration"] = record.duration as CKRecordValue
        ckRecord["resolution"] = record.resolution as CKRecordValue
        ckRecord["codec"] = record.codec as CKRecordValue
        
        if let fileURL = record.fileURL {
            let asset = CKAsset(fileURL: fileURL)
            ckRecord["file"] = asset
        }
        
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        ckRecord["metadata"] = String(data: metadataJSON, encoding: .utf8) as CKRecordValue?
        
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        ckRecord["chainOfCustody"] = String(data: custodyJSON, encoding: .utf8) as CKRecordValue?
        
        do {
            _ = try await privateDatabase.save(ckRecord)
        } catch {
            throw CloudKitError.uploadFailed
        }
    }
    
    // MARK: - Photos
    
    func uploadPhoto(_ record: PhotoRecord) async throws {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: "Photo", recordID: recordID)
        
        ckRecord["createdAt"] = record.createdAt as CKRecordValue
        ckRecord["modifiedAt"] = record.modifiedAt as CKRecordValue
        ckRecord["deviceIdentifier"] = record.deviceIdentifier as CKRecordValue
        ckRecord["checksumSHA256"] = record.checksumSHA256 as CKRecordValue
        ckRecord["fileSize"] = record.fileSize as CKRecordValue
        ckRecord["resolution"] = record.resolution as CKRecordValue
        ckRecord["format"] = record.format as CKRecordValue
        
        if let fileURL = record.fileURL {
            let asset = CKAsset(fileURL: fileURL)
            ckRecord["file"] = asset
        }
        
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        ckRecord["metadata"] = String(data: metadataJSON, encoding: .utf8) as CKRecordValue?
        
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        ckRecord["chainOfCustody"] = String(data: custodyJSON, encoding: .utf8) as CKRecordValue?
        
        do {
            _ = try await privateDatabase.save(ckRecord)
        } catch {
            throw CloudKitError.uploadFailed
        }
    }
    
    // MARK: - Audio Recordings
    
    func uploadAudioRecording(_ record: AudioRecord) async throws {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: "AudioRecording", recordID: recordID)
        
        ckRecord["createdAt"] = record.createdAt as CKRecordValue
        ckRecord["modifiedAt"] = record.modifiedAt as CKRecordValue
        ckRecord["deviceIdentifier"] = record.deviceIdentifier as CKRecordValue
        ckRecord["checksumSHA256"] = record.checksumSHA256 as CKRecordValue
        ckRecord["fileSize"] = record.fileSize as CKRecordValue
        ckRecord["duration"] = record.duration as CKRecordValue
        ckRecord["format"] = record.format as CKRecordValue
        ckRecord["sampleRate"] = record.sampleRate as CKRecordValue
        
        if let fileURL = record.fileURL {
            let asset = CKAsset(fileURL: fileURL)
            ckRecord["file"] = asset
        }
        
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        ckRecord["metadata"] = String(data: metadataJSON, encoding: .utf8) as CKRecordValue?
        
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        ckRecord["chainOfCustody"] = String(data: custodyJSON, encoding: .utf8) as CKRecordValue?
        
        do {
            _ = try await privateDatabase.save(ckRecord)
        } catch {
            throw CloudKitError.uploadFailed
        }
    }
    
    // MARK: - Screenshots
    
    func uploadScreenshot(_ record: ScreenshotRecord) async throws {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: "Screenshot", recordID: recordID)
        
        ckRecord["createdAt"] = record.createdAt as CKRecordValue
        ckRecord["modifiedAt"] = record.modifiedAt as CKRecordValue
        ckRecord["deviceIdentifier"] = record.deviceIdentifier as CKRecordValue
        ckRecord["checksumSHA256"] = record.checksumSHA256 as CKRecordValue
        ckRecord["fileSize"] = record.fileSize as CKRecordValue
        ckRecord["resolution"] = record.resolution as CKRecordValue
        ckRecord["format"] = record.format as CKRecordValue
        
        if let fileURL = record.fileURL {
            let asset = CKAsset(fileURL: fileURL)
            ckRecord["file"] = asset
        }
        
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        ckRecord["metadata"] = String(data: metadataJSON, encoding: .utf8) as CKRecordValue?
        
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        ckRecord["chainOfCustody"] = String(data: custodyJSON, encoding: .utf8) as CKRecordValue?
        
        do {
            _ = try await privateDatabase.save(ckRecord)
        } catch {
            throw CloudKitError.uploadFailed
        }
    }
    
    // MARK: - AI Chat Logs
    
    func uploadAIChatLog(_ record: AIChatLogRecord) async throws {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: "AIChatLog", recordID: recordID)
        
        ckRecord["createdAt"] = record.createdAt as CKRecordValue
        ckRecord["modifiedAt"] = record.modifiedAt as CKRecordValue
        ckRecord["deviceIdentifier"] = record.deviceIdentifier as CKRecordValue
        ckRecord["checksumSHA256"] = record.checksumSHA256 as CKRecordValue
        ckRecord["fileSize"] = record.fileSize as CKRecordValue
        ckRecord["conversationTitle"] = record.conversationTitle as CKRecordValue
        ckRecord["messageCount"] = record.messageCount as CKRecordValue
        
        if let fileURL = record.fileURL {
            let asset = CKAsset(fileURL: fileURL)
            ckRecord["file"] = asset
        }
        
        let metadataJSON = try JSONEncoder().encode(record.metadata)
        ckRecord["metadata"] = String(data: metadataJSON, encoding: .utf8) as CKRecordValue?
        
        let custodyJSON = try JSONEncoder().encode(record.chainOfCustody)
        ckRecord["chainOfCustody"] = String(data: custodyJSON, encoding: .utf8) as CKRecordValue?
        
        do {
            _ = try await privateDatabase.save(ckRecord)
        } catch {
            throw CloudKitError.uploadFailed
        }
    }
}
