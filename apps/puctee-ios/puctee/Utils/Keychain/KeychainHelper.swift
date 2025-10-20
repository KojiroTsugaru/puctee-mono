//
//  KeychainHelper.swift
//  puctee
//
//  Created by kj on 5/12/25.
//

import Foundation
import Security

/// Helper class to simplify saving, retrieving, and deleting from the Keychain
final class KeychainHelper {
  static let standard = KeychainHelper()
  private init() {}
  
  /// Save Data type to Keychain
  func save(_ data: Data, service: String, account: String) {
    // 1. Delete existing item (for overwriting)
    let queryDelete: [String: Any] = [
      kSecClass as String       : kSecClassGenericPassword,
      kSecAttrService as String : service,
      kSecAttrAccount as String : account
    ]
    SecItemDelete(queryDelete as CFDictionary)
    
    // 2. Save new
    let queryAdd: [String: Any] = [
      kSecClass as String       : kSecClassGenericPassword,
      kSecAttrService as String : service,
      kSecAttrAccount as String : account,
      kSecValueData as String   : data
    ]
    let status = SecItemAdd(queryAdd as CFDictionary, nil)
    guard status == errSecSuccess else {
      print("Keychain Save Error: \(status)")
      return
    }
  }
  
  /// Read Data type from Keychain
  func read(service: String, account: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String         : kSecClassGenericPassword,
      kSecAttrService as String   : service,
      kSecAttrAccount as String   : account,
      kSecReturnData as String    : true,
      kSecMatchLimit as String    : kSecMatchLimitOne
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess else {
      print("Keychain Read Error: \(status)")
      return nil
    }
    return result as? Data
  }
  
  /// Delete item from Keychain
  func delete(service: String, account: String) {
    let query: [String: Any] = [
      kSecClass as String       : kSecClassGenericPassword,
      kSecAttrService as String : service,
      kSecAttrAccount as String : account
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      print("Keychain Delete Error: \(status)")
      return
    }
  }
}

// MARK: - Convenience for String
extension KeychainHelper {
  /// Save String
  func saveStr(_ string: String, service: String, account: String) {
    guard let data = string.data(using: .utf8) else { return }
    save(data, service: service, account: account)
  }
  
  /// Read String
  func readStr(service: String, account: String) -> String? {
    guard let data = read(service: service, account: account) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}

// MARK: - Date helper
extension KeychainHelper {
  /// Convert Date to TimeInterval (Double) and save to Keychain
  func saveDate(_ date: Date, service: String, account: String) {
    let timestamp = date.timeIntervalSince1970
    let str = String(timestamp)
    saveStr(str, service: service, account: account)
  }
  
  /// Parse the string read from Keychain into a Double to restore the Date
  func readDate(service: String, account: String) -> Date? {
    guard
      let str = readStr(service: service, account: account),
      let ts  = TimeInterval(str)
    else {
      return nil
    }
    return Date(timeIntervalSince1970: ts)
  }
}
