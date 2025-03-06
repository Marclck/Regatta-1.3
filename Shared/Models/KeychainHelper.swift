//
//  KeychainHelper.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 10/02/2025.
//

import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case notFound
}

class KeychainHelper {
    static let shared = KeychainHelper()
    private let service = "com.astrolabe.trial"
    
    private init() {}
    
    func save(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(data, key: key)
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    func update(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func read(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.notFound
        }
        
        guard let data = result as? Data else {
            throw KeychainError.unknown(errSecInternalError)
        }
        
        return data
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    // Convenience methods for storing trial status
    func setHasUsedUltraTrial(_ value: Bool) {
        do {
            let data = Data([value ? 1 : 0])
            try save(data, key: "hasUsedProUltraTrial")
        } catch {
            print("Failed to save trial status to Keychain: \(error)")
        }
    }
    
    func hasUsedUltraTrial() -> Bool {
        do {
            let data = try read(key: "hasUsedProUltraTrial")
            return data.first == 1
        } catch {
            return false // If not found, assume trial hasn't been used
        }
    }
}
