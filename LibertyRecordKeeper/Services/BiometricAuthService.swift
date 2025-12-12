//
//  BiometricAuthService.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import Foundation
import LocalAuthentication
import CryptoKit

enum BiometricAuthError: Error {
    case authenticationFailed
    case biometricsNotAvailable
    case keyGenerationFailed
    case keyRetrievalFailed
}

class BiometricAuthService {
    static let shared = BiometricAuthService()
    
    private let context = LAContext()
    private let keychain = KeychainService.shared
    
    private init() {}
    
    func canUseBiometrics() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticate() async throws -> SymmetricKey {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricAuthError.biometricsNotAvailable
        }
        
        let reason = "Authenticate to access your forensic records"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            if success {
                // Retrieve or generate encryption key
                return try await getOrCreateEncryptionKey()
            } else {
                throw BiometricAuthError.authenticationFailed
            }
        } catch {
            throw BiometricAuthError.authenticationFailed
        }
    }
    
    private func getOrCreateEncryptionKey() async throws -> SymmetricKey {
        // Try to retrieve existing key from keychain
        if let existingKey = try? keychain.retrieveEncryptionKey() {
            return existingKey
        }
        
        // Generate new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        try keychain.storeEncryptionKey(newKey)
        
        return newKey
    }
}

// MARK: - Keychain Service

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.libertyrecordkeeper.encryption"
    private let account = "database-encryption-key"
    
    private init() {}
    
    func storeEncryptionKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw BiometricAuthError.keyGenerationFailed
        }
    }
    
    func retrieveEncryptionKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw BiometricAuthError.keyRetrievalFailed
        }
        
        return SymmetricKey(data: keyData)
    }
    
    func deleteEncryptionKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
