//
//  ForensicMetadata.swift
//  LibertyRecordKeeper
//
//  Created on 12/17/2025.
//

import Foundation

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
        self.userIdentifier = ""
    }

    private static func getDeviceModel() -> String {
        // Implementation for fetching device model
        return "Unknown Device"
    }

    private static func getOSVersion() -> String {
        // Implementation for fetching OS version
        return "Unknown OS"
    }

    private static func getAppVersion() -> String {
        // Implementation for fetching app version
        return "1.0"
    }
}