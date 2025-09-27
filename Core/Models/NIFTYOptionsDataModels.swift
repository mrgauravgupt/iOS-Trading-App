import Foundation

// Import shared models to avoid duplication
// Note: OptionType, Timeframe, MarketRegime, VolatilityEnvironment, TrendDirection, and TradeAction are imported from CoreModels

// MARK: - NIFTY Options Specific Data Models

struct NIFTYOptionContract: Codable, Identifiable, Hashable {
    let id = UUID()
    let symbol: String // e.g., "NIFTY24JAN18000CE"
    let underlyingSymbol: String // "NIFTY"
    let strikePrice: Double
    let expiryDate: Date
    let optionType: OptionType
    let lotSize: Int
    let currentPrice: Double
    let bid: Double
    let ask: Double
    let volume: Int
    let openInterest: Int
    let impliedVolatility: Double
    let delta: Double
    let gamma: Double
    let theta: Double
    let vega: Double
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case symbol, underlyingSymbol, strikePrice, expiryDate, optionType, lotSize, currentPrice, bid, ask, volume, openInterest, impliedVolatility, delta, gamma, theta, vega, timestamp
    }
}

struct NIFTYOptionsChain: Codable {
    let underlyingPrice: Double
    let expiryDate: Date
    let callOptions: [NIFTYOptionContract]
    let putOptions: [NIFTYOptionContract]
    var timestamp: Date
    
    // Helper methods for options analysis
    func getATMStrike() -> Double {
        let roundedPrice = round(underlyingPrice / 50) * 50
        return roundedPrice
    }
    
    func getOptionsInRange(strikes: Int = 10) -> [NIFTYOptionContract] {
        let atmStrike = getATMStrike()
        let minStrike = atmStrike - Double(strikes * 50)
        let maxStrike = atmStrike + Double(strikes * 50)
        
        let relevantCalls = callOptions.filter { $0.strikePrice >= minStrike && $0.strikePrice <= maxStrike }
        let relevantPuts = putOptions.filter { $0.strikePrice >= minStrike && $0.strikePrice <= maxStrike }
        
        return relevantCalls + relevantPuts
    }
}

struct IntradayOptionsData: Codable, Identifiable {
    let id = UUID()
    let contract: NIFTYOptionContract
    let ohlcData: [OHLCData]
    let volumeProfile: [VolumeLevel]
    let orderBookData: OrderBookSnapshot?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case contract, ohlcData, volumeProfile, orderBookData, timestamp
    }
}

struct OHLCData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
    let timeframe: Timeframe

    enum CodingKeys: String, CodingKey {
        case timestamp, open, high, low, close, volume, timeframe
    }
}

// Note: Timeframe enum is now imported from CoreModels to avoid duplication

struct VolumeLevel: Codable, Identifiable {
    let id = UUID()
    let price: Double
    let volume: Int
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case price, volume, timestamp
    }
}

struct OrderBookSnapshot: Codable {
    let bids: [OrderBookLevel]
    let asks: [OrderBookLevel]
    let timestamp: Date
}

struct OrderBookLevel: Codable, Identifiable {
    let id = UUID()
    let price: Double
    let quantity: Int
    let orders: Int

    enum CodingKeys: String, CodingKey {
        case price, quantity, orders
    }
}

// MARK: - Intraday Trading Signals

struct IntradayTradingSignal: Codable, Identifiable {
    let id = UUID()
    let contract: NIFTYOptionContract
    let signalType: IntradaySignalType
    let confidence: Double
    let entryPrice: Double
    let targetPrice: Double
    let stopLoss: Double
    let timeframe: Timeframe
    let patterns: [String]
    let technicalIndicators: [String: Double]
    let timestamp: Date
    let expiryTime: Date // Signal validity

    enum CodingKeys: String, CodingKey {
        case contract, signalType, confidence, entryPrice, targetPrice, stopLoss, timeframe, patterns, technicalIndicators, timestamp, expiryTime
    }
}

// MARK: - IntradayTradingSignal Extensions
extension IntradayTradingSignal {
    // Convenience properties for backward compatibility
    var symbol: String { contract.symbol }
    var action: TradeAction { 
        switch signalType {
        case .breakoutBuy, .reversalBuy, .momentumBuy:
            return .buy
        case .breakdownSell, .reversalSell, .momentumSell:
            return .sell
        case .scalping, .hedging:
            return .buy // Default to buy for these strategies
        }
    }
    var optionType: OptionType { contract.optionType }
    var strikePrice: Double { contract.strikePrice }
    var expiryDate: Date { contract.expiryDate }
}

enum IntradaySignalType: String, Codable, CaseIterable {
    case breakoutBuy = "Breakout Buy"
    case breakdownSell = "Breakdown Sell"
    case reversalBuy = "Reversal Buy"
    case reversalSell = "Reversal Sell"
    case momentumBuy = "Momentum Buy"
    case momentumSell = "Momentum Sell"
    case scalping = "Scalping"
    case hedging = "Hedging"
}

// MARK: - Options Strategy Models

struct OptionsStrategy: Codable, Identifiable {
    let id = UUID()
    let name: String
    let type: OptionsStrategyType
    let legs: [OptionsLeg]
    let maxProfit: Double?
    let maxLoss: Double?
    let breakEvenPoints: [Double]
    let marginRequired: Double
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case name, type, legs, maxProfit, maxLoss, breakEvenPoints, marginRequired, timestamp
    }
}

enum OptionsStrategyType: String, Codable, CaseIterable {
    case longCall = "Long Call"
    case longPut = "Long Put"
    case shortCall = "Short Call"
    case shortPut = "Short Put"
    case longStraddle = "Long Straddle"
    case shortStraddle = "Short Straddle"
    case longStrangle = "Long Strangle"
    case shortStrangle = "Short Strangle"
    case bullCallSpread = "Bull Call Spread"
    case bearPutSpread = "Bear Put Spread"
    case ironCondor = "Iron Condor"
    case butterfly = "Butterfly"
}

struct OptionsLeg: Codable, Identifiable {
    let id = UUID()
    let contract: NIFTYOptionContract
    let action: TradeAction
    let quantity: Int
    let price: Double

    enum CodingKeys: String, CodingKey {
        case contract, action, quantity, price
    }
}

// MARK: - Historical Training Data

struct HistoricalTrainingData: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let underlyingData: [OHLCData]
    let optionsData: [IntradayOptionsData]
    let marketEvents: [MarketEvent]
    let tradingOutcomes: [TrainingOutcome]

    enum CodingKeys: String, CodingKey {
        case date, underlyingData, optionsData, marketEvents, tradingOutcomes
    }
}

struct MarketEvent: Codable, Identifiable {
    let id = UUID()
    let type: MarketEventType
    let timestamp: Date
    let impact: EventImpact
    let description: String

    enum CodingKeys: String, CodingKey {
        case type, timestamp, impact, description
    }
}

enum MarketEventType: String, Codable {
    case earnings = "Earnings"
    case rbiPolicy = "RBI Policy"
    case budgetAnnouncement = "Budget"
    case globalMarketMove = "Global Market"
    case volatilitySpike = "Volatility Spike"
    case largeOrderFlow = "Large Order Flow"
}

enum EventImpact: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct TrainingOutcome: Codable, Identifiable {
    let id = UUID()
    let signal: IntradayTradingSignal
    let actualEntry: Double?
    let actualExit: Double?
    let pnl: Double
    let success: Bool
    let duration: TimeInterval
    let slippageImpact: Double

    enum CodingKeys: String, CodingKey {
        case signal, actualEntry, actualExit, pnl, success, duration, slippageImpact
    }
}

// MARK: - Real-time Market Data

struct RealTimeMarketData: Codable {
    let niftySpotPrice: Double
    let niftyFuturePrice: Double
    let vix: Double
    let optionsChain: NIFTYOptionsChain
    let topGainers: [NIFTYOptionContract]
    let topLosers: [NIFTYOptionContract]
    let highestVolume: [NIFTYOptionContract]
    let highestOI: [NIFTYOptionContract]
    let timestamp: Date
}

// MARK: - AI Model State

struct AIModelState: Codable {
    let marketRegime: MarketRegime
    let volatilityEnvironment: VolatilityEnvironment
    let trendDirection: TrendDirection
    let supportResistanceLevels: [Double]
    let keyLevels: [KeyLevel]
    let riskMetrics: RiskMetrics
    let timestamp: Date
}

// Note: MarketRegime, VolatilityEnvironment, and TrendDirection enums are now imported from CoreModels to avoid duplication

struct KeyLevel: Codable, Identifiable {
    let id = UUID()
    let price: Double
    let type: KeyLevelType
    let strength: Double
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case price, type, strength, timestamp
    }
}

enum KeyLevelType: String, Codable {
    case support = "Support"
    case resistance = "Resistance"
    case pivot = "Pivot"
    case vwap = "VWAP"
}

// MARK: - Pattern Recognition Types

enum PatternTimeframe: String, Codable, CaseIterable {
    case oneMinute = "1m"
    case fiveMinute = "5m"
    case fifteenMinute = "15m"
    case thirtyMinute = "30m"
    case oneHour = "1h"
    
    var displayName: String {
        switch self {
        case .oneMinute: return "1 Min"
        case .fiveMinute: return "5 Min"
        case .fifteenMinute: return "15 Min"
        case .thirtyMinute: return "30 Min"
        case .oneHour: return "1 Hour"
        }
    }
}

enum OptionsPatternType: String, Codable, CaseIterable {
    case breakout = "Breakout"
    case reversal = "Reversal"
    case continuation = "Continuation"
    case momentum = "Momentum"
    case scalping = "Scalping"
    case volatility = "Volatility"

    var displayName: String {
        return self.rawValue
    }

    var color: String {
        switch self {
        case .breakout: return "blue"
        case .reversal: return "orange"
        case .continuation: return "green"
        case .momentum: return "purple"
        case .scalping: return "red"
        case .volatility: return "yellow"
        }
    }
}

struct DetectedPattern: Identifiable, Codable {
    let id = UUID()
    let timeframe: PatternTimeframe
    let patternType: OptionsPatternType
    let description: String
    let confidence: Double
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case timeframe, patternType, description, confidence, timestamp
    }
}

// MARK: - General App Models
// Note: TradeAction enum is now imported from CoreModels to avoid duplication

struct TradeSuggestion: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let action: TradeAction
    let price: Double
    let quantity: Int
    let confidence: Double // 0.0 to 1.0
    let rationale: String
    let timestamp: Date
    var isExecuted: Bool = false

    init(id: UUID = UUID(), symbol: String, action: TradeAction, price: Double, quantity: Int, confidence: Double, rationale: String, timestamp: Date, isExecuted: Bool = false) {
        self.id = id
        self.symbol = symbol
        self.action = action
        self.price = price
        self.quantity = quantity
        self.confidence = confidence
        self.rationale = rationale
        self.timestamp = timestamp
        self.isExecuted = isExecuted
    }
}

enum AITradingMode: String, CaseIterable {
    case alertOnly = "Alert Only"
    case autoTrade = "Auto Trade"
    
    var description: String {
        switch self {
        case .alertOnly:
            return "Show alerts for trade suggestions"
        case .autoTrade:
            return "Automatically execute suggested trades"
        }
    }
}

enum TradingStatus {
    case stopped
    case running
    case paused
    case emergencyStopped
}

struct RiskMetrics: Codable {
    var portfolioValue: Double = 0
    var totalExposure: Double = 0
    var maxDrawdown: Double = 0
    var valueAtRisk: Double = 0
    var sharpeRatio: Double = 0
    var beta: Double = 0
}


struct OptionsPosition: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let quantity: Int
    let strikePrice: Double
    let expiryDate: Date
    let optionType: OptionType
    let entryPrice: Double
    let currentPrice: Double
    let timestamp: Date

    var unrealizedPnL: Double {
        return Double(quantity) * (currentPrice - entryPrice) * 50 // NIFTY lot size
    }

    // Needed for Codable since computed properties aren't automatically encoded/decoded
    enum CodingKeys: String, CodingKey {
        case symbol, quantity, strikePrice, expiryDate, optionType, entryPrice, currentPrice, timestamp
    }
}

struct OptionsOrder: Codable {
    let id = UUID()
    let symbol: String
    let action: TradeAction
    let quantity: Int
    let orderType: OrderType
    let price: Double // Order price (premium for options)
    let strikePrice: Double
    let expiryDate: Date
    let optionType: OptionType
    let timestamp: Date = Date()

    enum CodingKeys: String, CodingKey {
        case symbol, action, quantity, orderType, price, strikePrice, expiryDate, optionType, timestamp
    }
}

enum OrderType: String, Codable {
    case market
    case limit
    case stopLoss
}

struct ExecutionResult: Codable {
    let isSuccessful: Bool
    let orderId: String?
    let executedPrice: Double?
    let executedQuantity: Int?
    let errorMessage: String?
}

enum TradingError: Error {
    case systemNotInitialized
    case marketClosed
    case insufficientFunds
    case riskLimitExceeded
    case orderExecutionFailed
    case dataUnavailable
}