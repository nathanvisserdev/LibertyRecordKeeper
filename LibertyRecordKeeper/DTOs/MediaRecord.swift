import Foundation

struct MediaRecord: Identifiable {
    let id: UUID
    let createdAt: Date
    let fileURL: URL
    let fileSize: Int64
    let duration: TimeInterval? // Added optional duration for media
    let resolution: String? // Added optional resolution for media
    let codec: String? // Added optional codec for media
}