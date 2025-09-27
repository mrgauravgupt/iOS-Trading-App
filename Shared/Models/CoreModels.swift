import Foundation

// MARK: - Core Trading Models

/// Option type for Indian markets with specific CE/PE notation
public enum OptionType: String, Codable, CaseIterable {
    case call = "CE"
    case put = "PE"
    
    /// Alternative representation for compatibility
    public var standardType: String {
        switch self {
        case .call: return "call"
        case .put: return "put"
        }
    }
}

/// Trade action types
public enum TradeAction: String, Codable, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
    case hold = "HOLD"
    
    public var displayName: String {
        return self.rawValue.capitalized
    }
}

/// Market sentiment analysis - consolidated version
public struct SentimentAnalysis: Codable {
    // Options-based sentiment (from SharedModels)
    public let putCallRatio: Double?
    public let oiPutCallRatio: Double?
    public let volatilitySkew: Double?
    public let sentimentScore: Double
    public let marketSentiment: MarketSentiment?
    
    // News-based sentiment (from ContinuousLearningManager)
    public let keywords: [String]?
    public let sources: [String]?
    
    public enum MarketSentiment: String, Codable {
        case bullish = "Bullish"
        case bearish = "Bearish"
        case neutral = "Neutral"
        case extremeBullish = "Extreme Bullish"
        case extremeBearish = "Extreme Bearish"
    }
    
    public init(
        putCallRatio: Double? = nil,
        oiPutCallRatio: Double? = nil,
        volatilitySkew: Double? = nil,
        sentimentScore: Double,
        marketSentiment: MarketSentiment? = nil,
        keywords: [String]? = nil,
        sources: [String]? = nil
    ) {
        self.putCallRatio = putCallRatio
        self.oiPutCallRatio = oiPutCallRatio
        self.volatilitySkew = volatilitySkew
        self.sentimentScore = sentimentScore
        self.marketSentiment = marketSentiment
        self.keywords = keywords
        self.sources = sources
    }
}

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

/// Timeframe enumeration for consistency across the app
public enum Timeframe: String, Codable, CaseIterable {
    case oneMinute = "1m"
    case fiveMinute = "5m"
    case fifteenMinute = "15m"
    case thirtyMinute = "30m"
    case oneHour = "1h"
    case fourHour = "4h"
    case oneDay = "1d"
    
    public var displayName: String {
        switch self {
        case .oneMinute: return "1 Min"
        case .fiveMinute: return "5 Min"
        case .fifteenMinute: return "15 Min"
        case .thirtyMinute: return "30 Min"
        case .oneHour: return "1 Hour"
        case .fourHour: return "4 Hour"
        case .oneDay: return "1 Day"
        }
    }
    
    public var seconds: Int {
        switch self {
        case .oneMinute: return 60
        case .fiveMinute: return 300
        case .fifteenMinute: return 900
        case .thirtyMinute: return 1800
        case .oneHour: return 3600
        case .fourHour: return 14400
        case .oneDay: return 86400
        }
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