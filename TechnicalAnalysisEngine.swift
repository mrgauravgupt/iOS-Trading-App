import Foundation

class TechnicalAnalysisEngine {
    // RSI calculation
    func calculateRSI(prices: [Double], period: Int = 14) -> Double {
        guard prices.count > period else { return 50.0 }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        }
        
        let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)
        
        if avgLoss == 0 {
            return 100.0
        }
        
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
    
    // MACD calculation
    func calculateMACD(prices: [Double], shortPeriod: Int = 12, longPeriod: Int = 26, signalPeriod: Int = 9) -> (macd: Double, signal: Double, histogram: Double) {
        guard prices.count > longPeriod else { return (0, 0, 0) }
        
        let shortEMA = calculateEMA(prices: prices, period: shortPeriod)
        let longEMA = calculateEMA(prices: prices, period: longPeriod)
        let macd = shortEMA - longEMA
        
        // Calculate signal line properly
        var macdLine: [Double] = []
        for i in 0..<prices.count {
            if i >= longPeriod {
                let short = calculateEMA(prices: Array(prices[0...i]), period: shortPeriod)
                let long = calculateEMA(prices: Array(prices[0...i]), period: longPeriod)
                macdLine.append(short - long)
            }
        }
        
        // Calculate signal line as EMA of MACD line
        let signal = macdLine.count >= signalPeriod ? calculateEMA(prices: macdLine, period: signalPeriod) : 0
        let histogram = macd - signal
        
        return (macd, signal, histogram)
    }
    
    // EMA calculation
    func calculateEMA(prices: [Double], period: Int) -> Double {
        guard prices.count >= period else { return prices.last ?? 0 }
        
        let multiplier = 2.0 / (Double(period) + 1.0)
        var ema = prices[0]
        
        for i in 1..<prices.count {
            ema = (prices[i] * multiplier) + (ema * (1 - multiplier))
        }
        
        return ema
    }
    
    // Bollinger Bands
    func calculateBollingerBands(prices: [Double], period: Int = 20, standardDeviations: Double = 2.0) -> (upper: Double, middle: Double, lower: Double) {
        guard prices.count >= period else { return (0, 0, 0) }
        
        let sma = prices.suffix(period).reduce(0, +) / Double(period)
        let variance = prices.suffix(period).map { pow($0 - sma, 2) }.reduce(0, +) / Double(period)
        let stdDev = sqrt(variance)
        
        return (sma + standardDeviations * stdDev, sma, sma - standardDeviations * stdDev)
    }
    
    // Moving Averages
    func calculateSMA(prices: [Double], period: Int) -> Double {
        guard prices.count >= period else { return 0 }
        return prices.suffix(period).reduce(0, +) / Double(period)
    }

    // Fibonacci Retracements
    func calculateFibonacciRetracement(high: Double, low: Double) -> [Double] {
        let range = high - low
        return [
            high,
            high - 0.236 * range,
            high - 0.382 * range,
            high - 0.5 * range,
            high - 0.618 * range,
            low
        ]
    }

    // Candlestick Patterns
    enum CandlestickPattern {
        case doji, hammer, shootingStar, engulfing
    }

    struct Candlestick {
        let open: Double
        let high: Double
        let low: Double
        let close: Double
    }

    func detectCandlestickPattern(candles: [Candlestick]) -> CandlestickPattern? {
        guard candles.count >= 2 else { return nil }

        let current = candles.last!
        let previous = candles[candles.count - 2]

        // Doji pattern
        let bodySize = abs(current.close - current.open)
        let totalRange = current.high - current.low
        if bodySize <= totalRange * 0.05 {
            return .doji
        }

        // Hammer pattern
        if current.low < current.open && current.low < current.close &&
           bodySize > 0 && (current.high - max(current.open, current.close)) > bodySize * 2 {
            return .hammer
        }

        // Shooting Star pattern
        if current.high > current.open && current.high > current.close &&
           bodySize > 0 && (min(current.open, current.close) - current.low) > bodySize * 2 {
            return .shootingStar
        }

        // Engulfing pattern
        let previousBody = abs(previous.close - previous.open)
        let currentBody = abs(current.close - current.open)
        if currentBody > previousBody &&
           ((current.open > previous.close && current.close < previous.open) ||
            (current.open < previous.close && current.close > previous.open)) {
            return .engulfing
        }

        return nil
    }

    // Stochastic Oscillator
    func calculateStochastic(highs: [Double], lows: [Double], closes: [Double], period: Int = 14) -> Double {
        guard highs.count >= period && lows.count >= period && closes.count >= period else { return 50.0 }

        let currentHigh = highs.suffix(period).max() ?? 0
        let currentLow = lows.suffix(period).min() ?? 0
        let currentClose = closes.last ?? 0

        if currentHigh == currentLow {
            return 50.0
        }

        return ((currentClose - currentLow) / (currentHigh - currentLow)) * 100
    }
}