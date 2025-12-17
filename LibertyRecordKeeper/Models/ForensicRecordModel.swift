//
//  ForensicRecordModel.swift
//  LibertyRecordKeeper
//
//  Created on 12/17/2025.
//

import Foundation
import CryptoKit

/// Represents a forensic record with stateful logic
class ForensicRecordModel: ForensicRecordDTO {
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