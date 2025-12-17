//
//  GetAllVideosService.swift
//  LibertyRecordKeeper
//
//  Created on 12/17/2025.
//

import Foundation
import CryptoKit

class GetAllVideosService {
    static func fetchAllVideos(from directory: String) throws -> [VideoRecord] {
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: directory)

        guard let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            throw NSError(domain: "GetAllVideosService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read directory contents."])
        }

        return files.compactMap { fileURL in
            guard fileURL.pathExtension == "mp4" else { return nil }

            let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes?[.size] as? Int64 ?? 0
            let creationDate = attributes?[.creationDate] as? Date ?? Date()

            let duration: TimeInterval = 0.0 // Placeholder for actual duration extraction
            let resolution = "Unknown" // Placeholder for actual resolution extraction
            let frameRate: Double = 0.0 // Placeholder for actual frame rate extraction
            let codec = "Unknown" // Placeholder for actual codec extraction

            return VideoRecord(
                fileURL: fileURL,
                duration: duration,
                resolution: resolution,
                frameRate: frameRate,
                codec: codec
            )
        }
    }
}
