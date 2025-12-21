// SetupTBAuthViewModel.swift
// ViewModel for SetupTBAuthView, manages QR, code entry, backup codes, and secure notification.

import Foundation
import Combine

class SetupTBAuthViewModel: ObservableObject {
    @Published var qrCodeURL: URL?
    @Published var code: String = ""
    @Published var isCodeValid: Bool = false
    @Published var backupCodes: [String]? = nil
    @Published var showBackupCodes: Bool = false
    @Published var showSecureNotice: Bool = false
    @Published var error: String? = nil

    private let model: SetupTBAuthModel
    private var cancellables = Set<AnyCancellable>()

    init(model: SetupTBAuthModel) {
        self.model = model
        self.qrCodeURL = model.generateQRCodeURL()
    }

    func verifyCode() {
        let now = Date()
        if model.validateTOTP(code: code, time: now) {
            isCodeValid = true
            backupCodes = model.generateAndEncryptBackupCodes(with2FACode: code)
            showBackupCodes = true
            showSecureNotice = true
            error = nil
        } else {
            isCodeValid = false
            error = "Invalid code. Please try again."
        }
    }

    func acknowledgeBackupCodes() {
        showSecureNotice = false
    }
}
