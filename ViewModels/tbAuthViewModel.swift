// tbAuthViewModel.swift
// Handles logic for time-based authentication code entry.

import Foundation

class tbAuthViewModel: ObservableObject {
    @Published var code: String = ""
    @Published var error: String? = nil
    private let twoFactorService: TwoFactorAuthServiceProtocol
    private let secret: String

    init(twoFactorService: TwoFactorAuthServiceProtocol, secret: String) {
        self.twoFactorService = twoFactorService
        self.secret = secret
    }

    func verifyCode() {
        let now = Date()
        if twoFactorService.validateTOTP(secret: secret, code: code, time: now) {
            error = nil
        } else {
            error = "Invalid code. Please try again."
        }
    }
}
