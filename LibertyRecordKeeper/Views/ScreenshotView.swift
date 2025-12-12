//
//  ScreenshotView.swift
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

struct ScreenshotView: View {
    @StateObject private var viewModel = ScreenshotViewModel()
    @State private var selectedScreenshot: ScreenshotRecord?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading screenshots...")
                } else if viewModel.screenshots.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("No Screenshots Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Screenshots you take will automatically appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                            ForEach(viewModel.screenshots) { screenshot in
                                ScreenshotThumbnail(screenshot: screenshot)
                                    .onTapGesture {
                                        selectedScreenshot = screenshot
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Screenshots")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedScreenshot) { screenshot in
                ScreenshotDetailView(screenshot: screenshot)
            }
        }
    }
}

struct ScreenshotThumbnail: View {
    let screenshot: ScreenshotRecord
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
            
            Text(formatDate(screenshot.createdAt))
                .font(.caption)
                .lineLimit(1)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = screenshot.fileURL else { return }
        
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

struct ScreenshotDetailView: View {
    let screenshot: ScreenshotRecord
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
                Text("Captured: \(formatDate(screenshot.createdAt))")
                Text("Resolution: \(screenshot.resolution)")
                Text("Format: \(screenshot.format)")
                Text("Size: \(formatFileSize(screenshot.fileSize))")
                Text("Checksum: \(screenshot.checksumSHA256)")
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
        guard let url = screenshot.fileURL else { return }
        
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
