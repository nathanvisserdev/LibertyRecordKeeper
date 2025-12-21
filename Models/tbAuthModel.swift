// tbAuthModel.swift
// Model for time-based authentication, injected with SecureServiceConnection implementation.

import Foundation

class tbAuthModel {
    private let serviceConnection: SecureServiceConnection
    private let twoFactorService: TwoFactorAuthServiceProtocol
    private let secret: String

    init(serviceConnection: SecureServiceConnection, twoFactorService: TwoFactorAuthServiceProtocol, secret: String) {
        self.serviceConnection = serviceConnection
        self.twoFactorService = twoFactorService
        self.secret = secret
    }

    func authenticateWith2FA(code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let now = Date()
        if twoFactorService.validateTOTP(secret: secret, code: code, time: now) {
            serviceConnection.authenticate(with: code, completion: completion)
        } else {
            completion(.failure(NSError(domain: "2FA", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid 2FA code."])) )
        }
    }
}
