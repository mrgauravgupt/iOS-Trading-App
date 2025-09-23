import Foundation

struct Config {
    static let newsAPIKey = "90509892e0ac4720b91120f917c25dd7" // Replace with actual key
    static let zerodhaAPIKey = "fvpyc7zxx9jsz680" // Placeholder for Zerodha
    static let apiBaseURL = "https://api.kite.trade" // Zerodha API base URL
    static let isDebug = true

    static func validateAPIKeys() -> Bool {
        return !newsAPIKey.isEmpty && !zerodhaAPIKey.isEmpty
    }
}
