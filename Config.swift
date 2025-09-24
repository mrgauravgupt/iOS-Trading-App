import Foundation

struct Config {
    static let newsAPIKey = "90509892e0ac4720b91120f917c25dd7" // Replace with actual key
    static let apiBaseURL = "https://api.kite.trade" // Zerodha API base URL
    static let isDebug = true

    // MARK: - Zerodha Credentials (Keychain-first)
    static func zerodhaAPIKey() -> String {
        KeychainHelper.shared.read("ZerodhaAPIKey") ?? ""
    }

    static func zerodhaAccessToken() -> String {
        KeychainHelper.shared.read("ZerodhaAccessToken") ?? ""
    }

    static func validateAPIKeys() -> Bool {
        let news = KeychainHelper.shared.read("NewsAPIKey") ?? newsAPIKey
        let apiKey = zerodhaAPIKey()
        let access = zerodhaAccessToken()
        return !news.isEmpty && !apiKey.isEmpty && !access.isEmpty
    }

    // MARK: - Zerodha Secret and Redirect URL
    static func zerodhaAPISecret() -> String {
        KeychainHelper.shared.read("ZerodhaAPISecret") ?? ""
    }

    static func zerodhaRedirectURL() -> String {
        // Must match the Redirect URL configured in Zerodha console
        KeychainHelper.shared.read("ZerodhaRedirectURL") ?? "https://yourapp.com/kite-redirect"
    }
}
