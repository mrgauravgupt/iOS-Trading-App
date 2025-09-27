import Foundation

/// Configuration constants for market data and trading parameters
struct MarketDataConfig {
    // MARK: - Default Market Values
    static let defaultNIFTYSpotPrice: Double = 18500.0
    static let defaultVIXLevel: Double = 15.0
    static let defaultVolatility: Double = 0.20
    static let niftyStrikeInterval: Double = 50.0
    static let defaultLotSize: Int = 50
    static let defaultExpiryDays: Int = 30

    // MARK: - Realistic Data Ranges
    static let volatilityRange: ClosedRange<Double> = 0.15...0.25
    static let vixRange: ClosedRange<Double> = 13.0...17.0
    static let strikeRange: ClosedRange<Int> = -10...10 // +/- 10 strikes from ATM

    // Dynamic spot price range based on current NIFTY value (-200 to +200)
    static func spotPriceRange(for currentNIFTY: Double) -> ClosedRange<Double> {
        let lowerBound = currentNIFTY - 200.0
        let upperBound = currentNIFTY + 200.0
        return lowerBound...upperBound
    }

    // MARK: - AI Model Parameters
    static let defaultAccuracy: Double = 0.65
    static let accuracyRange: ClosedRange<Double> = 0.55...0.75
    static let confidenceRange: ClosedRange<Double> = 0.60...0.85
    static let learningRate: Double = 0.001
    static let explorationRate: Double = 0.1

    // MARK: - Risk Management Defaults
    static let defaultVaR95: Double = 25000.0
    static let defaultVaR99: Double = 45000.0
    static let defaultVaR999: Double = 75000.0
    static let defaultExpectedShortfall: Double = 55000.0
    static let defaultDailyLossLimit: Double = 15000.0
    static let defaultPortfolioVaRLimit: Double = 35000.0

    // MARK: - Pattern Recognition Defaults
    static let bullishEngulfingAccuracy: Double = 0.68
    static let bearishEngulfingAccuracy: Double = 0.72
    static let doubleBottomAccuracy: Double = 0.61
    static let headShouldersAccuracy: Double = 0.75

    // MARK: - Utility Functions
    static func getRealisticSpotPrice(currentNIFTY: Double = 24500.0) -> Double {
        let range = spotPriceRange(for: currentNIFTY)
        return Double.random(in: range)
    }

    static func getRealisticVolatility() -> Double {
        return Double.random(in: volatilityRange)
    }

    static func getRealisticVIX() -> Double {
        return Double.random(in: vixRange)
    }

    static func getRealisticAccuracy() -> Double {
        return Double.random(in: accuracyRange)
    }

    static func getRealisticConfidence() -> Double {
        return Double.random(in: confidenceRange)
    }
}
