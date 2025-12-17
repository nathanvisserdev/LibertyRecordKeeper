//
//  CustodyEvent.swift
//  LibertyRecordKeeper
//
//  Created on 12/17/2025.
//

import Foundation

/// Represents an event in the chain of custody
struct CustodyEvent: Codable, Hashable {
    let timestamp: Date
    let eventDescription: String
    let user: String
}