//
//  VideoModel.swift
//  LibertyRecordKeeper
//
//  Created on 12/17/2025.
//

import Foundation

struct VideoModel: Identifiable {
    let id: UUID
    let createdAt: Date
    let fileURL: URL
    let fileSize: Int64
    let resolution: String
    let duration: Double
}