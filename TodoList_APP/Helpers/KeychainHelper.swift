//
//  KeychainHelper.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/13/25.
//

import Foundation
import Security

class KeychainHelper {
    
    static let shared = KeychainHelper()
    private init() {}
    
    // Save data to Keychain
    func save(_ data: Data, service: String, account: String) {
        // Delete existing item if it exists
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let attributes: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save failed with status: \(status)")
        }
    }
    
    // Read data from Keychain
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            return item as? Data
        } else {
            print("Keychain read failed with status: \(status)")
            return nil
        }
    }
    
    // Delete data from Keychain
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
