import Foundation

/// Manages real-time calculation of technical indicators
class TechnicalIndicatorsManager {

    // MARK: - RSI Calculation

    /// Calculate RSI (Relative Strength Index) for a series of OHLC data
    /// - Parameters:
    ///   - data: Array of OHLC data points
    ///   - period: RSI period (default 14)
    /// - Returns: RSI value or nil if insufficient data
    static func calculateRSI(for data: [OHLCData], period: Int = 14) -> Double? {
        guard data.count >= period + 1 else { return nil }

        let closes = data.map { $0.close }
        var gains: [Double] = []
        var losses: [Double] = []

        // Calculate price changes
        for i in 1..<closes.count {
            let change = closes[i] - closes[i-1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }

        // Calculate initial averages
        let avgGain = gains.prefix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.prefix(period).reduce(0, +) / Double(period)

        // Calculate RSI using Wilder's smoothing
        var currentAvgGain = avgGain
        var currentAvgLoss = avgLoss

        for i in period..<gains.count {
            currentAvgGain = (currentAvgGain * Double(period - 1) + gains[i]) / Double(period)
            currentAvgLoss = (currentAvgLoss * Double(period - 1) + losses[i]) / Double(period)
        }

        if currentAvgLoss == 0 {
            return 100.0
        }

        let rs = currentAvgGain / currentAvgLoss
        return 100.0 - (100.0 / (1.0 + rs))
    }

    // MARK: - MACD Calculation

    /// Calculate MACD (Moving Average Convergence Divergence)
    /// - Parameters:
    ///   - data: Array of OHLC data points
    ///   - fastPeriod: Fast EMA period (default 12)
    ///   - slowPeriod: Slow EMA period (default 26)
    ///   - signalPeriod: Signal line EMA period (default 9)
    /// - Returns: MACDResult containing MACD line, signal line, and histogram
    static func calculateMACD(for data: [OHLCData], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> MACDResult? {
        let closes = data.map { $0.close }

        guard closes.count >= slowPeriod + signalPeriod else { return nil }

        // Calculate EMAs
        guard let fastEMA = calculateEMA(for: closes, period: fastPeriod),
              let slowEMA = calculateEMA(for: closes, period: slowPeriod) else {
            return nil
        }

        // Calculate MACD line
        let macdLine = zip(fastEMA, slowEMA).map { $0 - $1 }

        // Calculate signal line (EMA of MACD line)
        guard let signalLine = calculateEMA(for: macdLine, period: signalPeriod) else {
            return nil
        }

        // Calculate histogram
        let histogram = zip(macdLine, signalLine).map { $0 - $1 }

        return MACDResult(
            macdLine: macdLine.last ?? 0,
            signalLine: signalLine.last ?? 0,
            histogram: histogram.last ?? 0,
            fastEMA: fastEMA.last ?? 0,
            slowEMA: slowEMA.last ?? 0
        )
    }

    // MARK: - Bollinger Bands Calculation

    /// Calculate Bollinger Bands
    /// - Parameters:
    ///   - data: Array of OHLC data points
    ///   - period: Moving average period (default 20)
    ///   - standardDeviations: Number of standard deviations (default 2)
    /// - Returns: BollingerBandsResult or nil if insufficient data
    static func calculateBollingerBands(for data: [OHLCData], period: Int = 20, standardDeviations: Double = 2.0) -> BollingerBandsResult? {
        let closes = data.map { $0.close }
        guard closes.count >= period else { return nil }

        // Calculate SMA
        let sma = calculateSMA(for: closes, period: period)?.last ?? 0

        // Calculate standard deviation
        let recentCloses = Array(closes.suffix(period))
        let variance = recentCloses.map { pow($0 - sma, 2) }.reduce(0, +) / Double(period)
        let stdDev = sqrt(variance)

        let upperBand = sma + (standardDeviations * stdDev)
        let lowerBand = sma - (standardDeviations * stdDev)

        return BollingerBandsResult(
            upperBand: upperBand,
            middleBand: sma,
            lowerBand: lowerBand,
            bandwidth: (upperBand - lowerBand) / sma,
            percentB: (closes.last! - lowerBand) / (upperBand - lowerBand)
        )
    }

    // MARK: - Moving Average Calculations

    /// Calculate Simple Moving Average
    static func calculateSMA(for prices: [Double], period: Int) -> [Double]? {
        guard prices.count >= period else { return nil }

        var sma: [Double] = []
        for i in (period-1)..<prices.count {
            let sum = prices[(i-period+1)...i].reduce(0, +)
            sma.append(sum / Double(period))
        }
        return sma
    }

    /// Calculate Exponential Moving Average
    static func calculateEMA(for prices: [Double], period: Int) -> [Double]? {
        guard prices.count >= period else { return nil }

        let multiplier = 2.0 / (Double(period) + 1.0)
        var ema: [Double] = []

        // Start with SMA for first value
        let sma = prices.prefix(period).reduce(0, +) / Double(period)
        ema.append(sma)

        // Calculate subsequent EMAs
        for i in period..<prices.count {
            let currentEMA = (prices[i] - ema.last!) * multiplier + ema.last!
            ema.append(currentEMA)
        }

        return ema
    }

    // MARK: - Volume Profile Analysis

    /// Calculate Volume Profile for recent data
    /// - Parameters:
    ///   - data: Array of OHLC data points
    ///   - priceRange: Price range to analyze (default 2% around current price)
    /// - Returns: Array of VolumeLevel objects
    static func calculateVolumeProfile(for data: [OHLCData], priceRange: Double = 0.02) -> [VolumeLevel] {
        guard let currentPrice = data.last?.close else { return [] }

        let minPrice = currentPrice * (1 - priceRange)
        let maxPrice = currentPrice * (1 + priceRange)
        let priceStep = (maxPrice - minPrice) / 20 // 20 price levels

        var volumeLevels: [VolumeLevel] = []

        for i in 0..<20 {
            let levelPrice = minPrice + (Double(i) * priceStep)
            var totalVolume = 0

            // Aggregate volume for candles that touch this price level
            for candle in data {
                if candle.low <= levelPrice && candle.high >= levelPrice {
                    totalVolume += candle.volume
                }
            }

            volumeLevels.append(VolumeLevel(
                price: levelPrice,
                volume: totalVolume,
                timestamp: data.last?.timestamp ?? Date()
            ))
        }

        return volumeLevels.sorted { $0.volume > $1.volume } // Sort by volume descending
    }

    // MARK: - Support and Resistance Levels

    /// Calculate support and resistance levels using pivot points
    /// - Parameter data: Array of OHLC data points (should be daily data)
    /// - Returns: Array of KeyLevel objects
    static func calculatePivotLevels(for data: [OHLCData]) -> [KeyLevel] {
        guard data.count >= 1 else { return [] }

        let lastCandle = data.last!
        let pivot = (lastCandle.high + lastCandle.low + lastCandle.close) / 3

        // Calculate resistance levels
        let r1 = (2 * pivot) - lastCandle.low
        let r2 = pivot + (lastCandle.high - lastCandle.low)
        let r3 = lastCandle.high + 2 * (pivot - lastCandle.low)

        // Calculate support levels
        let s1 = (2 * pivot) - lastCandle.high
        let s2 = pivot - (lastCandle.high - lastCandle.low)
        let s3 = lastCandle.low - 2 * (lastCandle.high - pivot)

        return [
            KeyLevel(price: r3, type: .resistance, strength: 0.9, timestamp: lastCandle.timestamp),
            KeyLevel(price: r2, type: .resistance, strength: 0.8, timestamp: lastCandle.timestamp),
            KeyLevel(price: r1, type: .resistance, strength: 0.7, timestamp: lastCandle.timestamp),
            KeyLevel(price: pivot, type: .pivot, strength: 1.0, timestamp: lastCandle.timestamp),
            KeyLevel(price: s1, type: .support, strength: 0.7, timestamp: lastCandle.timestamp),
            KeyLevel(price: s2, type: .support, strength: 0.8, timestamp: lastCandle.timestamp),
            KeyLevel(price: s3, type: .support, strength: 0.9, timestamp: lastCandle.timestamp)
        ]
    }
}

// MARK: - Result Structures

struct MACDResult {
    let macdLine: Double
    let signalLine: Double
    let histogram: Double
    let fastEMA: Double
    let slowEMA: Double
}

struct BollingerBandsResult {
    let upperBand: Double
    let middleBand: Double
    let lowerBand: Double
    let bandwidth: Double
    let percentB: Double
}
