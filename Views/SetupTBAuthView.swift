// SetupTBAuthView.swift
// View for presenting QR code, accepting TOTP, and showing backup codes securely.

import SwiftUI

struct SetupTBAuthView: View {
    @ObservedObject var viewModel: SetupTBAuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Set Up Two-Factor Authentication")
                .font(.title2)
                .bold()
            if let url = viewModel.qrCodeURL {
                // Placeholder for QR code image
                Text("Scan this QR code with Microsoft Authenticator:")
                Text(url.absoluteString)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            TextField("Enter 6-digit code", text: $viewModel.code)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let error = viewModel.error {
                Text(error).foregroundColor(.red)
            }
            Button("Verify Code") {
                viewModel.verifyCode()
            }
            if viewModel.showBackupCodes, let codes = viewModel.backupCodes {
                VStack(spacing: 8) {
                    Text("Backup Codes (One-Time Use)")
                        .font(.headline)
                    Text("Take a record of these codes and do not lose them or allow them to be intercepted.")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                    ForEach(codes, id: \ .self) { code in
                        Text(code).font(.system(.body, design: .monospaced))
                    }
                    Button("I have taken a copy for my records") {
                        viewModel.acknowledgeBackupCodes()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .navigationTitle("2FA Setup")
    }
}
