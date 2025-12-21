// SetupTBAuthModel.swift
// Model for 2FA setup, holds state and logic for QR, code, and backup codes.

import Foundation

class SetupTBAuthModel {
    let service: SetupTBAuthServiceProtocol
    var secret: String
    var backupCodesEncrypted: Data?
    var account: String

    init(service: SetupTBAuthServiceProtocol, account: String) {
        self.service = service
        self.account = account
        self.secret = service.generateSecret()
    }

    func generateQRCodeURL() -> URL {
        service.generateQRCodeURL(secret: secret, account: account)
    }

    func validateTOTP(code: String, time: Date) -> Bool {
        service.validateTOTP(secret: secret, code: code, time: time)
    }

    func generateAndEncryptBackupCodes(with2FACode code: String) -> [String]? {
        let codes = service.generateBackupCodes()
        backupCodesEncrypted = service.encryptBackupCodes(codes, with2FACode: code)
        return codes
    }

    func decryptBackupCodes(with2FACode code: String) -> [String]? {
        guard let data = backupCodesEncrypted else { return nil }
        return service.decryptBackupCodes(data, with2FACode: code)
    }
}
