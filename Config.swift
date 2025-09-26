import Foundation

struct Config {
    static let newsAPIKey = "90509892e0ac4720b91120f917c25dd7" // Replace with actual key
    static let apiBaseURL = "https://api.kite.trade" // Zerodha API base URL
    static let isDebug = true

    // MARK: - Zerodha Credentials (Keychain-first with fallback)
    static func zerodhaAPIKey() -> String {
        KeychainHelper.shared.readWithFallback("ZerodhaAPIKey") ?? ""
    }

    static func zerodhaAccessToken() -> String {
        KeychainHelper.shared.readWithFallback("ZerodhaAccessToken") ?? ""
    }

    static func validateAPIKeys() -> Bool {
        let news = KeychainHelper.shared.readWithFallback("NewsAPIKey") ?? newsAPIKey
        let apiKey = zerodhaAPIKey()
        let access = zerodhaAccessToken()
        return !news.isEmpty && !apiKey.isEmpty && !access.isEmpty
    }

    // MARK: - Zerodha Secret and Redirect URL
    static func zerodhaAPISecret() -> String {
        KeychainHelper.shared.readWithFallback("ZerodhaAPISecret") ?? ""
    }

    static func zerodhaRedirectURL() -> String {
        // Must match the Redirect URL configured in Zerodha console
        KeychainHelper.shared.readWithFallback("ZerodhaRedirectURL") ?? "https://trading-app.com/kite-redirect"
    }
}
