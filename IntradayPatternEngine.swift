import Foundation
import Combine

class IntradayPatternEngine: ObservableObject {
    @Published var detectedPatterns: [IntradayPattern] = []
    @Published var activeSignals: [IntradayTradingSignal] = []
    @Published var patternAlerts: [PatternAlert] = []
    
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    private let volumeAnalyzer = VolumeAnalyzer()
    private let orderFlowAnalyzer = OrderFlowAnalyzer()
    
    // MARK: - Intraday Pattern Detection
    
    func analyzeIntradayPatterns(
        ohlcData: [OHLCData],
        volumeData: [VolumeLevel],
        timeframe: Timeframe
    ) -> [IntradayPattern] {
        
        var patterns: [IntradayPattern] = []
        
        // 1. Breakout Patterns
        patterns.append(contentsOf: detectBreakoutPatterns(ohlcData: ohlcData, timeframe: timeframe))
        
        // 2. Reversal Patterns
        patterns.append(contentsOf: detectReversalPatterns(ohlcData: ohlcData, timeframe: timeframe))
        
        // 3. Momentum Patterns
        patterns.append(contentsOf: detectMomentumPatterns(ohlcData: ohlcData, timeframe: timeframe))
        
        // 4. Volume-based Patterns
        patterns.append(contentsOf: detectVolumePatterns(ohlcData: ohlcData, volumeData: volumeData))
        
        // 5. Scalping Patterns (for 1m and 5m timeframes)
        if timeframe == .oneMinute || timeframe == .fiveMinute {
            patterns.append(contentsOf: detectScalpingPatterns(ohlcData: ohlcData))
        }
        
        // 6. Options-specific Patterns
        patterns.append(contentsOf: detectOptionsSpecificPatterns(ohlcData: ohlcData))
        
        return patterns
    }
    
    // MARK: - Breakout Pattern Detection
    
    private func detectBreakoutPatterns(ohlcData: [OHLCData], timeframe: Timeframe) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []
        
        guard ohlcData.count >= 20 else { return patterns }
        
        let prices = ohlcData.map { $0.close }
        let highs = ohlcData.map { $0.high }
        let lows = ohlcData.map { $0.low }
        let volumes = ohlcData.map { $0.volume }
        
        // 1. Range Breakout
        if let rangeBreakout = detectRangeBreakout(highs: highs, lows: lows, volumes: volumes) {
            patterns.append(rangeBreakout)
        }
        
        // 2. Triangle Breakout
        if let triangleBreakout = detectTriangleBreakout(highs: highs, lows: lows, prices: prices) {
            patterns.append(triangleBreakout)
        }
        
        // 3. Flag/Pennant Breakout
        if let flagBreakout = detectFlagBreakout(prices: prices, volumes: volumes) {
            patterns.append(flagBreakout)
        }
        
        // 4. Support/Resistance Breakout
        if let srBreakout = detectSupportResistanceBreakout(prices: prices, volumes: volumes) {
            patterns.append(srBreakout)
        }
        
        return patterns
    }
    
    private func detectRangeBreakout(highs: [Double], lows: [Double], volumes: [Int]) -> IntradayPattern? {
        let lookbackPeriod = 15
        guard highs.count >= lookbackPeriod else { return nil }
        
        let recentHighs = Array(highs.suffix(lookbackPeriod))
        let recentLows = Array(lows.suffix(lookbackPeriod))
        let recentVolumes = Array(volumes.suffix(lookbackPeriod))
        
        let rangeHigh = recentHighs.max() ?? 0
        let rangeLow = recentLows.min() ?? 0
        let rangeSize = rangeHigh - rangeLow
        
        let currentHigh = highs.last ?? 0
        let currentLow = lows.last ?? 0
        let currentVolume = volumes.last ?? 0
        let avgVolume = recentVolumes.reduce(0, +) / recentVolumes.count
        
        // Check for breakout conditions
        let isUpwardBreakout = currentHigh > rangeHigh && currentVolume > avgVolume * 2
        let isDownwardBreakout = currentLow < rangeLow && currentVolume > avgVolume * 2
        
        if isUpwardBreakout || isDownwardBreakout {
            return IntradayPattern(
                type: .rangeBreakout,
                direction: isUpwardBreakout ? .bullish : .bearish,
                confidence: calculateBreakoutConfidence(rangeSize: rangeSize, volumeRatio: Double(currentVolume) / Double(avgVolume)),
                entryPrice: isUpwardBreakout ? rangeHigh : rangeLow,
                targetPrice: isUpwardBreakout ? rangeHigh + rangeSize : rangeLow - rangeSize,
                stopLoss: isUpwardBreakout ? rangeHigh - (rangeSize * 0.2) : rangeLow + (rangeSize * 0.2),
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    // MARK: - Reversal Pattern Detection
    
    private func detectReversalPatterns(ohlcData: [OHLCData], timeframe: Timeframe) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []
        
        guard ohlcData.count >= 10 else { return patterns }
        
        // 1. Double Top/Bottom
        if let doublePattern = detectDoubleTopBottom(ohlcData: ohlcData) {
            patterns.append(doublePattern)
        }
        
        // 2. Head and Shoulders
        if let hsPattern = detectHeadAndShoulders(ohlcData: ohlcData) {
            patterns.append(hsPattern)
        }
        
        // 3. Divergence Patterns
        patterns.append(contentsOf: detectDivergencePatterns(ohlcData: ohlcData))
        
        // 4. Hammer/Doji Reversal
        if let candlestickReversal = detectCandlestickReversal(ohlcData: ohlcData) {
            patterns.append(candlestickReversal)
        }
        
        return patterns
    }
    
    private func detectDoubleTopBottom(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 20 else { return nil }
        
        let highs = ohlcData.map { $0.high }
        let lows = ohlcData.map { $0.low }
        
        // Look for double top pattern
        let peaks = findPeaks(in: highs, minDistance: 5)
        if peaks.count >= 2 {
            let lastTwoPeaks = Array(peaks.suffix(2))
            let peak1 = lastTwoPeaks[0]
            let peak2 = lastTwoPeaks[1]
            
            let priceDiff = abs(highs[peak1] - highs[peak2])
            let avgPrice = (highs[peak1] + highs[peak2]) / 2
            
            // Check if peaks are at similar levels (within 1% of each other)
            if priceDiff / avgPrice < 0.01 {
                let neckline = findNeckline(ohlcData: ohlcData, peak1: peak1, peak2: peak2)
                
                return IntradayPattern(
                    type: .doubleTop,
                    direction: .bearish,
                    confidence: 0.75,
                    entryPrice: neckline,
                    targetPrice: neckline - (avgPrice - neckline),
                    stopLoss: avgPrice,
                    timeframe: .fifteenMinute,
                    timestamp: Date()
                )
            }
        }
        
        // Look for double bottom pattern
        let troughs = findTroughs(in: lows, minDistance: 5)
        if troughs.count >= 2 {
            let lastTwoTroughs = Array(troughs.suffix(2))
            let trough1 = lastTwoTroughs[0]
            let trough2 = lastTwoTroughs[1]
            
            let priceDiff = abs(lows[trough1] - lows[trough2])
            let avgPrice = (lows[trough1] + lows[trough2]) / 2
            
            if priceDiff / avgPrice < 0.01 {
                let neckline = findNeckline(ohlcData: ohlcData, peak1: trough1, peak2: trough2)
                
                return IntradayPattern(
                    type: .doubleBottom,
                    direction: .bullish,
                    confidence: 0.75,
                    entryPrice: neckline,
                    targetPrice: neckline + (neckline - avgPrice),
                    stopLoss: avgPrice,
                    timeframe: .fifteenMinute,
                    timestamp: Date()
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Momentum Pattern Detection
    
    private func detectMomentumPatterns(ohlcData: [OHLCData], timeframe: Timeframe) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []
        
        guard ohlcData.count >= 14 else { return patterns }
        
        let prices = ohlcData.map { $0.close }
        
        // 1. RSI Momentum
        let rsi = technicalAnalysisEngine.calculateRSI(prices: prices)
        if let rsiPattern = detectRSIMomentum(rsi: rsi, prices: prices) {
            patterns.append(rsiPattern)
        }
        
        // 2. MACD Momentum
        let (macd, signal, histogram) = technicalAnalysisEngine.calculateMACD(prices: prices)
        if let macdPattern = detectMACDMomentum(macd: macd, signal: signal, histogram: histogram, prices: prices) {
            patterns.append(macdPattern)
        }
        
        // 3. Stochastic Momentum
        let highs = ohlcData.map { $0.high }
        let lows = ohlcData.map { $0.low }
        let stochastic = technicalAnalysisEngine.calculateStochastic(highs: highs, lows: lows, closes: prices)
        if let stochPattern = detectStochasticMomentum(stochastic: stochastic, prices: prices) {
            patterns.append(stochPattern)
        }
        
        return patterns
    }
    
    private func detectRSIMomentum(rsi: Double, prices: [Double]) -> IntradayPattern? {
        let currentPrice = prices.last ?? 0
        
        if rsi < 30 {
            // Oversold - potential bullish momentum
            return IntradayPattern(
                type: .rsiOversold,
                direction: .bullish,
                confidence: (30 - rsi) / 30,
                entryPrice: currentPrice,
                targetPrice: currentPrice * 1.02,
                stopLoss: currentPrice * 0.99,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        } else if rsi > 70 {
            // Overbought - potential bearish momentum
            return IntradayPattern(
                type: .rsiOverbought,
                direction: .bearish,
                confidence: (rsi - 70) / 30,
                entryPrice: currentPrice,
                targetPrice: currentPrice * 0.98,
                stopLoss: currentPrice * 1.01,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    // MARK: - Volume Pattern Detection
    
    private func detectVolumePatterns(ohlcData: [OHLCData], volumeData: [VolumeLevel]) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []
        
        // 1. Volume Breakout
        if let volumeBreakout = detectVolumeBreakout(ohlcData: ohlcData) {
            patterns.append(volumeBreakout)
        }
        
        // 2. Volume Divergence
        if let volumeDivergence = detectVolumeDivergence(ohlcData: ohlcData) {
            patterns.append(volumeDivergence)
        }
        
        // 3. Accumulation/Distribution
        if let accumulationPattern = detectAccumulationDistribution(ohlcData: ohlcData) {
            patterns.append(accumulationPattern)
        }
        
        return patterns
    }
    
    // MARK: - Scalping Pattern Detection
    
    private func detectScalpingPatterns(ohlcData: [OHLCData]) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []
        
        guard ohlcData.count >= 5 else { return patterns }
        
        // 1. Quick Reversal Scalp
        if let quickReversal = detectQuickReversalScalp(ohlcData: ohlcData) {
            patterns.append(quickReversal)
        }
        
        // 2. Momentum Scalp
        if let momentumScalp = detectMomentumScalp(ohlcData: ohlcData) {
            patterns.append(momentumScalp)
        }
        
        // 3. Range Scalp
        if let rangeScalp = detectRangeScalp(ohlcData: ohlcData) {
            patterns.append(rangeScalp)
        }
        
        return patterns
    }
    
    // MARK: - Options-Specific Pattern Detection
    
    private func detectOptionsSpecificPatterns(ohlcData: [OHLCData]) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []
        
        // 1. Gamma Squeeze Pattern
        if let gammaSqueezePattern = detectGammaSqueezePattern(ohlcData: ohlcData) {
            patterns.append(gammaSqueezePattern)
        }
        
        // 2. IV Crush Pattern
        if let ivCrushPattern = detectIVCrushPattern(ohlcData: ohlcData) {
            patterns.append(ivCrushPattern)
        }
        
        // 3. Pin Risk Pattern
        if let pinRiskPattern = detectPinRiskPattern(ohlcData: ohlcData) {
            patterns.append(pinRiskPattern)
        }
        
        return patterns
    }
    
    // MARK: - Signal Generation
    
    func generateTradingSignals(from patterns: [IntradayPattern], marketData: RealTimeMarketData) -> [IntradayTradingSignal] {
        var signals: [IntradayTradingSignal] = []
        
        for pattern in patterns {
            if pattern.confidence > 0.6 { // Only generate signals for high-confidence patterns
                let signal = createTradingSignal(from: pattern, marketData: marketData)
                signals.append(signal)
            }
        }
        
        return signals
    }
    
    private func createTradingSignal(from pattern: IntradayPattern, marketData: RealTimeMarketData) -> IntradayTradingSignal {
        let signalType = mapPatternToSignalType(pattern: pattern)
        let optimalContract = findOptimalContract(for: pattern, in: marketData.optionsChain)
        
        return IntradayTradingSignal(
            contract: optimalContract,
            signalType: signalType,
            confidence: pattern.confidence,
            entryPrice: pattern.entryPrice,
            targetPrice: pattern.targetPrice,
            stopLoss: pattern.stopLoss,
            timeframe: pattern.timeframe,
            patterns: [pattern.type.rawValue],
            technicalIndicators: [:], // Add relevant indicators
            timestamp: Date(),
            expiryTime: Date().addingTimeInterval(3600) // 1 hour validity
        )
    }
    
    // MARK: - Helper Methods
    
    private func findPeaks(in data: [Double], minDistance: Int) -> [Int] {
        var peaks: [Int] = []
        
        for i in minDistance..<(data.count - minDistance) {
            let isLocalMax = (i-minDistance..<i).allSatisfy { data[$0] < data[i] } &&
                            (i+1...i+minDistance).allSatisfy { data[$0] < data[i] }
            
            if isLocalMax {
                peaks.append(i)
            }
        }
        
        return peaks
    }
    
    private func findTroughs(in data: [Double], minDistance: Int) -> [Int] {
        var troughs: [Int] = []
        
        for i in minDistance..<(data.count - minDistance) {
            let isLocalMin = (i-minDistance..<i).allSatisfy { data[$0] > data[i] } &&
                            (i+1...i+minDistance).allSatisfy { data[$0] > data[i] }
            
            if isLocalMin {
                troughs.append(i)
            }
        }
        
        return troughs
    }
    
    private func calculateBreakoutConfidence(rangeSize: Double, volumeRatio: Double) -> Double {
        let sizeScore = min(rangeSize / 100, 1.0) // Normalize range size
        let volumeScore = min(volumeRatio / 3.0, 1.0) // Normalize volume ratio
        return (sizeScore + volumeScore) / 2.0
    }
    
    // Additional helper methods would be implemented here...
    
    private func findNeckline(ohlcData: [OHLCData], peak1: Int, peak2: Int) -> Double {
        // Simplified neckline calculation
        let minIndex = min(peak1, peak2)
        let maxIndex = max(peak1, peak2)
        
        let lows = ohlcData[minIndex...maxIndex].map { $0.low }
        return lows.min() ?? 0.0
    }
    
    private func mapPatternToSignalType(pattern: IntradayPattern) -> IntradaySignalType {
        switch pattern.type {
        case .rangeBreakout:
            return pattern.direction == .bullish ? .breakoutBuy : .breakdownSell
        case .doubleTop, .doubleBottom:
            return pattern.direction == .bullish ? .reversalBuy : .reversalSell
        case .rsiOversold, .rsiOverbought:
            return pattern.direction == .bullish ? .momentumBuy : .momentumSell
        default:
            return .scalping
        }
    }
    
    private func findOptimalContract(for pattern: IntradayPattern, in optionsChain: NIFTYOptionsChain) -> NIFTYOptionContract {
        // Find the most suitable option contract based on pattern characteristics
        let atmStrike = optionsChain.getATMStrike()
        let relevantOptions = optionsChain.getOptionsInRange(strikes: 5)
        
        // For now, return ATM option of appropriate type
        if pattern.direction == .bullish {
            return relevantOptions.first { $0.optionType == .call && $0.strikePrice == atmStrike } ?? relevantOptions.first!
        } else {
            return relevantOptions.first { $0.optionType == .put && $0.strikePrice == atmStrike } ?? relevantOptions.first!
        }
    }
    
    // Placeholder implementations for pattern detection methods
    private func detectTriangleBreakout(highs: [Double], lows: [Double], prices: [Double]) -> IntradayPattern? { return nil }
    private func detectFlagBreakout(prices: [Double], volumes: [Int]) -> IntradayPattern? { return nil }
    private func detectSupportResistanceBreakout(prices: [Double], volumes: [Int]) -> IntradayPattern? { return nil }
    private func detectHeadAndShoulders(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectDivergencePatterns(ohlcData: [OHLCData]) -> [IntradayPattern] { return [] }
    private func detectCandlestickReversal(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectMACDMomentum(macd: Double, signal: Double, histogram: Double, prices: [Double]) -> IntradayPattern? { return nil }
    private func detectStochasticMomentum(stochastic: Double, prices: [Double]) -> IntradayPattern? { return nil }
    private func detectVolumeBreakout(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectVolumeDivergence(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectAccumulationDistribution(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectQuickReversalScalp(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectMomentumScalp(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectRangeScalp(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectGammaSqueezePattern(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectIVCrushPattern(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
    private func detectPinRiskPattern(ohlcData: [OHLCData]) -> IntradayPattern? { return nil }
}

// MARK: - Supporting Data Structures

struct IntradayPattern: Identifiable {
    let id = UUID()
    let type: IntradayPatternType
    let direction: PatternDirection
    let confidence: Double
    let entryPrice: Double
    let targetPrice: Double
    let stopLoss: Double
    let timeframe: Timeframe
    let timestamp: Date
}

enum IntradayPatternType: String, CaseIterable {
    case rangeBreakout = "Range Breakout"
    case doubleTop = "Double Top"
    case doubleBottom = "Double Bottom"
    case headAndShoulders = "Head and Shoulders"
    case rsiOversold = "RSI Oversold"
    case rsiOverbought = "RSI Overbought"
    case macdBullish = "MACD Bullish"
    case macdBearish = "MACD Bearish"
    case volumeBreakout = "Volume Breakout"
    case scalping = "Scalping"
    case gammaSqueezePattern = "Gamma Squeeze"
    case ivCrushPattern = "IV Crush"
}

enum PatternDirection: String {
    case bullish = "Bullish"
    case bearish = "Bearish"
    case neutral = "Neutral"
}

struct PatternAlert {
    let pattern: IntradayPattern
    let message: String
    let priority: AlertPriority
    let timestamp: Date
}

enum AlertPriority {
    case high
    case medium
    case low
}

// Supporting analyzer classes
class VolumeAnalyzer {
    // Volume analysis implementation
}

class OrderFlowAnalyzer {
    // Order flow analysis implementation
}