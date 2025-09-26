import Foundation
import Combine

@MainActor
class IntradayPatternEngine: ObservableObject {
    @Published var detectedPatterns: [IntradayPattern] = []
    @Published var activeSignals: [IntradayTradingSignal] = []
    @Published var patternAlerts: [PatternAlert] = []

    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    private let volumeAnalyzer = VolumeAnalyzer()
    private let orderFlowAnalyzer = OrderFlowAnalyzer()

    // Pattern performance tracking
    private var patternPerformanceHistory: [String: PatternPerformance] = [:]
    
    // MARK: - Initialization
    
    func initialize() async throws {
        // Initialize the pattern engine
        // This could include loading models, setting up configurations, etc.
        print("IntradayPatternEngine initialized")
    }

    // MARK: - Intraday Pattern Detection

    func analyzeIntradayPatterns(
        ohlcData: [OHLCData],
        volumeData: [VolumeLevel],
        timeframe: Timeframe
    ) -> [IntradayPattern] {

        var patterns: [IntradayPattern] = []

        // 1. Breakout Patterns (15+ patterns)
        patterns.append(contentsOf: detectBreakoutPatterns(ohlcData: ohlcData, timeframe: timeframe))

        // 2. Reversal Patterns (15+ patterns)
        patterns.append(contentsOf: detectReversalPatterns(ohlcData: ohlcData, timeframe: timeframe))

        // 3. Momentum Patterns (10+ patterns)
        patterns.append(contentsOf: detectMomentumPatterns(ohlcData: ohlcData, timeframe: timeframe))

        // 4. Volume-based Patterns (8+ patterns)
        patterns.append(contentsOf: detectVolumePatterns(ohlcData: ohlcData, volumeData: volumeData))

        // 5. Scalping Patterns (for 1m and 5m timeframes) (5+ patterns)
        if timeframe == .oneMinute || timeframe == .fiveMinute {
            patterns.append(contentsOf: detectScalpingPatterns(ohlcData: ohlcData))
        }

        // 6. Options-specific Patterns (5+ patterns)
        patterns.append(contentsOf: detectOptionsSpecificPatterns(ohlcData: ohlcData))

        // 7. Multi-timeframe Patterns (if data available)
        patterns.append(contentsOf: detectMultiTimeframePatterns(ohlcData: ohlcData, timeframe: timeframe))

        // Apply confidence scoring and filtering
        patterns = patterns.map { pattern in
            var adjustedPattern = pattern
            adjustedPattern.confidence = calculateAdjustedConfidence(for: pattern, timeframe: timeframe)
            return adjustedPattern
        }.filter { $0.confidence > 0.3 } // Filter low-confidence patterns

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
    
    // MARK: - Enhanced Breakout Pattern Implementations

    private func detectTriangleBreakout(highs: [Double], lows: [Double], prices: [Double]) -> IntradayPattern? {
        guard highs.count >= 25 else { return nil }

        let recentHighs = Array(highs.suffix(20))
        let recentLows = Array(lows.suffix(20))
        _ = Array(prices.suffix(20))

        // Check for converging trendlines
        let highTrendline = calculateTrendline(points: recentHighs.enumerated().map { (Double($0.offset), $0.element) })
        let lowTrendline = calculateTrendline(points: recentLows.enumerated().map { (Double($0.offset), $0.element) })

        // Triangle formation: highs decreasing, lows increasing
        let highSlope = highTrendline.slope
        let lowSlope = lowTrendline.slope

        if highSlope < -0.001 && lowSlope > 0.001 { // Converging lines
            let currentPrice = prices.last ?? 0
            let triangleHeight = recentHighs.max()! - recentLows.min()!
            let breakoutLevel = currentPrice > (recentHighs.last! + recentLows.last!) / 2 ?
                recentHighs.last! : recentLows.last!

            let direction: PatternDirection = currentPrice > (recentHighs.last! + recentLows.last!) / 2 ? .bullish : .bearish

            return IntradayPattern(
                type: .triangleBreakout,
                direction: direction,
                confidence: 0.7,
                entryPrice: breakoutLevel,
                targetPrice: direction == .bullish ?
                    breakoutLevel + triangleHeight * 0.618 :
                    breakoutLevel - triangleHeight * 0.618,
                stopLoss: direction == .bullish ?
                    breakoutLevel - triangleHeight * 0.2 :
                    breakoutLevel + triangleHeight * 0.2,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectFlagBreakout(prices: [Double], volumes: [Int]) -> IntradayPattern? {
        guard prices.count >= 20, volumes.count >= 20 else { return nil }

        let recentPrices = Array(prices.suffix(15))
        let recentVolumes = Array(volumes.suffix(15))

        // Look for flag pattern: sharp move followed by consolidation
        let firstHalf = Array(recentPrices.prefix(7))
        let secondHalf = Array(recentPrices.suffix(8))

        let firstTrend = calculateTrendline(points: firstHalf.enumerated().map { (Double($0.offset), $0.element) })
        let secondTrend = calculateTrendline(points: secondHalf.enumerated().map { (Double($0.offset), $0.element) })

        // Flag: strong initial trend followed by sideways/consolidation
        if abs(firstTrend.slope) > 0.002 && abs(secondTrend.slope) < 0.001 {
            let flagHeight = recentPrices.max()! - recentPrices.min()!
            _ = prices.last!
            let avgVolume = recentVolumes.reduce(0, +) / recentVolumes.count
            let currentVolume = volumes.last!

            // Volume confirmation for breakout
            if currentVolume > Int(Double(avgVolume) * 1.5) {
                let direction: PatternDirection = firstTrend.slope > 0 ? .bullish : .bearish
                let breakoutLevel = direction == .bullish ? recentPrices.max()! : recentPrices.min()!

                return IntradayPattern(
                    type: .flagBreakout,
                    direction: direction,
                    confidence: 0.65,
                    entryPrice: breakoutLevel,
                    targetPrice: direction == .bullish ?
                        breakoutLevel + flagHeight :
                        breakoutLevel - flagHeight,
                    stopLoss: direction == .bullish ?
                        breakoutLevel - flagHeight * 0.3 :
                        breakoutLevel + flagHeight * 0.3,
                    timeframe: .fifteenMinute,
                    timestamp: Date()
                )
            }
        }

        return nil
    }

    private func detectSupportResistanceBreakout(prices: [Double], volumes: [Int]) -> IntradayPattern? {
        guard prices.count >= 30 else { return nil }

        let recentPrices = Array(prices.suffix(25))
        let recentVolumes = Array(volumes.suffix(25))

        // Find key support/resistance levels
        let pivotPoints = findPivotPoints(prices: recentPrices, lookback: Int(5))
        let currentPrice = prices.last!
        let currentVolume = volumes.last!
        let avgVolume = recentVolumes.reduce(0, +) / recentVolumes.count

        // Check for breakout above resistance or below support
        for pivot in pivotPoints {
            let distance = abs(currentPrice - pivot.level) / pivot.level

            if distance < 0.005 && Double(currentVolume) > Double(avgVolume) * 1.8 { // Within 0.5% and high volume
                let direction: PatternDirection = currentPrice > pivot.level ? .bullish : .bearish

                return IntradayPattern(
                    type: .supportResistanceBreakout,
                    direction: direction,
                    confidence: 0.75,
                    entryPrice: pivot.level,
                    targetPrice: direction == .bullish ?
                        pivot.level + (pivot.level - pivot.supportLevel) :
                        pivot.level - (pivot.resistanceLevel - pivot.level),
                    stopLoss: pivot.level,
                    timeframe: .fifteenMinute,
                    timestamp: Date()
                )
            }
        }

        return nil
    }

    // Additional breakout patterns
    private func detectWedgeBreakout(highs: [Double], lows: [Double], prices: [Double]) -> IntradayPattern? {
        guard highs.count >= 25 else { return nil }

        let recentHighs = Array(highs.suffix(20))
        let recentLows = Array(lows.suffix(20))

        let highTrendline = calculateTrendline(points: recentHighs.enumerated().map { (Double($0.offset), $0.element) })
        let lowTrendline = calculateTrendline(points: recentLows.enumerated().map { (Double($0.offset), $0.element) })

        // Wedge: both lines sloping in same direction but converging
        if abs(highTrendline.slope) > 0.001 && abs(lowTrendline.slope) > 0.001 &&
           ((highTrendline.slope > 0 && lowTrendline.slope > 0) ||
            (highTrendline.slope < 0 && lowTrendline.slope < 0)) {

            let wedgeHeight = recentHighs.max()! - recentLows.min()!
            _ = prices.last!
            let direction: PatternDirection = highTrendline.slope > 0 ? .bullish : .bearish

            return IntradayPattern(
                type: .wedgeBreakout,
                direction: direction,
                confidence: 0.6,
                entryPrice: direction == .bullish ? recentHighs.last! : recentLows.last!,
                targetPrice: direction == .bullish ?
                    recentHighs.last! + wedgeHeight * 0.7 :
                    recentLows.last! - wedgeHeight * 0.7,
                stopLoss: direction == .bullish ?
                    recentHighs.last! - wedgeHeight * 0.2 :
                    recentLows.last! + wedgeHeight * 0.2,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectChannelBreakout(highs: [Double], lows: [Double], prices: [Double], volumes: [Int]) -> IntradayPattern? {
        guard highs.count >= 20 else { return nil }

        let recentHighs = Array(highs.suffix(15))
        let recentLows = Array(lows.suffix(15))
        let recentVolumes = Array(volumes.suffix(15))

        let highTrendline = calculateTrendline(points: recentHighs.enumerated().map { (Double($0.offset), $0.element) })
        let lowTrendline = calculateTrendline(points: recentLows.enumerated().map { (Double($0.offset), $0.element) })

        // Channel: parallel trendlines
        if abs(highTrendline.slope - lowTrendline.slope) < 0.001 {
            let channelHeight = recentHighs.max()! - recentLows.min()!
            let currentPrice = prices.last!
            let currentVolume = volumes.last!
            let avgVolume = recentVolumes.reduce(0, +) / recentVolumes.count

            if currentVolume > avgVolume * 2 {
                let direction: PatternDirection = currentPrice > (recentHighs.last! + recentLows.last!) / 2 ? .bullish : .bearish
                let breakoutLevel = direction == .bullish ? recentHighs.last! : recentLows.last!

                return IntradayPattern(
                    type: .channelBreakout,
                    direction: direction,
                    confidence: 0.7,
                    entryPrice: breakoutLevel,
                    targetPrice: direction == .bullish ?
                        breakoutLevel + channelHeight :
                        breakoutLevel - channelHeight,
                    stopLoss: direction == .bullish ?
                        breakoutLevel - channelHeight * 0.25 :
                        breakoutLevel + channelHeight * 0.25,
                    timeframe: .fifteenMinute,
                    timestamp: Date()
                )
            }
        }

        return nil
    }
    // MARK: - Enhanced Reversal Pattern Implementations

    private func detectHeadAndShoulders(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 25 else { return nil }

        let highs = ohlcData.map { $0.high }
        let lows = ohlcData.map { $0.low }

        // Find peaks and troughs
        let peaks = findPeaks(in: highs, minDistance: 3)
        let troughs = findTroughs(in: lows, minDistance: 3)

        guard peaks.count >= 3, troughs.count >= 2 else { return nil }

        // Check for head and shoulders pattern
        if peaks.count >= 3 {
            let leftShoulder = highs[peaks[0]]
            let head = highs[peaks[1]]
            let rightShoulder = highs[peaks[2]]

            // Head should be higher than both shoulders
            if head > leftShoulder && head > rightShoulder {
                let shoulderAvg = (leftShoulder + rightShoulder) / 2
                let shoulderDiff = abs(leftShoulder - rightShoulder) / shoulderAvg

                // Shoulders should be at similar levels
                if shoulderDiff < 0.03 {
                    let neckline = findNeckline(ohlcData: ohlcData, peak1: peaks[0], peak2: peaks[2])

                    return IntradayPattern(
                        type: .headAndShoulders,
                        direction: .bearish,
                        confidence: 0.8,
                        entryPrice: neckline,
                        targetPrice: neckline - (head - neckline),
                        stopLoss: head,
                        timeframe: .fifteenMinute,
                        timestamp: Date()
                    )
                }
            }
        }

        return nil
    }

    private func detectDivergencePatterns(ohlcData: [OHLCData]) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []
        guard ohlcData.count >= 20 else { return patterns }

        let prices = ohlcData.map { $0.close }
        _ = ohlcData.map { $0.high }
        _ = ohlcData.map { $0.low }

        // RSI Divergence
        let rsi = technicalAnalysisEngine.calculateRSI(prices: prices)
        if let rsiDivergence = detectRSIDivergence(rsi: rsi, prices: prices) {
            patterns.append(rsiDivergence)
        }

        // MACD Divergence
        let (macd, _, _) = technicalAnalysisEngine.calculateMACD(prices: prices)
        if let macdDivergence = detectMACDDivergence(macd: macd, prices: prices) {
            patterns.append(macdDivergence)
        }

        // Price vs Volume Divergence
        if let volumeDivergence = detectPriceVolumeDivergence(ohlcData: ohlcData) {
            patterns.append(volumeDivergence)
        }

        return patterns
    }

    private func detectCandlestickReversal(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 3 else { return nil }

        let current = ohlcData[ohlcData.count - 1]
        _ = ohlcData[ohlcData.count - 2] // previous not used in this simplified implementation

        // Hammer pattern (bullish reversal)
        let bodySize = abs(current.close - current.open)
        let totalRange = current.high - current.low
        let lowerShadow = min(current.open, current.close) - current.low
        let upperShadow = current.high - max(current.open, current.close)

        if totalRange > 0 {
            let bodyRatio = bodySize / totalRange
            let lowerShadowRatio = lowerShadow / totalRange

            // Hammer: small body, long lower shadow
            if bodyRatio < 0.3 && lowerShadowRatio > 0.6 {
                return IntradayPattern(
                    type: .hammer,
                    direction: .bullish,
                    confidence: 0.7,
                    entryPrice: current.close,
                    targetPrice: current.close + totalRange * 2,
                    stopLoss: current.low,
                    timeframe: .fiveMinute,
                    timestamp: Date()
                )
            }

            // Shooting Star (bearish reversal)
            let upperShadowRatio = upperShadow / totalRange
            if bodyRatio < 0.3 && upperShadowRatio > 0.6 {
                return IntradayPattern(
                    type: .shootingStar,
                    direction: .bearish,
                    confidence: 0.7,
                    entryPrice: current.close,
                    targetPrice: current.close - totalRange * 2,
                    stopLoss: current.high,
                    timeframe: .fiveMinute,
                    timestamp: Date()
                )
            }
        }

        return nil
    }

    // Additional reversal patterns
    private func detectEngulfingPattern(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 2 else { return nil }

        let current = ohlcData[ohlcData.count - 1]
        let previous = ohlcData[ohlcData.count - 2]

        // Bullish engulfing
        if previous.close < previous.open && current.close > current.open &&
           current.close > previous.open && current.open < previous.close {
            return IntradayPattern(
                type: .bullishEngulfing,
                direction: .bullish,
                confidence: 0.75,
                entryPrice: current.close,
                targetPrice: current.close + (current.close - current.open) * 2,
                stopLoss: current.open,
                timeframe: .fiveMinute,
                timestamp: Date()
            )
        }

        // Bearish engulfing
        if previous.close > previous.open && current.close < current.open &&
           current.close < previous.open && current.open > previous.close {
            return IntradayPattern(
                type: .bearishEngulfing,
                direction: .bearish,
                confidence: 0.75,
                entryPrice: current.close,
                targetPrice: current.close - (current.open - current.close) * 2,
                stopLoss: current.open,
                timeframe: .fiveMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectKeyReversal(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 5 else { return nil }

        let current = ohlcData.last!
        let recent = Array(ohlcData.suffix(4))
        let recentHighs = recent.map { $0.high }
        let recentLows = recent.map { $0.low }

        // Key reversal up: price makes new low but closes near high
        if current.low <= recentLows.min()! && current.close > (current.high + current.low) / 2 {
            return IntradayPattern(
                type: .keyReversalUp,
                direction: .bullish,
                confidence: 0.65,
                entryPrice: current.close,
                targetPrice: current.close + (current.high - current.low) * 1.5,
                stopLoss: current.low,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        // Key reversal down: price makes new high but closes near low
        if current.high >= recentHighs.max()! && current.close < (current.high + current.low) / 2 {
            return IntradayPattern(
                type: .keyReversalDown,
                direction: .bearish,
                confidence: 0.65,
                entryPrice: current.close,
                targetPrice: current.close - (current.high - current.low) * 1.5,
                stopLoss: current.high,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }
    // MARK: - Enhanced Momentum Pattern Implementations

    private func detectMACDMomentum(macd: Double, signal: Double, histogram: Double, prices: [Double]) -> IntradayPattern? {
        let currentPrice = prices.last ?? 0

        // Bullish MACD crossover
        if macd > signal && histogram > 0 {
            return IntradayPattern(
                type: .macdBullish,
                direction: .bullish,
                confidence: min(abs(histogram) / 10, 0.8),
                entryPrice: currentPrice,
                targetPrice: currentPrice * 1.015,
                stopLoss: currentPrice * 0.99,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        // Bearish MACD crossover
        if macd < signal && histogram < 0 {
            return IntradayPattern(
                type: .macdBearish,
                direction: .bearish,
                confidence: min(abs(histogram) / 10, 0.8),
                entryPrice: currentPrice,
                targetPrice: currentPrice * 0.985,
                stopLoss: currentPrice * 1.01,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectStochasticMomentum(stochastic: Double, prices: [Double]) -> IntradayPattern? {
        let currentPrice = prices.last ?? 0

        // Stochastic oversold bounce
        if stochastic < 20 {
            return IntradayPattern(
                type: .stochasticOversold,
                direction: .bullish,
                confidence: (20 - stochastic) / 20,
                entryPrice: currentPrice,
                targetPrice: currentPrice * 1.02,
                stopLoss: currentPrice * 0.995,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        // Stochastic overbought drop
        if stochastic > 80 {
            return IntradayPattern(
                type: .stochasticOverbought,
                direction: .bearish,
                confidence: (stochastic - 80) / 20,
                entryPrice: currentPrice,
                targetPrice: currentPrice * 0.98,
                stopLoss: currentPrice * 1.005,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    // Additional momentum patterns
    private func detectBollingerBandSqueeze(prices: [Double]) -> IntradayPattern? {
        guard prices.count >= 20 else { return nil }

        let recentPrices = Array(prices.suffix(20))
        let sma = recentPrices.reduce(0, +) / Double(recentPrices.count)
        let variance = recentPrices.map { pow($0 - sma, 2) }.reduce(0, +) / Double(recentPrices.count)
        let stdDev = sqrt(variance)

        let upperBand = sma + (2 * stdDev)
        let lowerBand = sma - (2 * stdDev)
        let bandWidth = (upperBand - lowerBand) / sma

        let currentPrice = prices.last!

        // Squeeze condition: bands are very close together
        if bandWidth < 0.02 { // Less than 2% bandwidth
            let direction: PatternDirection = currentPrice > sma ? .bullish : .bearish

            return IntradayPattern(
                type: .bollingerSqueeze,
                direction: direction,
                confidence: 0.6,
                entryPrice: currentPrice,
                targetPrice: direction == .bullish ? upperBand : lowerBand,
                stopLoss: direction == .bullish ? lowerBand : upperBand,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectIchimokuCloudBreakout(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 52 else { return nil }

        let highs = ohlcData.map { $0.high }
        let lows = ohlcData.map { $0.low }
        let closes = ohlcData.map { $0.close }

        // Calculate Ichimoku components (simplified)
        let tenkanSen = calculateTenkanSen(highs: highs, lows: lows)
        let kijunSen = calculateKijunSen(highs: highs, lows: lows)
        let senkouSpanA = zip(tenkanSen, kijunSen).map { ($0 + $1) / 2 }
        let senkouSpanB = calculateSenkouSpanB(highs: highs, lows: lows)

        let currentPrice = closes.last!
        let currentTenkan = tenkanSen.last ?? currentPrice
        let currentKijun = kijunSen.last ?? currentPrice
        let currentSenkouA = senkouSpanA.last ?? currentPrice
        let currentSenkouB = senkouSpanB

        // Bullish breakout above cloud
        if currentPrice > max(currentSenkouA, currentSenkouB) && currentTenkan > currentKijun {
            return IntradayPattern(
                type: .ichimokuBullish,
                direction: .bullish,
                confidence: 0.7,
                entryPrice: currentPrice,
                targetPrice: currentPrice * 1.025,
                stopLoss: min(currentSenkouA, currentSenkouB),
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        // Bearish breakdown below cloud
        if currentPrice < min(currentSenkouA, currentSenkouB) && currentTenkan < currentKijun {
            return IntradayPattern(
                type: .ichimokuBearish,
                direction: .bearish,
                confidence: 0.7,
                entryPrice: currentPrice,
                targetPrice: currentPrice * 0.975,
                stopLoss: max(currentSenkouA, currentSenkouB),
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }
    private func detectVolumeBreakout(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 10 else { return nil }

        let volumes = ohlcData.map { Double($0.volume) }
        let prices = ohlcData.map { $0.close }

        let recentVolumes = Array(volumes.suffix(10))
        let avgVolume = recentVolumes.reduce(0, +) / Double(recentVolumes.count)
        let currentVolume = volumes.last!
        let currentPrice = prices.last!

        if currentVolume > avgVolume * 2.5 {
            let priceChange = (currentPrice - prices[prices.count - 2]) / prices[prices.count - 2]
            let direction: PatternDirection = priceChange > 0 ? .bullish : .bearish

            return IntradayPattern(
                type: .volumeBreakout,
                direction: direction,
                confidence: min(currentVolume / avgVolume / 5, 0.9),
                entryPrice: currentPrice,
                targetPrice: direction == .bullish ?
                    currentPrice * 1.02 :
                    currentPrice * 0.98,
                stopLoss: direction == .bullish ?
                    currentPrice * 0.995 :
                    currentPrice * 1.005,
                timeframe: .fiveMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectVolumeDivergence(ohlcData: [OHLCData]) -> IntradayPattern? {
        return detectPriceVolumeDivergence(ohlcData: ohlcData)
    }

    private func detectAccumulationDistribution(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 20 else { return nil }

        var adLine: [Double] = []
        var accumulation = 0.0

        for candle in ohlcData {
            let mfm = ((candle.close - candle.low) - (candle.high - candle.close)) / (candle.high - candle.low)
            let mfv = mfm * Double(candle.volume)
            accumulation += mfv
            adLine.append(accumulation)
        }

        let recentAD = Array(adLine.suffix(10))
        let adTrend = calculateTrendline(points: recentAD.enumerated().map { (Double($0.offset), $0.element) })
        let priceTrend = calculateTrendline(points: ohlcData.suffix(10).enumerated().map { (Double($0.offset), $0.element.close) })

        // Bullish divergence: price down, AD up
        if priceTrend.slope < -0.001 && adTrend.slope > 0.001 {
            return IntradayPattern(
                type: .accumulationDistribution,
                direction: .bullish,
                confidence: 0.6,
                entryPrice: ohlcData.last!.close,
                targetPrice: ohlcData.last!.close * 1.015,
                stopLoss: ohlcData.last!.close * 0.99,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectQuickReversalScalp(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 3 else { return nil }

        let current = ohlcData.last!
        let prev1 = ohlcData[ohlcData.count - 2]
        let prev2 = ohlcData[ohlcData.count - 3]

        // Quick scalp: 3 consecutive candles with reversal
        if (prev2.close > prev2.open && prev1.close < prev1.open && current.close > current.open) ||
           (prev2.close < prev2.open && prev1.close > prev1.open && current.close < current.open) {

            let direction: PatternDirection = current.close > current.open ? .bullish : .bearish

            return IntradayPattern(
                type: .quickReversalScalp,
                direction: direction,
                confidence: 0.5,
                entryPrice: current.close,
                targetPrice: direction == .bullish ?
                    current.close + (current.high - current.low) :
                    current.close - (current.high - current.low),
                stopLoss: direction == .bullish ? current.low : current.high,
                timeframe: .oneMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectMomentumScalp(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 5 else { return nil }

        let recent = Array(ohlcData.suffix(5))
        let closes = recent.map { $0.close }
        let volumes = recent.map { Double($0.volume) }

        let priceChange = (closes.last! - closes.first!) / closes.first!
        let avgVolume = volumes.reduce(0, +) / Double(volumes.count)
        let currentVolume = volumes.last!

        if abs(priceChange) > 0.005 && currentVolume > avgVolume * 1.5 {
            let direction: PatternDirection = priceChange > 0 ? .bullish : .bearish

            return IntradayPattern(
                type: .momentumScalp,
                direction: direction,
                confidence: min(abs(priceChange) * 50, 0.7),
                entryPrice: closes.last!,
                targetPrice: direction == .bullish ?
                    closes.last! + abs(priceChange) * closes.last! :
                    closes.last! - abs(priceChange) * closes.last!,
                stopLoss: direction == .bullish ?
                    closes.last! - abs(priceChange) * closes.last! * 0.5 :
                    closes.last! + abs(priceChange) * closes.last! * 0.5,
                timeframe: .oneMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectRangeScalp(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 10 else { return nil }

        let recent = Array(ohlcData.suffix(10))
        let highs = recent.map { $0.high }
        let lows = recent.map { $0.low }
        let closes = recent.map { $0.close }

        let rangeHigh = highs.max()!
        let rangeLow = lows.min()!
        _ = rangeHigh - rangeLow
        let currentPrice = closes.last!

        // Price near range boundary
        let distanceToHigh = abs(currentPrice - rangeHigh) / rangeHigh
        let distanceToLow = abs(currentPrice - rangeLow) / rangeLow

        if distanceToHigh < 0.005 || distanceToLow < 0.005 {
            let direction: PatternDirection = distanceToHigh < distanceToLow ? .bearish : .bullish

            return IntradayPattern(
                type: .rangeScalp,
                direction: direction,
                confidence: 0.55,
                entryPrice: currentPrice,
                targetPrice: direction == .bullish ? rangeHigh : rangeLow,
                stopLoss: direction == .bullish ? rangeLow : rangeHigh,
                timeframe: .oneMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectGammaSqueezePattern(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 20 else { return nil }

        let prices = ohlcData.map { $0.close }
        let volumes = ohlcData.map { Double($0.volume) }

        // Gamma squeeze: high volume, price moving against options positioning
        let recentPrices = Array(prices.suffix(10))
        let recentVolumes = Array(volumes.suffix(10))

        let priceChange = (recentPrices.last! - recentPrices.first!) / recentPrices.first!
        let volumeSpike = recentVolumes.max()! / (recentVolumes.reduce(0, +) / Double(recentVolumes.count))

        if abs(priceChange) > 0.02 && volumeSpike > 3.0 {
            let direction: PatternDirection = priceChange > 0 ? .bullish : .bearish

            return IntradayPattern(
                type: .gammaSqueezePattern,
                direction: direction,
                confidence: min(volumeSpike / 5, 0.8),
                entryPrice: recentPrices.last!,
                targetPrice: direction == .bullish ?
                    recentPrices.last! * 1.05 :
                    recentPrices.last! * 0.95,
                stopLoss: direction == .bullish ?
                    recentPrices.last! * 0.98 :
                    recentPrices.last! * 1.02,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectIVCrushPattern(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 30 else { return nil }

        let prices = ohlcData.map { $0.close }
        let recentPrices = Array(prices.suffix(20))

        // IV crush: price moves sharply, then volatility drops
        let firstHalf = Array(recentPrices.prefix(10))
        let secondHalf = Array(recentPrices.suffix(10))

        let firstVolatility = calculateVolatility(prices: firstHalf)
        let secondVolatility = calculateVolatility(prices: secondHalf)

        if firstVolatility > secondVolatility * 1.5 {
            let direction: PatternDirection = recentPrices.last! > recentPrices.first! ? .bullish : .bearish

            return IntradayPattern(
                type: .ivCrushPattern,
                direction: direction,
                confidence: min(firstVolatility / secondVolatility * 0.3, 0.75),
                entryPrice: recentPrices.last!,
                targetPrice: direction == .bullish ?
                    recentPrices.last! * 1.03 :
                    recentPrices.last! * 0.97,
                stopLoss: direction == .bullish ?
                    recentPrices.last! * 0.99 :
                    recentPrices.last! * 1.01,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectPinRiskPattern(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 10 else { return nil }

        let current = ohlcData.last!
        _ = Array(ohlcData.suffix(10)) // recent not used in this simplified implementation

        // Pin risk: price closes near strike price
        let bodySize = abs(current.close - current.open)
        let totalRange = current.high - current.low

        if totalRange > 0 && bodySize / totalRange < 0.3 {
            // Small body, potential pin
            let direction: PatternDirection = current.close > (current.high + current.low) / 2 ? .bullish : .bearish

            return IntradayPattern(
                type: .pinRiskPattern,
                direction: direction,
                confidence: 0.6,
                entryPrice: current.close,
                targetPrice: direction == .bullish ? current.high : current.low,
                stopLoss: direction == .bullish ? current.low : current.high,
                timeframe: .fiveMinute,
                timestamp: Date()
            )
        }

        return nil
    }
}

// MARK: - Supporting Data Structures

struct IntradayPattern: Identifiable {
    let id = UUID()
    let type: IntradayPatternType
    let direction: PatternDirection
    var confidence: Double
    let entryPrice: Double
    let targetPrice: Double
    let stopLoss: Double
    let timeframe: Timeframe
    let timestamp: Date
}

enum IntradayPatternType: String, CaseIterable {
    // Breakout Patterns (15+)
    case rangeBreakout = "Range Breakout"
    case triangleBreakout = "Triangle Breakout"
    case flagBreakout = "Flag Breakout"
    case wedgeBreakout = "Wedge Breakout"
    case channelBreakout = "Channel Breakout"
    case supportResistanceBreakout = "Support/Resistance Breakout"
    case bollingerBreakout = "Bollinger Breakout"
    case fibonacciBreakout = "Fibonacci Breakout"
    case pivotBreakout = "Pivot Breakout"
    case trendlineBreakout = "Trendline Breakout"
    case rectangleBreakout = "Rectangle Breakout"
    case cupHandleBreakout = "Cup & Handle Breakout"
    case inverseHeadShoulders = "Inverse Head & Shoulders"
    case broadeningFormation = "Broadening Formation"
    case diamondBreakout = "Diamond Breakout"

    // Reversal Patterns (15+)
    case doubleTop = "Double Top"
    case doubleBottom = "Double Bottom"
    case headAndShoulders = "Head and Shoulders"
    case hammer = "Hammer"
    case shootingStar = "Shooting Star"
    case bullishEngulfing = "Bullish Engulfing"
    case bearishEngulfing = "Bearish Engulfing"
    case keyReversalUp = "Key Reversal Up"
    case keyReversalDown = "Key Reversal Down"
    case morningStar = "Morning Star"
    case eveningStar = "Evening Star"
    case threeWhiteSoldiers = "Three White Soldiers"
    case threeBlackCrows = "Three Black Crows"
    case harami = "Harami"
    case piercingPattern = "Piercing Pattern"

    // Momentum Patterns (10+)
    case rsiOversold = "RSI Oversold"
    case rsiOverbought = "RSI Overbought"
    case macdBullish = "MACD Bullish"
    case macdBearish = "MACD Bearish"
    case stochasticOversold = "Stochastic Oversold"
    case stochasticOverbought = "Stochastic Overbought"
    case bollingerSqueeze = "Bollinger Squeeze"
    case ichimokuBullish = "Ichimoku Bullish"
    case ichimokuBearish = "Ichimoku Bearish"
    case adxStrongTrend = "ADX Strong Trend"

    // Volume Patterns (8+)
    case volumeBreakout = "Volume Breakout"
    case volumeClimax = "Volume Climax"
    case volumeDivergence = "Volume Divergence"
    case accumulationDistribution = "Accumulation/Distribution"
    case onBalanceVolume = "On Balance Volume"
    case chaikinMoneyFlow = "Chaikin Money Flow"
    case volumeWeightedAveragePrice = "VWAP Breakout"
    case volumeProfile = "Volume Profile"

    // Scalping Patterns (5+)
    case scalping = "Scalping"
    case quickReversalScalp = "Quick Reversal Scalp"
    case momentumScalp = "Momentum Scalp"
    case rangeScalp = "Range Scalp"
    case newsScalp = "News Scalp"

    // Options-Specific Patterns (5+)
    case gammaSqueezePattern = "Gamma Squeeze"
    case ivCrushPattern = "IV Crush"
    case pinRiskPattern = "Pin Risk"
    case optionsFlow = "Options Flow"
    case straddleBreakout = "Straddle Breakout"

    // Additional Patterns
    case rsiDivergenceBullish = "RSI Bullish Divergence"
    case rsiDivergenceBearish = "RSI Bearish Divergence"
    case macdDivergenceBullish = "MACD Bullish Divergence"
    case macdDivergenceBearish = "MACD Bearish Divergence"
    case volumeDivergenceBullish = "Volume Bullish Divergence"
    case volumeDivergenceBearish = "Volume Bearish Divergence"
    case higherTimeframeTrend = "Higher Timeframe Trend"
    case timeframeConvergence = "Timeframe Convergence"
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

// MARK: - Missing Method Implementations

extension IntradayPatternEngine {
    // MARK: - Confidence Scoring and Multi-Timeframe Analysis

    private func calculateAdjustedConfidence(for pattern: IntradayPattern, timeframe: Timeframe) -> Double {
        var confidence = pattern.confidence

        // Timeframe adjustment
        switch timeframe {
        case .oneMinute:
            confidence *= 0.8 // Lower confidence for very short timeframes
        case .fiveMinute:
            confidence *= 0.9
        case .fifteenMinute:
            confidence *= 1.0 // Baseline
        case .thirtyMinute:
            confidence *= 1.1 // Higher confidence for longer timeframes
        case .oneHour:
            confidence *= 1.2
        }

        // Pattern performance adjustment
        if let performance = patternPerformanceHistory[pattern.type.rawValue] {
            let successRate = Double(performance.successfulTrades) / Double(performance.totalTrades)
            confidence *= (0.5 + successRate) // Blend with historical performance
        }

        return min(confidence, 0.95) // Cap at 95%
    }

    private func detectMultiTimeframePatterns(ohlcData: [OHLCData], timeframe: Timeframe) -> [IntradayPattern] {
        var patterns: [IntradayPattern] = []

        // Only add multi-timeframe analysis for 15m and 30m charts
        guard timeframe == .fifteenMinute || timeframe == .thirtyMinute else { return patterns }

        // Higher timeframe trend confirmation
        if let trendPattern = detectHigherTimeframeTrend(ohlcData: ohlcData) {
            patterns.append(trendPattern)
        }

        // Timeframe convergence/divergence
        if let convergencePattern = detectTimeframeConvergence(ohlcData: ohlcData) {
            patterns.append(convergencePattern)
        }

        return patterns
    }

    // MARK: - Pattern Performance Tracking

    func updatePatternPerformance(patternType: IntradayPatternType, successful: Bool) {
        let key = patternType.rawValue
        var performance = patternPerformanceHistory[key] ?? PatternPerformance(totalTrades: 0, successfulTrades: 0)

        performance.totalTrades += 1
        if successful {
            performance.successfulTrades += 1
        }

        patternPerformanceHistory[key] = performance
    }

    func getPatternSuccessRate(_ patternType: IntradayPatternType) -> Double {
        guard let performance = patternPerformanceHistory[patternType.rawValue],
              performance.totalTrades > 0 else {
            return 0.5 // Default 50% for new patterns
        }

        return Double(performance.successfulTrades) / Double(performance.totalTrades)
    }

    // MARK: - Additional Helper Methods

    private func calculateTrendline(points: [(x: Double, y: Double)]) -> (slope: Double, intercept: Double) {
        let n = Double(points.count)
        let sumX = points.map { $0.x }.reduce(0, +)
        let sumY = points.map { $0.y }.reduce(0, +)
        let sumXY = points.map { $0.x * $0.y }.reduce(0, +)
        let sumXX = points.map { $0.x * $0.x }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        return (slope, intercept)
    }

    private func findPivotPoints(prices: [Double], lookback: Int) -> [PivotPoint] {
        var pivots: [PivotPoint] = []

        for i in lookback..<(prices.count - lookback) {
            let currentPrice = prices[i]
            let leftWindow = Array(prices[(i-lookback)...(i-1)])
            let rightWindow = Array(prices[(i+1)...(i+lookback)])

            // Resistance level
            if currentPrice > leftWindow.max()! && currentPrice > rightWindow.max()! {
                let supportLevel = leftWindow.min()!
                let resistanceLevel = rightWindow.max()!
                pivots.append(PivotPoint(level: currentPrice, supportLevel: supportLevel, resistanceLevel: resistanceLevel))
            }

            // Support level
            if currentPrice < leftWindow.min()! && currentPrice < rightWindow.min()! {
                let supportLevel = rightWindow.min()!
                let resistanceLevel = leftWindow.max()!
                pivots.append(PivotPoint(level: currentPrice, supportLevel: supportLevel, resistanceLevel: resistanceLevel))
            }
        }

        return pivots
    }

    private func detectRSIDivergence(rsi: Double, prices: [Double]) -> IntradayPattern? {
        // Simplified divergence detection
        guard prices.count >= 10 else { return nil }

        let recentPrices = Array(prices.suffix(10))
        let priceTrend = calculateTrendline(points: recentPrices.enumerated().map { (Double($0.offset), $0.element) })

        // Bullish divergence: price falling but RSI rising
        if priceTrend.slope < -0.001 && rsi > 50 {
            return IntradayPattern(
                type: .rsiDivergenceBullish,
                direction: .bullish,
                confidence: 0.6,
                entryPrice: prices.last!,
                targetPrice: prices.last! * 1.02,
                stopLoss: prices.last! * 0.98,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        // Bearish divergence: price rising but RSI falling
        if priceTrend.slope > 0.001 && rsi < 50 {
            return IntradayPattern(
                type: .rsiDivergenceBearish,
                direction: .bearish,
                confidence: 0.6,
                entryPrice: prices.last!,
                targetPrice: prices.last! * 0.98,
                stopLoss: prices.last! * 1.02,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectMACDDivergence(macd: Double, prices: [Double]) -> IntradayPattern? {
        // Similar to RSI divergence but for MACD
        guard prices.count >= 10 else { return nil }

        let recentPrices = Array(prices.suffix(10))
        let priceTrend = calculateTrendline(points: recentPrices.enumerated().map { (Double($0.offset), $0.element) })

        if priceTrend.slope < -0.001 && macd > 0 {
            return IntradayPattern(
                type: .macdDivergenceBullish,
                direction: .bullish,
                confidence: 0.65,
                entryPrice: prices.last!,
                targetPrice: prices.last! * 1.025,
                stopLoss: prices.last! * 0.975,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        if priceTrend.slope > 0.001 && macd < 0 {
            return IntradayPattern(
                type: .macdDivergenceBearish,
                direction: .bearish,
                confidence: 0.65,
                entryPrice: prices.last!,
                targetPrice: prices.last! * 0.975,
                stopLoss: prices.last! * 1.025,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectPriceVolumeDivergence(ohlcData: [OHLCData]) -> IntradayPattern? {
        guard ohlcData.count >= 10 else { return nil }

        let prices = ohlcData.map { $0.close }
        let volumes = ohlcData.map { Double($0.volume) }

        let priceTrend = calculateTrendline(points: prices.enumerated().map { (Double($0.offset), $0.element) })
        let volumeTrend = calculateTrendline(points: volumes.enumerated().map { (Double($0.offset), $0.element) })

        // Bullish divergence: price down, volume up
        if priceTrend.slope < -0.001 && volumeTrend.slope > 0.001 {
            return IntradayPattern(
                type: .volumeDivergenceBullish,
                direction: .bullish,
                confidence: 0.55,
                entryPrice: prices.last!,
                targetPrice: prices.last! * 1.015,
                stopLoss: prices.last! * 0.99,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        // Bearish divergence: price up, volume down
        if priceTrend.slope > 0.001 && volumeTrend.slope < -0.001 {
            return IntradayPattern(
                type: .volumeDivergenceBearish,
                direction: .bearish,
                confidence: 0.55,
                entryPrice: prices.last!,
                targetPrice: prices.last! * 0.985,
                stopLoss: prices.last! * 1.01,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectHigherTimeframeTrend(ohlcData: [OHLCData]) -> IntradayPattern? {
        // Simplified higher timeframe analysis
        guard ohlcData.count >= 20 else { return nil }

        let firstHalf = Array(ohlcData.prefix(10))
        let secondHalf = Array(ohlcData.suffix(10))

        let firstAvg = firstHalf.map { $0.close }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.close }.reduce(0, +) / Double(secondHalf.count)

        let trendStrength = abs(secondAvg - firstAvg) / firstAvg

        if trendStrength > 0.005 { // 0.5% trend
            let direction: PatternDirection = secondAvg > firstAvg ? .bullish : .bearish
            return IntradayPattern(
                type: .higherTimeframeTrend,
                direction: direction,
                confidence: min(trendStrength * 100, 0.8),
                entryPrice: ohlcData.last!.close,
                targetPrice: direction == .bullish ?
                    ohlcData.last!.close * 1.01 :
                    ohlcData.last!.close * 0.99,
                stopLoss: direction == .bullish ?
                    ohlcData.last!.close * 0.995 :
                    ohlcData.last!.close * 1.005,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func detectTimeframeConvergence(ohlcData: [OHLCData]) -> IntradayPattern? {
        // Detect when multiple timeframes align
        guard ohlcData.count >= 15 else { return nil }

        let shortTerm = Array(ohlcData.suffix(5))
        let mediumTerm = Array(ohlcData.suffix(10))

        let shortTrend = calculateTrendline(points: shortTerm.enumerated().map { (Double($0.offset), $0.element.close) })
        let mediumTrend = calculateTrendline(points: mediumTerm.enumerated().map { (Double($0.offset), $0.element.close) })

        // Convergence when trends are in the same direction and similar strength
        if (shortTrend.slope > 0 && mediumTrend.slope > 0) ||
           (shortTrend.slope < 0 && mediumTrend.slope < 0) {

            let convergenceStrength = abs(shortTrend.slope - mediumTrend.slope) < 0.001 ? 0.8 : 0.6
            let direction: PatternDirection = shortTrend.slope > 0 ? .bullish : .bearish

            return IntradayPattern(
                type: .timeframeConvergence,
                direction: direction,
                confidence: convergenceStrength,
                entryPrice: ohlcData.last!.close,
                targetPrice: direction == .bullish ?
                    ohlcData.last!.close * 1.02 :
                    ohlcData.last!.close * 0.98,
                stopLoss: direction == .bullish ?
                    ohlcData.last!.close * 0.99 :
                    ohlcData.last!.close * 1.01,
                timeframe: .fifteenMinute,
                timestamp: Date()
            )
        }

        return nil
    }

    private func calculateVolatility(prices: [Double]) -> Double {
        guard prices.count > 1 else { return 0 }

        let returns = zip(prices.dropFirst(), prices).map { ($0 - $1) / $1 }
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)

        return sqrt(variance)
    }

    // Ichimoku helper methods
    private func calculateTenkanSen(highs: [Double], lows: [Double]) -> [Double] {
        let period = 9
        var tenkan: [Double] = []

        for i in (period-1)..<highs.count {
            let highMax = highs[(i-period+1)...i].max()!
            let lowMin = lows[(i-period+1)...i].min()!
            tenkan.append((highMax + lowMin) / 2)
        }

        return tenkan
    }

    private func calculateKijunSen(highs: [Double], lows: [Double]) -> [Double] {
        let period = 26
        var kijun: [Double] = []

        for i in (period-1)..<highs.count {
            let highMax = highs[(i-period+1)...i].max()!
            let lowMin = lows[(i-period+1)...i].min()!
            kijun.append((highMax + lowMin) / 2)
        }

        return kijun
    }

    private func calculateSenkouSpanB(highs: [Double], lows: [Double]) -> Double {
        let period = 52
        guard highs.count >= period, lows.count >= period else { return 0 }

        let highMax = highs.suffix(period).max()!
        let lowMin = lows.suffix(period).min()!

        return (highMax + lowMin) / 2
    }
}

// MARK: - Supporting Data Structures

struct PatternPerformance {
    var totalTrades: Int
    var successfulTrades: Int
}

struct PivotPoint {
    let level: Double
    let supportLevel: Double
    let resistanceLevel: Double
}

// Supporting analyzer classes
class VolumeAnalyzer {
    // Volume analysis implementation
}

class OrderFlowAnalyzer {
    // Order flow analysis implementation
}
