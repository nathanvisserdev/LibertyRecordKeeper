// SecuritySettingsView.swift
// Allows user to set up 2FA and manage security settings.

import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SecuritySettingsViewModel

    var body: some View {
        Form {
            Section(header: Text("Two-Factor Authentication")) {
                Toggle("Enable 2FA", isOn: $viewModel.is2FAEnabled)
                if viewModel.is2FAEnabled, let secret = viewModel.secret {
                    Text("Scan this QR code with Microsoft Authenticator:")
                    // Placeholder for QR code
                    Text(secret).font(.footnote).foregroundColor(.gray)
                }
                if let error = viewModel.setupError {
                    Text(error).foregroundColor(.red)
                }
            }
            Button(viewModel.is2FAEnabled ? "Disable 2FA" : "Setup 2FA") {
                if viewModel.is2FAEnabled {
                    viewModel.disable2FA()
                } else {
                    viewModel.setup2FA()
                }
            }
        }
        .navigationTitle("Security Settings")
    }
}
