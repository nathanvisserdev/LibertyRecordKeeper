//
//  AudioRecordingService.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import AVFoundation

enum AudioRecordingError: Error {
    case notAuthorized
    case setupFailed
    case recordingFailed
}

class AudioRecordingService: NSObject, ObservableObject {
    static let shared = AudioRecordingService()
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var startTime: Date?
    
    private override init() {
        super.init()
    }
    
    func checkAuthorization() async -> Bool {
        let status = AVAudioSession.sharedInstance().recordPermission
        
        switch status {
        case .granted:
            return true
        case .undetermined:
            return await AVAudioSession.sharedInstance().requestRecordPermission()
        default:
            return false
        }
    }
    
    func startRecording() async throws {
        guard await checkAuthorization() else {
            throw AudioRecordingError.notAuthorized
        }
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
        
        // Create output file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recordingsFolder = documentsPath.appendingPathComponent("AudioRecordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsFolder, withIntermediateDirectories: true)
        
        let fileName = "Audio_\(Date().timeIntervalSince1970).m4a"
        let audioURL = recordingsFolder.appendingPathComponent(fileName)
        
        // Setup recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        
        guard audioRecorder?.record() == true else {
            throw AudioRecordingError.recordingFailed
        }
        
        startTime = Date()
        
        await MainActor.run {
            isRecording = true
            startTimer()
        }
    }
    
    func stopRecording() async throws -> AudioRecord {
        guard let recorder = audioRecorder, isRecording else {
            throw AudioRecordingError.recordingFailed
        }
        
        recorder.stop()
        
        guard let audioURL = recorder.url,
              let startTime = startTime else {
            throw AudioRecordingError.recordingFailed
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Get audio properties
        let asset = AVAsset(url: audioURL)
        let tracks = asset.tracks(withMediaType: .audio)
        
        var sampleRate = 44100.0
        var format = "AAC"
        
        if let audioTrack = tracks.first {
            if let formatDescription = audioTrack.formatDescriptions.first as? CMFormatDescription {
                if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                    sampleRate = streamBasicDescription.pointee.mSampleRate
                }
            }
        }
        
        let record = AudioRecord(
            fileURL: audioURL,
            duration: duration,
            format: format,
            sampleRate: sampleRate
        )
        
        await MainActor.run {
            isRecording = false
            stopTimer()
            recordingDuration = 0
        }
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        return record
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            DispatchQueue.main.async {
                self.isRecording = false
                self.stopTimer()
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.stopTimer()
        }
    }
}
