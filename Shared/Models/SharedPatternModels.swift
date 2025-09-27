import Foundation

// MARK: - Pattern Recognition Models

/// Represents a detected chart pattern
public struct ChartPattern: Identifiable, Codable {
    public var id = UUID()
    public let type: PatternType
    public let startIndex: Int
    public let endIndex: Int
    public let confidence: Double
    public let predictedDirection: TrendDirection
    public let timestamp: Date
    
    public init(
        type: PatternType,
        startIndex: Int,
        endIndex: Int,
        confidence: Double,
        predictedDirection: TrendDirection,
        timestamp: Date = Date()
    ) {
        self.type = type
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.confidence = confidence
        self.predictedDirection = predictedDirection
        self.timestamp = timestamp
    }
}

/// Types of chart patterns
public enum PatternType: String, Codable, CaseIterable {
    case headAndShoulders = "Head and Shoulders"
    case inverseHeadAndShoulders = "Inverse Head and Shoulders"
    case doubleTop = "Double Top"
    case doubleBottom = "Double Bottom"
    case tripleTop = "Triple Top"
    case tripleBottom = "Triple Bottom"
    case ascendingTriangle = "Ascending Triangle"
    case descendingTriangle = "Descending Triangle"
    case symmetricalTriangle = "Symmetrical Triangle"
    case bullishFlag = "Bullish Flag"
    case bearishFlag = "Bearish Flag"
    case bullishPennant = "Bullish Pennant"
    case bearishPennant = "Bearish Pennant"
    case cupAndHandle = "Cup and Handle"
    case inverseCupAndHandle = "Inverse Cup and Handle"
    case bullishRectangle = "Bullish Rectangle"
    case bearishRectangle = "Bearish Rectangle"
    case wedgeUp = "Rising Wedge"
    case wedgeDown = "Falling Wedge"
    case roundingBottom = "Rounding Bottom"
    case roundingTop = "Rounding Top"
    
    public var isReversalPattern: Bool {
        switch self {
        case .headAndShoulders, .inverseHeadAndShoulders, 
             .doubleTop, .doubleBottom, 
             .tripleTop, .tripleBottom,
             .roundingBottom, .roundingTop:
            return true
        default:
            return false
        }
    }
    
    public var isContinuationPattern: Bool {
        switch self {
        case .bullishFlag, .bearishFlag,
             .bullishPennant, .bearishPennant,
             .bullishRectangle, .bearishRectangle:
            return true
        default:
            return false
        }
    }
    
    public var expectedDirection: TrendDirection? {
        switch self {
        case .inverseHeadAndShoulders, .doubleBottom, .tripleBottom,
             .ascendingTriangle, .bullishFlag, .bullishPennant,
             .cupAndHandle, .bullishRectangle, .wedgeDown, .roundingBottom:
            return .bullish
        case .headAndShoulders, .doubleTop, .tripleTop,
             .descendingTriangle, .bearishFlag, .bearishPennant,
             .inverseCupAndHandle, .bearishRectangle, .wedgeUp, .roundingTop:
            return .bearish
        case .symmetricalTriangle:
            return nil // Can break either way
        }
    }
}

/// Pattern detection result
public struct PatternDetectionResult: Codable {
    public let patterns: [ChartPattern]
    public let timestamp: Date
    public let symbol: String
    public let timeframe: Timeframe
    
    public init(
        patterns: [ChartPattern] = [],
        timestamp: Date = Date(),
        symbol: String = "",
        timeframe: Timeframe = .oneDay
    ) {
        self.patterns = patterns
        self.timestamp = timestamp
        self.symbol = symbol
        self.timeframe = timeframe
    }
}

/// Pattern scanner configuration
public struct PatternScannerConfig: Codable {
    public var enabledPatterns: [PatternType]
    public var minConfidence: Double
    public var lookbackPeriod: Int
    public var timeframes: [Timeframe]
    
    public init(
        enabledPatterns: [PatternType] = PatternType.allCases,
        minConfidence: Double = 0.7,
        lookbackPeriod: Int = 100,
        timeframes: [Timeframe] = [.oneDay, .fourHour, .oneHour]
    ) {
        self.enabledPatterns = enabledPatterns
        self.minConfidence = minConfidence
        self.lookbackPeriod = lookbackPeriod
        self.timeframes = timeframes
    }
}

/// Pattern backtest result
public struct PatternBacktestResult: Codable {
    public let patternType: PatternType
    public let successRate: Double
    public let averageReturn: Double
    public let sampleSize: Int
    public let timeframe: Timeframe
    
    public init(
        patternType: PatternType,
        successRate: Double,
        averageReturn: Double,
        sampleSize: Int,
        timeframe: Timeframe
    ) {
        self.patternType = patternType
        self.successRate = successRate
        self.averageReturn = averageReturn
        self.sampleSize = sampleSize
        self.timeframe = timeframe
    }
}
