// SetupTBAuthService.swift
// Handles QR code generation, TOTP validation, and secure backup code management for 2FA setup.

import Foundation
import CryptoKit

protocol SetupTBAuthServiceProtocol {
    func generateSecret() -> String
    func generateQRCodeURL(secret: String, account: String) -> URL
    func validateTOTP(secret: String, code: String, time: Date) -> Bool
    func generateBackupCodes() -> [String]
    func encryptBackupCodes(_ codes: [String], with2FACode code: String) -> Data?
    func decryptBackupCodes(_ data: Data, with2FACode code: String) -> [String]?
}

class SetupTBAuthService: SetupTBAuthServiceProtocol {
    private let digits = 6
    private let timeStep: TimeInterval = 30
    private let backupCodeCount = 12

    func generateSecret() -> String {
        let secretData = Data((0..<20).map { _ in UInt8.random(in: 0...255) })
        return secretData.base64EncodedString()
    }

    func generateQRCodeURL(secret: String, account: String) -> URL {
        let urlString = "otpauth://totp/RecordKeeper:\(account)?secret=\(secret)&issuer=RecordKeeper"
        return URL(string: urlString) ?? URL(fileURLWithPath: "/")
    }

    func validateTOTP(secret: String, code: String, time: Date) -> Bool {
        // Use the same TOTP logic as TwoFactorAuthService
        let counter = UInt64(time.timeIntervalSince1970 / timeStep)
        let keyData = Data(base64Encoded: secret) ?? Data()
        var counterData = withUnsafeBytes(of: counter.bigEndian, Array.init)
        let hash = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: SymmetricKey(data: keyData))
        let offset = Int(hash.last! & 0x0f)
        let truncatedHash = hash[offset..<offset+4]
        var codeInt = truncatedHash.reduce(0) { ($0 << 8) | UInt32($1) }
        codeInt &= 0x7fffffff
        codeInt = codeInt % UInt32(pow(10, Float(digits)))
        let generated = String(format: "%0*u", digits, codeInt)
        return generated == code
    }

    func generateBackupCodes() -> [String] {
        (0..<backupCodeCount).map { _ in
            String(format: "%08d", Int.random(in: 10000000...99999999))
        }
    }

    func encryptBackupCodes(_ codes: [String], with2FACode code: String) -> Data? {
        let joined = codes.joined(separator: ",")
        guard let keyData = code.data(using: .utf8) else { return nil }
        let key = SymmetricKey(data: SHA256.hash(data: keyData))
        let sealed = try? ChaChaPoly.seal(joined.data(using: .utf8)!, using: key)
        return sealed?.combined
    }

    func decryptBackupCodes(_ data: Data, with2FACode code: String) -> [String]? {
        guard let keyData = code.data(using: .utf8) else { return nil }
        let key = SymmetricKey(data: SHA256.hash(data: keyData))
        guard let box = try? ChaChaPoly.SealedBox(combined: data),
              let decrypted = try? ChaChaPoly.open(box, using: key),
              let string = String(data: decrypted, encoding: .utf8) else { return nil }
        return string.components(separatedBy: ",")
    }
}
