import Foundation

// MARK: - Market Data Models

/// Represents a single point of market data
public struct MarketDataPoint {
    public var date: Date
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var volume: Int
    public var symbol: String
    
    public init(
        date: Date = Date(),
        open: Double = 0.0,
        high: Double = 0.0,
        low: Double = 0.0,
        close: Double = 0.0,
        volume: Int = 0,
        symbol: String = ""
    ) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.symbol = symbol
    }
}

/// Represents processed market data ready for model consumption
public struct ProcessedDataPoint {
    public var date: Date
    public var features: [String: Double]
    public var label: Double?
    
    public init(
        date: Date = Date(),
        features: [String: Double] = [:],
        label: Double? = nil
    ) {
        self.date = date
        self.features = features
        self.label = label
    }
}

// MARK: - Analytics Models

/// Validation results for model performance
public struct ValidationResults {
    // Fields from HistoricalTrainingManager
    public var patternRecognitionAccuracy: Double
    public var marketRegimeAccuracy: Double
    public var rlAgentPerformance: Double
    
    // Fields from ContinuousLearningManager
    public var improvedWinRate: Bool
    public var reducedDrawdown: Bool
    public var betterSharpeRatio: Bool
    public var overallImprovement: Double
    
    public init(
        patternRecognitionAccuracy: Double = 0.0,
        marketRegimeAccuracy: Double = 0.0,
        rlAgentPerformance: Double = 0.0,
        improvedWinRate: Bool = false,
        reducedDrawdown: Bool = false,
        betterSharpeRatio: Bool = false,
        overallImprovement: Double = 0.0
    ) {
        self.patternRecognitionAccuracy = patternRecognitionAccuracy
        self.marketRegimeAccuracy = marketRegimeAccuracy
        self.rlAgentPerformance = rlAgentPerformance
        self.improvedWinRate = improvedWinRate
        self.reducedDrawdown = reducedDrawdown
        self.betterSharpeRatio = betterSharpeRatio
        self.overallImprovement = overallImprovement
    }
}

/// Results from backtesting
public struct BacktestResults {
    public var totalReturn: Double
    public var winRate: Double
    public var maxDrawdown: Double
    public var sharpeRatio: Double
    public var trades: [TradeResult]
    
    public init(
        totalReturn: Double = 0.0,
        winRate: Double = 0.0,
        maxDrawdown: Double = 0.0,
        sharpeRatio: Double = 0.0,
        trades: [TradeResult] = []
    ) {
        self.totalReturn = totalReturn
        self.winRate = winRate
        self.maxDrawdown = maxDrawdown
        self.sharpeRatio = sharpeRatio
        self.trades = trades
    }
}

/// Performance metrics for trading strategies
public struct PerformanceMetrics {
    public var totalReturn: Double
    public var annualizedReturn: Double
    public var sharpeRatio: Double
    public var maxDrawdown: Double
    public var winRate: Double
    public var profitFactor: Double
    public var totalTrades: Int  // Added missing property
    
    public init(
        totalReturn: Double = 0.0,
        annualizedReturn: Double = 0.0,
        sharpeRatio: Double = 0.0,
        maxDrawdown: Double = 0.0,
        winRate: Double = 0.0,
        profitFactor: Double = 0.0,
        totalTrades: Int = 0     // Added to initializer
    ) {
        self.totalReturn = totalReturn
        self.annualizedReturn = annualizedReturn
        self.sharpeRatio = sharpeRatio
        self.maxDrawdown = maxDrawdown
        self.winRate = winRate
        self.profitFactor = profitFactor
        self.totalTrades = totalTrades
    }
}

/// Results of a single trade
public struct TradeResult {
    public var symbol: String
    public var entryDate: Date
    public var exitDate: Date
    public var entryPrice: Double
    public var exitPrice: Double
    public var quantity: Int
    public var pnl: Double
    public var isWin: Bool
    
    public init(
        symbol: String = "",
        entryDate: Date = Date(),
        exitDate: Date = Date(),
        entryPrice: Double = 0.0,
        exitPrice: Double = 0.0,
        quantity: Int = 0,
        pnl: Double = 0.0,
        isWin: Bool = false
    ) {
        self.symbol = symbol
        self.entryDate = entryDate
        self.exitDate = exitDate
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.quantity = quantity
        self.pnl = pnl
        self.isWin = isWin
    }
}

/// Results from testing models
public struct TestResults {
    public var accuracy: Double
    public var precision: Double
    public var recall: Double
    public var f1Score: Double
    public var confusionMatrix: [[Int]]
    public var backtestResults: BacktestResults
    public var performanceMetrics: PerformanceMetrics
    
    public init(
        accuracy: Double = 0.0,
        precision: Double = 0.0,
        recall: Double = 0.0,
        f1Score: Double = 0.0,
        confusionMatrix: [[Int]] = [],
        backtestResults: BacktestResults = BacktestResults(),
        performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    ) {
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
        self.confusionMatrix = confusionMatrix
        self.backtestResults = backtestResults
        self.performanceMetrics = performanceMetrics
    }
}

/// Results from training models
public struct TrainingResults {
    public var epochs: Int
    public var finalLoss: Double
    public var trainingTime: TimeInterval
    public var validationAccuracy: Double
    public var learningRate: Double
    
    public init(
        epochs: Int = 0,
        finalLoss: Double = 0.0,
        trainingTime: TimeInterval = 0.0,
        validationAccuracy: Double = 0.0,
        learningRate: Double = 0.0
    ) {
        self.epochs = epochs
        self.finalLoss = finalLoss
        self.trainingTime = trainingTime
        self.validationAccuracy = validationAccuracy
        self.learningRate = learningRate
    }
}
