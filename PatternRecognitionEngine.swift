import Foundation

public class PatternRecognitionEngine {
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()

    enum TradingSignal: CaseIterable {
        case buy, sell, hold
    }

    struct PatternResult {
        let pattern: String
        let signal: TradingSignal
        let confidence: Double
    }

    func analyzePatterns(highs: [Double], lows: [Double], closes: [Double], opens: [Double]) -> [PatternResult] {
        var results: [PatternResult] = []

        // RSI Analysis
        if let rsi = calculateRSI(highs: highs, lows: lows, closes: closes) {
            let rsiResult = analyzeRSI(rsi)
            results.append(rsiResult)
        }

        // MACD Analysis
        if let macdResult = analyzeMACD(highs: highs, lows: lows, closes: closes) {
            results.append(macdResult)
        }

        // Bollinger Bands Analysis
        if let bollingerResult = analyzeBollingerBands(highs: highs, lows: lows, closes: closes) {
            results.append(bollingerResult)
        }

        // Candlestick Analysis
        let candles = createCandlesticks(opens: opens, highs: highs, lows: lows, closes: closes)
        if let candlestickResult = analyzeCandlesticks(candles) {
            results.append(candlestickResult)
        }

        // Stochastic Analysis
        if let stochasticResult = analyzeStochastic(highs: highs, lows: lows, closes: closes) {
            results.append(stochasticResult)
        }

        return results
    }

    // Test method to validate pattern recognition
    func testPatternRecognition() -> [PatternResult] {
        let testHighs = [18100.0, 18200.0, 18300.0, 18250.0, 18150.0, 18200.0, 18350.0]
        let testLows = [18000.0, 18100.0, 18200.0, 18150.0, 18050.0, 18100.0, 18250.0]
        let testCloses = [18050.0, 18150.0, 18250.0, 18200.0, 18100.0, 18150.0, 18300.0]
        let testOpens = [18000.0, 18100.0, 18200.0, 18150.0, 18050.0, 18100.0, 18250.0]

        return analyzePatterns(highs: testHighs, lows: testLows, closes: testCloses, opens: testOpens)
    }

    private func calculateRSI(highs: [Double], lows: [Double], closes: [Double]) -> Double? {
        // Simplified RSI calculation using closes
        return technicalAnalysisEngine.calculateRSI(prices: closes)
    }

    private func analyzeRSI(_ rsi: Double) -> PatternResult {
        let signal: TradingSignal = rsi < 30 ? .buy : rsi > 70 ? .sell : .hold
        let confidence = min(abs(rsi - 50) / 50, 1.0)
        return PatternResult(pattern: "RSI", signal: signal, confidence: confidence)
    }

    private func analyzeMACD(highs: [Double], lows: [Double], closes: [Double]) -> PatternResult? {
        let (macd, signal, _) = technicalAnalysisEngine.calculateMACD(prices: closes)
        let macdSignal: TradingSignal = macd > signal ? .buy : macd < signal ? .sell : .hold
        let confidence = min(abs(macd - signal) / abs(signal), 1.0)
        return PatternResult(pattern: "MACD", signal: macdSignal, confidence: confidence)
    }

    private func analyzeBollingerBands(highs: [Double], lows: [Double], closes: [Double]) -> PatternResult? {
        let (upper, middle, lower) = technicalAnalysisEngine.calculateBollingerBands(prices: closes)
        let currentPrice = closes.last ?? 0

        let signal: TradingSignal
        let confidence: Double

        if currentPrice > upper {
            signal = .sell
            confidence = min((currentPrice - upper) / (upper - middle), 1.0)
        } else if currentPrice < lower {
            signal = .buy
            confidence = min((lower - currentPrice) / (middle - lower), 1.0)
        } else {
            signal = .hold
            confidence = 0.5
        }

        return PatternResult(pattern: "Bollinger Bands", signal: signal, confidence: confidence)
    }

    private func createCandlesticks(opens: [Double], highs: [Double], lows: [Double], closes: [Double]) -> [TechnicalAnalysisEngine.Candlestick] {
        var candles: [TechnicalAnalysisEngine.Candlestick] = []
        for i in 0..<min(opens.count, highs.count, lows.count, closes.count) {
            candles.append(TechnicalAnalysisEngine.Candlestick(open: opens[i], high: highs[i], low: lows[i], close: closes[i]))
        }
        return candles
    }

    private func analyzeCandlesticks(_ candles: [TechnicalAnalysisEngine.Candlestick]) -> PatternResult? {
        guard let pattern = technicalAnalysisEngine.detectCandlestickPattern(candles: candles) else {
            return nil
        }

        let signal: TradingSignal
        let confidence: Double

        switch pattern {
        case .doji:
            signal = .hold
            confidence = 0.7
        case .hammer:
            signal = .buy
            confidence = 0.8
        case .shootingStar:
            signal = .sell
            confidence = 0.8
        case .engulfing:
            signal = candles.last!.close > candles.last!.open ? .buy : .sell
            confidence = 0.9
        }

        return PatternResult(pattern: "Candlestick - \(pattern)", signal: signal, confidence: confidence)
    }

    private func analyzeStochastic(highs: [Double], lows: [Double], closes: [Double]) -> PatternResult? {
        let stochastic = technicalAnalysisEngine.calculateStochastic(highs: highs, lows: lows, closes: closes)
        let signal: TradingSignal = stochastic < 20 ? .buy : stochastic > 80 ? .sell : .hold
        let confidence = min(abs(stochastic - 50) / 50, 1.0)
        return PatternResult(pattern: "Stochastic", signal: signal, confidence: confidence)
    }
}