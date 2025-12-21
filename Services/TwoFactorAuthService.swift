// TwoFactorAuthService.swift
// Handles time-based two-factor authentication (2FA) using TOTP, compatible with Microsoft Authenticator.

import Foundation
import CryptoKit

protocol TwoFactorAuthServiceProtocol {
    /// Generates a TOTP code for the given secret and current time.
    func generateTOTP(secret: String, time: Date) -> String
    /// Validates a TOTP code for the given secret and current time.
    func validateTOTP(secret: String, code: String, time: Date) -> Bool
}

class TwoFactorAuthService: TwoFactorAuthServiceProtocol {
    private let timeStep: TimeInterval = 30 // 30 seconds per TOTP step
    private let digits = 6

    func generateTOTP(secret: String, time: Date) -> String {
        let counter = UInt64(time.timeIntervalSince1970 / timeStep)
        let keyData = Data(base64Encoded: secret) ?? Data()
        var counterData = withUnsafeBytes(of: counter.bigEndian, Array.init)
        let hash = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: SymmetricKey(data: keyData))
        let offset = Int(hash.last! & 0x0f)
        let truncatedHash = hash[offset..<offset+4]
        var codeInt = truncatedHash.reduce(0) { ($0 << 8) | UInt32($1) }
        codeInt &= 0x7fffffff
        codeInt = codeInt % UInt32(pow(10, Float(digits)))
        return String(format: "%0*u", digits, codeInt)
    }

    func validateTOTP(secret: String, code: String, time: Date) -> Bool {
        let generated = generateTOTP(secret: secret, time: time)
        return generated == code
    }
}
