import Foundation

class DataValidator {
    static let shared = DataValidator()

    func validateMarketData(_ data: MarketData) -> Bool {
        return data.price > 0 && data.volume >= 0 && data.symbol.count > 0
    }

    func handleError(_ error: Error) {
        print("Error handled: \(error.localizedDescription)")
        // Placeholder for error handling logic
    }
}
