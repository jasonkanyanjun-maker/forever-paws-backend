//
//  KeychainService.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    private let service = "com.foreverpaws.app"
    
    // MARK: - Save Credentials
    func saveCredentials(email: String, password: String) -> Bool {
        let emailData = email.data(using: .utf8)!
        let passwordData = password.data(using: .utf8)!
        
        // Save email
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_email",
            kSecValueData as String: emailData
        ]
        
        // Delete existing email entry
        SecItemDelete(emailQuery as CFDictionary)
        
        // Add new email entry
        let emailStatus = SecItemAdd(emailQuery as CFDictionary, nil)
        
        // Save password
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_password",
            kSecValueData as String: passwordData
        ]
        
        // Delete existing password entry
        SecItemDelete(passwordQuery as CFDictionary)
        
        // Add new password entry
        let passwordStatus = SecItemAdd(passwordQuery as CFDictionary, nil)
        
        return emailStatus == errSecSuccess && passwordStatus == errSecSuccess
    }
    
    // MARK: - Load Credentials
    func loadCredentials() -> (email: String?, password: String?) {
        let email = loadEmail()
        let password = loadPassword()
        return (email, password)
    }
    
    private func loadEmail() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_email",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let email = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return email
    }
    
    private func loadPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_password",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    // MARK: - Delete Credentials
    func deleteCredentials() -> Bool {
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_email"
        ]
        
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_password"
        ]
        
        let emailStatus = SecItemDelete(emailQuery as CFDictionary)
        let passwordStatus = SecItemDelete(passwordQuery as CFDictionary)
        
        return (emailStatus == errSecSuccess || emailStatus == errSecItemNotFound) &&
               (passwordStatus == errSecSuccess || passwordStatus == errSecItemNotFound)
    }
    
    // MARK: - Save Access Token
    func saveAccessToken(_ token: String) -> Bool {
        let tokenData = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "access_token",
            kSecValueData as String: tokenData
        ]
        
        // Delete existing token
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Load Access Token
    func loadAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "access_token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    // MARK: - Delete Access Token
    func deleteAccessToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "access_token"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}