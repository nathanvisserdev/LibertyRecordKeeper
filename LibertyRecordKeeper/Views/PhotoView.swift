//
//  PhotoView.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PhotoView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @State private var selectedPhoto: PhotoRecord?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading photos...")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                            ForEach(viewModel.photos) { photo in
                                PhotoThumbnail(photo: photo)
                                    .onTapGesture {
                                        selectedPhoto = photo
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Camera Controls
                HStack(spacing: 20) {
                    if !viewModel.isCameraReady {
                        Button("Setup Camera") {
                            viewModel.setupCamera()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Button(action: {
                            viewModel.capturePhoto()
                        }) {
                            HStack {
                                Image(systemName: "camera.circle")
                                Text("Take Photo")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Photos")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
}

struct PhotoThumbnail: View {
    let photo: PhotoRecord
    @State private var image: Image?
    
    var body: some View {
        VStack {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
                    .overlay(
                        ProgressView()
                    )
            }
            
            Text(formatDate(photo.createdAt))
                .font(.caption)
                .lineLimit(1)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = photo.fileURL else { return }
        
        #if os(iOS)
        if let uiImage = UIImage(contentsOfFile: url.path) {
            image = Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = NSImage(contentsOf: url) {
            image = Image(nsImage: nsImage)
        }
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PhotoDetailView: View {
    let photo: PhotoRecord
    @State private var image: Image?
    
    var body: some View {
        VStack {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Captured: \(formatDate(photo.createdAt))")
                Text("Resolution: \(photo.resolution)")
                Text("Format: \(photo.format)")
                Text("Size: \(formatFileSize(photo.fileSize))")
                Text("Checksum: \(photo.checksumSHA256)")
                    .font(.caption)
                    .lineLimit(2)
            }
            .padding()
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = photo.fileURL else { return }
        
        #if os(iOS)
        if let uiImage = UIImage(contentsOfFile: url.path) {
            image = Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = NSImage(contentsOf: url) {
            image = Image(nsImage: nsImage)
        }
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
