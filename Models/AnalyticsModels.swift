import Foundation

// MARK: - Analytics Models
// These models are used for analytics and performance measurement

/// Validation results for model performance
public struct ValidationResults {
    // Fields from HistoricalTrainingManager
    public var patternRecognitionAccuracy: Double = 0.0
    public var marketRegimeAccuracy: Double = 0.0
    public var priceDirectionAccuracy: Double = 0.0
    public var volatilityPredictionAccuracy: Double = 0.0
    public var supportResistanceAccuracy: Double = 0.0
    
    // Fields from ContinuousLearningManager
    public var overallAccuracy: Double = 0.0
    public var precisionScore: Double = 0.0
    public var recallScore: Double = 0.0
    public var f1Score: Double = 0.0
    
    public init() {}
}

/// Results from backtesting
public struct BacktestResults {
    public var trades: [TradeResult] = []
    public var startDate: Date = Date()
    public var endDate: Date = Date()
    public var initialCapital: Double = 0.0
    public var finalCapital: Double = 0.0
    public var maxDrawdown: Double = 0.0
    public var sharpeRatio: Double = 0.0
    public var winRate: Double = 0.0
    
    public init() {}
}

/// Performance metrics for trading strategies
public struct PerformanceMetrics {
    public var totalReturn: Double = 0.0
    public var annualizedReturn: Double = 0.0
    public var sharpeRatio: Double = 0.0
    public var maxDrawdown: Double = 0.0
    public var winRate: Double = 0.0
    public var profitFactor: Double = 0.0
    public var averageWin: Double = 0.0
    public var averageLoss: Double = 0.0
    public var expectancy: Double = 0.0
    
    public init() {}
}

/// Results of a single trade
public struct TradeResult {
    public var entryDate: Date
    public var exitDate: Date?
    public var entryPrice: Double
    public var exitPrice: Double?
    public var quantity: Int
    public var direction: String // "long" or "short"
    public var profit: Double?
    public var percentReturn: Double?
    public var reason: String
    
    public init(entryDate: Date = Date(), 
                exitDate: Date? = nil, 
                entryPrice: Double = 0.0, 
                exitPrice: Double? = nil, 
                quantity: Int = 0, 
                direction: String = "long", 
                profit: Double? = nil, 
                percentReturn: Double? = nil, 
                reason: String = "") {
        self.entryDate = entryDate
        self.exitDate = exitDate
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.quantity = quantity
        self.direction = direction
        self.profit = profit
        self.percentReturn = percentReturn
        self.reason = reason
    }
}

/// Results from testing models
public struct TestResults {
    public var accuracy: Double = 0.0
    public var precision: Double = 0.0
    public var recall: Double = 0.0
    public var f1Score: Double = 0.0
    public var confusionMatrix: [[Int]] = []
    
    public init() {}
}

/// Results from training models
public struct TrainingResults {
    public var epochs: Int = 0
    public var finalLoss: Double = 0.0
    public var trainingTime: TimeInterval = 0.0
    public var validationAccuracy: Double = 0.0
    public var learningRate: Double = 0.0
    
    public init() {}
}
