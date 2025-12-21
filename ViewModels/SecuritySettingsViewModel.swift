// SecuritySettingsViewModel.swift
// Handles logic for security settings, including 2FA setup.

import Foundation

class SecuritySettingsViewModel: ObservableObject {
    @Published var is2FAEnabled: Bool = false
    @Published var secret: String? = nil
    @Published var setupError: String? = nil

    private let twoFactorService: TwoFactorAuthServiceProtocol

    init(twoFactorService: TwoFactorAuthServiceProtocol) {
        self.twoFactorService = twoFactorService
    }

    func setup2FA() {
        // Generate a random secret for TOTP
        let secretData = Data((0..<20).map { _ in UInt8.random(in: 0...255) })
        secret = secretData.base64EncodedString()
        is2FAEnabled = true
    }

    func disable2FA() {
        secret = nil
        is2FAEnabled = false
    }
}
