// SecureServiceConnection.swift
// Defines a protocol for secure, industrial-grade service connections akin to Twitch.tv's security model.
// This protocol assumes all network traffic is encrypted (TLS), uses strong authentication (OAuth2 or similar), and is resistant to interception.

import Foundation

/// Protocol for secure service connections, suitable for industrial-grade security requirements.
protocol SecureServiceConnection {
    /// Initiates a secure connection to the service.
    /// - Parameter completion: Called with success or error upon connection attempt.
    func connect(completion: @escaping (Result<Void, Error>) -> Void)

    /// Authenticates the client using OAuth2 or a similar secure method.
    /// - Parameters:
    ///   - credentials: The credentials or token required for authentication.
    ///   - completion: Called with success or error upon authentication attempt.
    func authenticate(with credentials: String, completion: @escaping (Result<Void, Error>) -> Void)

    /// Sends encrypted data to the service.
    /// - Parameters:
    ///   - data: The data to send (should be encrypted at rest and in transit).
    ///   - completion: Called with success or error upon send attempt.
    func sendEncryptedData(_ data: Data, completion: @escaping (Result<Void, Error>) -> Void)

    /// Disconnects securely from the service.
    func disconnect()
}

// Note: Implementations of this protocol must ensure:
// - All network traffic uses TLS 1.3 or higher.
// - Authentication uses OAuth2, mutual TLS, or equivalent.
// - All sensitive data is encrypted in transit and at rest.
// - No credentials or tokens are ever logged or exposed.
// - All error handling avoids leaking sensitive information.
