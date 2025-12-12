//
//  PlatformHelpers.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import Combine

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor

extension ForensicMetadata {
    static func getDeviceIdentifier() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}

#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor

extension ForensicMetadata {
    static func getDeviceIdentifier() -> String {
        // Get hardware UUID on macOS
        var uuid: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        var ts = timespec()
        gethostuuid(&uuid, &ts)
        
        let uuidString = UUID(uuid: uuid).uuidString
        return uuidString
    }
}
#endif
