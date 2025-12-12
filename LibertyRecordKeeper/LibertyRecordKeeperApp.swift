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
            } catch let error as DatabaseError {
                await MainActor.run {
                    switch error {
                    case .openFailed:
                        errorMessage = "Failed to open database. Please check app permissions."
                    case .prepareFailed:
                        errorMessage = "Database initialization failed. Please restart the app."
                    case .executeFailed:
                        errorMessage = "Database setup failed. Please restart the app."
                    default:
                        errorMessage = "Database error: \(error)"
                    }
                    showError = true
                }
            } catch let error as BiometricAuthError {
                await MainActor.run {
                    switch error {
                    case .authenticationFailed:
                        errorMessage = "Biometric authentication failed. Please try again."
                    case .biometricsNotAvailable:
                        errorMessage = "Biometric authentication is not available on this device."
                    case .keyGenerationFailed:
                        errorMessage = "Failed to generate encryption key."
                    case .keyRetrievalFailed:
                        errorMessage = "Failed to retrieve encryption key."
                    }
                    showError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Authentication error: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
