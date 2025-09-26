import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case unexpectedStatus(OSStatus)
    case dataConversionError
    case environmentRestriction
    case simulatorRestriction
    
    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            let message: String
            switch status {
            case errSecDuplicateItem:
                message = "Item already exists in keychain (errSecDuplicateItem)"
            case errSecItemNotFound:
                message = "Item not found in keychain (errSecItemNotFound)"
            case errSecAuthFailed:
                message = "Authentication failed (errSecAuthFailed)"
            case errSecDecode:
                message = "Decode error (errSecDecode)"
            case errSecNotAvailable:
                message = "Keychain not available (errSecNotAvailable)"
            case errSecInteractionNotAllowed:
                message = "Interaction not allowed (errSecInteractionNotAllowed)"
            case errSecParam:
                message = "Invalid parameter (errSecParam)"
            case errSecUserCanceled:
                message = "User canceled the operation (errSecUserCanceled)"
            case errSecBadReq:
                message = "Bad request (errSecBadReq)"
            case errSecMissingEntitlement:
                message = "Missing entitlement (errSecMissingEntitlement)"
            default:
                message = "Unknown error"
            }
            return "Keychain error: \(status) - \(message)"
        case .dataConversionError:
            return "Failed to convert string to data"
        case .environmentRestriction:
            return "Keychain access restricted in this environment"
        case .simulatorRestriction:
            return "Keychain has limitations in the simulator"
        }
    }
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    
    // Flag to track if we're running in a simulator
    private let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()
    
    // Flag to track if we've had persistent keychain failures
    private var hasKeychainFailed = false
    
    private init() {
        // Check if we're in a simulator and log a warning
        if isSimulator {
            #if DEBUG
            print("⚠️ KeychainHelper initialized in simulator environment. Some keychain operations may fail.")
            #endif
        }
    }
    
    // For debugging purposes
    private func logKeychainError(_ status: OSStatus, operation: String, key: String) {
        #if DEBUG
        print("🔑 Keychain \(operation) failed for key '\(key)' with status: \(status)")
        switch status {
        case errSecDuplicateItem:
            print("  - Item already exists (errSecDuplicateItem)")
        case errSecItemNotFound:
            print("  - Item not found (errSecItemNotFound)")
        case errSecAuthFailed:
            print("  - Authentication failed (errSecAuthFailed)")
        case errSecDecode:
            print("  - Decode error (errSecDecode)")
        case errSecNotAvailable:
            print("  - Keychain not available (errSecNotAvailable)")
        case errSecInteractionNotAllowed:
            print("  - Interaction not allowed (errSecInteractionNotAllowed)")
        case errSecParam:
            print("  - Invalid parameter (errSecParam)")
        case errSecUserCanceled:
            print("  - User canceled the operation (errSecUserCanceled)")
        case errSecBadReq:
            print("  - Bad request (errSecBadReq)")
        case errSecMissingEntitlement:
            print("  - Missing entitlement (errSecMissingEntitlement)")
        default:
            print("  - Unknown error code: \(status)")
        }
        
        // Mark keychain as failed if we encounter serious errors
        if status == errSecNotAvailable || 
           status == errSecMissingEntitlement || 
           status == errSecInteractionNotAllowed {
            hasKeychainFailed = true
            print("⚠️ Marking keychain as persistently unavailable - will use fallbacks for future operations")
        }
        #endif
    }

    @discardableResult
    func save(_ value: String, forKey key: String) throws -> Bool {
        // Skip keychain if we've had persistent failures
        if hasKeychainFailed {
            throw KeychainError.environmentRestriction
        }
        
        // Check for simulator environment
        if isSimulator {
            #if DEBUG
            print("⚠️ Attempting keychain operation in simulator for key: \(key)")
            #endif
        }
        
        guard let data = value.data(using: .utf8) else { 
            throw KeychainError.dataConversionError
        }

        // Don't delete existing item - instead try to add first, then update if needed
        // This reduces the number of keychain operations
        
        // Use more robust keychain query with accessibility and access control
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.example.iOS-Trading-App",
            kSecAttrSynchronizable as String: false
        ]

        // Try to add the item
        var status = SecItemAdd(query as CFDictionary, nil)
        
        // If item already exists, try to update it
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.example.iOS-Trading-App"
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        }
        
        // Handle the result
        if status != errSecSuccess {
            logKeychainError(status, operation: "save/update", key: key)
            
            // Special handling for simulator and restricted environments
            if isSimulator && (status == errSecNotAvailable || status == errSecMissingEntitlement) {
                throw KeychainError.simulatorRestriction
            }
            
            throw KeychainError.unexpectedStatus(status)
        }
        
        return true
    }

    func read(_ key: String) -> String? {
        // Skip keychain if we've had persistent failures
        if hasKeychainFailed {
            #if DEBUG
            print("🔑 Skipping keychain read due to previous failures, key: \(key)")
            #endif
            return nil
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.example.iOS-Trading-App",
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status != errSecSuccess {
            if status != errSecItemNotFound {
                logKeychainError(status, operation: "read", key: key)
                
                // Special handling for simulator
                if isSimulator && (status == errSecNotAvailable || status == errSecMissingEntitlement) {
                    #if DEBUG
                    print("⚠️ Keychain read failed in simulator environment")
                    #endif
                }
            }
            return nil
        }
        
        guard let data = item as? Data else { 
            #if DEBUG
            print("⚠️ Failed to convert keychain item to Data for key: \(key)")
            #endif
            return nil 
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            #if DEBUG
            print("⚠️ Failed to convert Data to String for key: \(key)")
            #endif
            return nil
        }
        
        return string
    }

    func delete(_ key: String) {
        // Skip keychain if we've had persistent failures
        if hasKeychainFailed {
            #if DEBUG
            print("🔑 Skipping keychain delete due to previous failures, key: \(key)")
            #endif
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.example.iOS-Trading-App"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logKeychainError(status, operation: "delete", key: key)
        }
    }
    
    // Fallback to UserDefaults if keychain fails
    func saveWithFallback(_ value: String, forKey key: String) -> Bool {
        // If we already know keychain has failed, go straight to fallback
        if hasKeychainFailed || isSimulator {
            #if DEBUG
            print("🔑 Using UserDefaults directly due to known keychain limitations for key: \(key)")
            #endif
            
            // Use UserDefaults as fallback with encryption if possible
            let fallbackKey = "kc_fallback_\(key)"
            UserDefaults.standard.set(value, forKey: fallbackKey)
            
            // Store a timestamp to track when this value was saved
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(fallbackKey)_timestamp")
            return true
        }
        
        // Try keychain first
        do {
            return try save(value, forKey: key)
        } catch {
            #if DEBUG
            print("🔑 Keychain save failed, using UserDefaults fallback for key: \(key)")
            print("   Error: \(error.localizedDescription)")
            #endif
            
            // Use UserDefaults as fallback
            let fallbackKey = "kc_fallback_\(key)"
            UserDefaults.standard.set(value, forKey: fallbackKey)
            
            // Store a timestamp to track when this value was saved
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(fallbackKey)_timestamp")
            
            // If this is a simulator restriction or environment restriction, mark keychain as failed
            if let keychainError = error as? KeychainError {
                if case .simulatorRestriction = keychainError {
                    hasKeychainFailed = true
                } else if case .environmentRestriction = keychainError {
                    hasKeychainFailed = true
                }
            }
            
            return true
        }
    }
    
    func readWithFallback(_ key: String) -> String? {
        // If we already know keychain has failed, go straight to fallback
        if hasKeychainFailed || isSimulator {
            #if DEBUG
            print("🔑 Reading directly from UserDefaults due to known keychain limitations for key: \(key)")
            #endif
            return UserDefaults.standard.string(forKey: "kc_fallback_\(key)")
        }
        
        // Try keychain first
        if let value = read(key) {
            return value
        }
        
        // Fall back to UserDefaults
        let fallbackValue = UserDefaults.standard.string(forKey: "kc_fallback_\(key)")
        
        #if DEBUG
        if fallbackValue != nil {
            print("🔑 Retrieved value from UserDefaults fallback for key: \(key)")
        }
        #endif
        
        return fallbackValue
    }
    
    // Clear all stored credentials (both keychain and fallback)
    func clearAllCredentials() {
        // List of all credential keys
        let credentialKeys = ["ZerodhaAPIKey", "ZerodhaAPISecret", "ZerodhaRedirectURL", "ZerodhaAccessToken", "NewsAPIKey"]
        
        // Clear from keychain
        for key in credentialKeys {
            delete(key)
            
            // Also clear from UserDefaults
            let fallbackKey = "kc_fallback_\(key)"
            UserDefaults.standard.removeObject(forKey: fallbackKey)
            UserDefaults.standard.removeObject(forKey: "\(fallbackKey)_timestamp")
        }
        
        // Reset the keychain failure flag
        hasKeychainFailed = false
        
        #if DEBUG
        print("🔑 All credentials cleared from both keychain and UserDefaults")
        #endif
    }
}