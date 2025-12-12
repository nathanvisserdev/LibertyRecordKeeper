//
//  CameraService.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import AVFoundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum CameraError: Error {
    case notAuthorized
    case setupFailed
    case captureFailed
}

class CameraService: NSObject, ObservableObject {
    static let shared = CameraService()
    
    @Published var isRecording = false
    @Published var isCameraAvailable = false
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentVideoURL: URL?
    
    private var videoCompletionHandler: ((Result<VideoRecord, Error>) -> Void)?
    private var photoCompletionHandler: ((Result<PhotoRecord, Error>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    func checkAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    func setupCamera() async throws {
        guard await checkAuthorization() else {
            throw CameraError.notAuthorized
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        #if os(iOS)
        session.sessionPreset = .high
        #endif
        
        // Setup video input
        guard let camera = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: camera) else {
            throw CameraError.setupFailed
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Setup audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        // Setup video output
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            videoOutput = movieOutput
        }
        
        // Setup photo output
        let photoOut = AVCapturePhotoOutput()
        if session.canAddOutput(photoOut) {
            session.addOutput(photoOut)
            photoOutput = photoOut
        }
        
        session.commitConfiguration()
        
        captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        
        await MainActor.run {
            isCameraAvailable = true
        }
    }
    
    func startVideoRecording(completion: @escaping (Result<VideoRecord, Error>) -> Void) throws {
        guard let videoOutput = videoOutput else {
            throw CameraError.setupFailed
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosFolder = documentsPath.appendingPathComponent("Videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: videosFolder, withIntermediateDirectories: true)
        
        let fileName = "Video_\(Date().timeIntervalSince1970).mp4"
        let videoURL = videosFolder.appendingPathComponent(fileName)
        
        currentVideoURL = videoURL
        videoCompletionHandler = completion
        
        videoOutput.startRecording(to: videoURL, recordingDelegate: self)
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func stopVideoRecording() {
        videoOutput?.stopRecording()
    }
    
    func capturePhoto(completion: @escaping (Result<PhotoRecord, Error>) -> Void) throws {
        guard let photoOutput = photoOutput else {
            throw CameraError.setupFailed
        }
        
        photoCompletionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
        
        DispatchQueue.main.async {
            self.isCameraAvailable = false
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        if let error = error {
            videoCompletionHandler?(.failure(error))
            return
        }
        
        // Get video properties
        let asset = AVAsset(url: outputFileURL)
        let duration = asset.duration.seconds
        let tracks = asset.tracks(withMediaType: .video)
        
        var resolution = "Unknown"
        var codec = "H.264"
        
        if let videoTrack = tracks.first {
            let size = videoTrack.naturalSize
            resolution = "\(Int(size.width))x\(Int(size.height))"
            
            if let formatDescription = videoTrack.formatDescriptions.first as? CMFormatDescription {
                let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
                codec = fourCCToString(codecType)
            }
        }
        
        let record = VideoRecord(
            fileURL: outputFileURL,
            duration: duration,
            resolution: resolution,
            codec: codec
        )
        
        videoCompletionHandler?(.success(record))
        videoCompletionHandler = nil
    }
    
    private func fourCCToString(_ fourCC: FourCharCode) -> String {
        let bytes: [CChar] = [
            CChar((fourCC >> 24) & 0xff),
            CChar((fourCC >> 16) & 0xff),
            CChar((fourCC >> 8) & 0xff),
            CChar(fourCC & 0xff),
            0
        ]
        return String(cString: bytes)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoCompletionHandler?(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            photoCompletionHandler?(.failure(CameraError.captureFailed))
            return
        }
        
        // Save photo to disk
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let photosFolder = documentsPath.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: photosFolder, withIntermediateDirectories: true)
        
        let fileName = "Photo_\(Date().timeIntervalSince1970).jpg"
        let photoURL = photosFolder.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: photoURL)
            
            #if os(iOS)
            let image = UIImage(data: imageData)
            let resolution = "\(Int(image?.size.width ?? 0))x\(Int(image?.size.height ?? 0))"
            #elseif os(macOS)
            let image = NSImage(data: imageData)
            let resolution = "\(Int(image?.size.width ?? 0))x\(Int(image?.size.height ?? 0))"
            #endif
            
            let record = PhotoRecord(
                fileURL: photoURL,
                resolution: resolution,
                format: "JPEG"
            )
            
            photoCompletionHandler?(.success(record))
            photoCompletionHandler = nil
            
        } catch {
            photoCompletionHandler?(.failure(error))
        }
    }
}
