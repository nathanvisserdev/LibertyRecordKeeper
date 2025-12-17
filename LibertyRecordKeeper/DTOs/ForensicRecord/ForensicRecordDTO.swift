//
//  ForensicRecord.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import CryptoKit

// This file will be split into multiple files categorically under the ForensicRecord folder.

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
