//
//  KeychainHelper.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 15/05/25.
//

import Foundation
import Security

struct KeychainHelper {
    static func save(account: String, service: String, value: String) -> Bool {
            guard let data = value.data(using: .utf8) else { return false }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecAttrService as String: service
            ]
            SecItemDelete(query as CFDictionary)

            let attributes: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecAttrService as String: service,
                kSecValueData as String: data
            ]
            let status = SecItemAdd(attributes as CFDictionary, nil)
            return status == errSecSuccess
        }
    
    static func retrieveUsername(forService service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let item = result as? [String: Any],
           let account = item[kSecAttrAccount as String] as? String {
            return account
        }
        return nil
    }
        static func retrieve(account: String, service: String) -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecAttrService as String: service,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

            if status == errSecSuccess,
               let data = dataTypeRef as? Data,
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return nil
        }

        static func delete(account: String, service: String) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecAttrService as String: service
            ]
            SecItemDelete(query as CFDictionary)
        }
}
