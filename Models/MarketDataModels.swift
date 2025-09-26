import Foundation

// MARK: - Market Data Models
// These models are used for market data representation

/// Represents a single point of market data
public struct MarketDataPoint {
    public var timestamp: Date
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var volume: Int
    public var symbol: String
    
    public init(timestamp: Date = Date(), 
                open: Double = 0.0, 
                high: Double = 0.0, 
                low: Double = 0.0, 
                close: Double = 0.0, 
                volume: Int = 0, 
                symbol: String = "") {
        self.timestamp = timestamp
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
    public var timestamp: Date
    public var features: [String: Double]
    public var label: Double?
    
    public init(timestamp: Date = Date(), features: [String: Double] = [:], label: Double? = nil) {
        self.timestamp = timestamp
        self.features = features
        self.label = label
    }
}
