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
        
        let macdArray = [macd] // Simplified for this example
        let signal = calculateEMA(prices: macdArray, period: signalPeriod)
        
        return (macd, signal, macd - signal)
    }
    
    // EMA calculation
    private func _calculateEMA(prices: [Double], period: Int) -> Double {
        guard prices.count >= period else { return prices.last ?? 0 }
        
        let multiplier = 2.0 / (Double(period) + 1.0)
        var ema = prices[period-1]
        
        for i in period..<prices.count {
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
    
    func calculateEMA(prices: [Double], period: Int) -> Double {
        return _calculateEMA(prices: prices, period: period)
    }
}
