import Foundation
import SharedCoreModels

// MARK: - Shared Enums

// MARK: - Pattern Alert Models

/// Represents a pattern alert for trading signals
public struct PatternAlert: Identifiable {
    public var id: UUID
    public let patternType: PatternType
    public let symbol: String
    public let timeframe: String
    public let timestamp: Date
    public let confidence: Double
    public let signal: TradingSignal
    public let strength: PatternStrength
    public let urgency: AlertUrgency?

    public enum PatternType: String, CaseIterable {
        case recognition = "Recognition"
        case confluence = "Confluence"
        case reversal = "Reversal"
        case breakout = "Breakout"
    }

    public enum TradingSignal {
        case buy
        case sell
        case hold
        case strongBuy
        case strongSell
    }

    public enum PatternStrength {
        case weak
        case moderate
        case strong
        case veryStrong
    }

    public enum AlertUrgency: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        public var priority: Int {
            switch self {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }

    public init(
        id: UUID = UUID(),
        patternType: PatternType,
        symbol: String,
        timeframe: String,
        timestamp: Date,
        confidence: Double,
        signal: TradingSignal,
        strength: PatternStrength,
        urgency: AlertUrgency?
    ) {
        self.id = id
        self.patternType = patternType
        self.symbol = symbol
        self.timeframe = timeframe
        self.timestamp = timestamp
        self.confidence = confidence
        self.signal = signal
        self.strength = strength
        self.urgency = urgency
    }
}

// MARK: - Confluence Pattern Models

/// Represents a confluence of multiple patterns across different timeframes
public struct ConfluencePattern: Identifiable {
    public let id = UUID()
    public let patterns: [PatternResult]
    public let timeframes: [String]
    public let overallConfidence: Double
    public let signal: PatternAlert.TradingSignal
    public let strength: PatternAlert.PatternStrength
    public let timestamp: Date
    public let dominantPattern: String
    
    public struct PatternResult {
        public let pattern: String
        public let timeframe: String
        public let confidence: Double
        public let signal: PatternAlert.TradingSignal
        public let strength: PatternAlert.PatternStrength
        
        public init(
            pattern: String,
            timeframe: String,
            confidence: Double,
            signal: PatternAlert.TradingSignal,
            strength: PatternAlert.PatternStrength
        ) {
            self.pattern = pattern
            self.timeframe = timeframe
            self.confidence = confidence
            self.signal = signal
            self.strength = strength
        }
    }
    
    public init(
        patterns: [PatternResult],
        timeframes: [String],
        overallConfidence: Double,
        signal: PatternAlert.TradingSignal,
        strength: PatternAlert.PatternStrength,
        timestamp: Date,
        dominantPattern: String
    ) {
        self.patterns = patterns
        self.timeframes = timeframes
        self.overallConfidence = overallConfidence
        self.signal = signal
        self.strength = strength
        self.timestamp = timestamp
        self.dominantPattern = dominantPattern
    }
    
    public var confluenceScore: Double {
        let timeframeBonus = Double(timeframes.count) * 0.1
        let patternBonus = Double(patterns.count) * 0.05
        return min(overallConfidence + timeframeBonus + patternBonus, 1.0)
    }
}

// MARK: - Pattern Performance Models

/// Performance metrics for pattern analysis
/// Uses shared MarketRegime from CoreModels to avoid duplication
public struct PatternPerformance {
    // Common properties
    public let pattern: String
    public let timestamp: Date
    
    // For ML-based pattern recognition
    public let confidence: Double?
    public let marketRegime: MarketRegime?
    public let outcome: Bool? // true if profitable
    public let holdingPeriod: Int? // in minutes
    public let features: [Double]? // ML features used for prediction
    
    // For intraday pattern tracking
    public let totalTrades: Int?
    public let successfulTrades: Int?
    
    public init(
        pattern: String,
        timestamp: Date,
        confidence: Double?,
        marketRegime: MarketRegime?,
        outcome: Bool?,
        holdingPeriod: Int?,
        features: [Double]?,
        totalTrades: Int?,
        successfulTrades: Int?
    ) {
        self.pattern = pattern
        self.timestamp = timestamp
        self.confidence = confidence
        self.marketRegime = marketRegime
        self.outcome = outcome
        self.holdingPeriod = holdingPeriod
        self.features = features
        self.totalTrades = totalTrades
        self.successfulTrades = successfulTrades
    }
}
