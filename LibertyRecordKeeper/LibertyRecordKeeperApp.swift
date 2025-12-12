//
//  LibertyRecordKeeperApp.swift
//  LibertyRecordKeeper
//
//  Created by Nathan Visser on 2025-12-12.
//

import SwiftUI
import CryptoKit

@main
struct LibertyRecordKeeperApp: App {
    @State private var isAuthenticated = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
            } else {
                AuthenticationView(
                    isAuthenticated: $isAuthenticated,
                    showError: $showError,
                    errorMessage: $errorMessage
                )
            }
        }
    }
}

struct AuthenticationView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield")
                .resizable()
                .frame(width: 100, height: 120)
                .foregroundColor(.blue)
            
            Text("Liberty Record Keeper")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Secure Forensic Evidence Management")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                authenticate()
            }) {
                HStack {
                    Image(systemName: "faceid")
                    Text("Authenticate with Biometrics")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .alert("Authentication Error", isPresented: $showError) {
            Button("Retry") {
                authenticate()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func authenticate() {
        Task {
            do {
                let key = try await BiometricAuthService.shared.authenticate()
                
                // Initialize database with encryption key
                try DatabaseService.shared.initializeDatabase(with: key)
                
                await MainActor.run {
                    isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
