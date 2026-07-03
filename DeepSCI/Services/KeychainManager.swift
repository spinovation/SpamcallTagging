import Foundation
import Security

public final class KeychainManager {
    public static let shared = KeychainManager()
    private let serviceName = "com.spamcalltagging.app"
    private let userIdKey = "pseudonymousUserId"
    
    private init() {}
    
    // Gets the existing pseudonymous user ID, or generates a new one if it doesn't exist
    public func getOrCreateUserId() -> String {
        if let existingId = fetchString(forKey: userIdKey) {
            return existingId
        }
        
        // Generate new pseudonymous ID (UUID format)
        let newId = UUID().uuidString
        saveString(newId, forKey: userIdKey)
        return newId
    }
    
    // MARK: - SecItem Helpers
    
    private func saveString(_ string: String, forKey key: String) {
        guard let data = string.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete first to avoid duplicates
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error status: \(status)")
        }
    }
    
    private func fetchString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
