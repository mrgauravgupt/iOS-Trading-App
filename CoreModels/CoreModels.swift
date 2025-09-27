import Foundation

// MARK: - Core Trading Models

/// Risk metrics for trading
public struct RiskMetrics: Codable {
    public let var95: Double
    public let var99: Double
    public let expectedShortfall: Double
    public let maxDrawdown: Double
    public let sharpeRatio: Double
    public let sortinoRatio: Double
    public let beta: Double
    public let alpha: Double
    public let timestamp: Date
    
    public init(
        var95: Double,
        var99: Double,
        expectedShortfall: Double,
        maxDrawdown: Double,
        sharpeRatio: Double,
        sortinoRatio: Double,
        beta: Double,
        alpha: Double,
        timestamp: Date = Date()
    ) {
        self.var95 = var95
        self.var99 = var99
        self.expectedShortfall = expectedShortfall
        self.maxDrawdown = maxDrawdown
        self.sharpeRatio = sharpeRatio
        self.sortinoRatio = sortinoRatio
        self.beta = beta
        self.alpha = alpha
        self.timestamp = timestamp
    }
}

/// Market regime classification
public enum MarketRegime: String, Codable {
    case trending = "Trending"
    case ranging = "Ranging"
    case volatile = "Volatile"
    case quiet = "Quiet"
    case breakout = "Breakout"
    case reversal = "Reversal"
}

/// Volatility environment classification
public enum VolatilityEnvironment: String, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case extreme = "Extreme"
}

/// Trend direction
public enum TrendDirection: String, Codable {
    case bullish = "Bullish"
    case bearish = "Bearish"
    case neutral = "Neutral"
    case strongBullish = "Strong Bullish"
    case strongBearish = "Strong Bearish"
}
