//
//  ScreenRecordingService.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import ReplayKit
import AVFoundation

#if os(iOS)
import UIKit
#endif

enum RecordingError: Error {
    case notAvailable
    case recordingFailed
    case saveFailed
}

class ScreenRecordingService: NSObject, ObservableObject {
    static let shared = ScreenRecordingService()
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    
    private var recorder: RPScreenRecorder?
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var startTime: Date?
    private var outputURL: URL?
    
    private override init() {
        super.init()
        recorder = RPScreenRecorder.shared()
    }
    
    func checkAvailability() -> Bool {
        return RPScreenRecorder.shared().isAvailable
    }
    
    func startRecording() async throws {
        guard let recorder = recorder, recorder.isAvailable else {
            throw RecordingError.notAvailable
        }
        
        // Create output file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recordingsFolder = documentsPath.appendingPathComponent("ScreenRecordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsFolder, withIntermediateDirectories: true)
        
        let fileName = "ScreenRecording_\(Date().timeIntervalSince1970).mp4"
        outputURL = recordingsFolder.appendingPathComponent(fileName)
        
        guard let outputURL = outputURL else {
            throw RecordingError.recordingFailed
        }
        
        // Setup video writer
        videoWriter = try AVAssetWriter(url: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true
        
        if let videoWriterInput = videoWriterInput, videoWriter?.canAdd(videoWriterInput) == true {
            videoWriter?.add(videoWriterInput)
        }
        
        // Setup audio writer
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        
        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioWriterInput?.expectsMediaDataInRealTime = true
        
        if let audioWriterInput = audioWriterInput, videoWriter?.canAdd(audioWriterInput) == true {
            videoWriter?.add(audioWriterInput)
        }
        
        startTime = Date()
        
        // Start recording
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            recorder.startCapture(handler: { [weak self] sampleBuffer, bufferType, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                self?.processSampleBuffer(sampleBuffer, bufferType: bufferType)
            }) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    DispatchQueue.main.async {
                        self.isRecording = true
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, bufferType: RPSampleBufferType) {
        guard videoWriter?.status == .writing else {
            if videoWriter?.status == .unknown {
                videoWriter?.startWriting()
                videoWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
            return
        }
        
        switch bufferType {
        case .video:
            if videoWriterInput?.isReadyForMoreMediaData == true {
                videoWriterInput?.append(sampleBuffer)
            }
        case .audioMic, .audioApp:
            if audioWriterInput?.isReadyForMoreMediaData == true {
                audioWriterInput?.append(sampleBuffer)
            }
        @unknown default:
            break
        }
    }
    
    func stopRecording() async throws -> ScreenRecordingRecord {
        guard let recorder = recorder, isRecording else {
            throw RecordingError.recordingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            recorder.stopCapture { [weak self] error in
                guard let self = self else {
                    continuation.resume(throwing: RecordingError.recordingFailed)
                    return
                }
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                self.videoWriterInput?.markAsFinished()
                self.audioWriterInput?.markAsFinished()
                
                self.videoWriter?.finishWriting { [weak self] in
                    guard let self = self,
                          let outputURL = self.outputURL,
                          let startTime = self.startTime else {
                        continuation.resume(throwing: RecordingError.saveFailed)
                        return
                    }
                    
                    let duration = Date().timeIntervalSince(startTime)
                    
                    // Get video properties
                    let asset = AVAsset(url: outputURL)
                    let tracks = asset.tracks(withMediaType: .video)
                    
                    var resolution = "Unknown"
                    var frameRate = 0.0
                    
                    if let videoTrack = tracks.first {
                        let size = videoTrack.naturalSize
                        resolution = "\(Int(size.width))x\(Int(size.height))"
                        frameRate = Double(videoTrack.nominalFrameRate)
                    }
                    
                    let record = ScreenRecordingRecord(
                        fileURL: outputURL,
                        duration: duration,
                        resolution: resolution,
                        frameRate: frameRate
                    )
                    
                    DispatchQueue.main.async {
                        self.isRecording = false
                        self.recordingDuration = 0
                    }
                    
                    continuation.resume(returning: record)
                }
            }
        }
    }
}
