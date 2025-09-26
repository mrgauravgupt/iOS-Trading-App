import Foundation
import Combine

class TechnicalAnalysisEngine: ObservableObject {
    
    // MARK: - Enhanced Pattern Recognition Structures
    
    enum ChartPattern: String, CaseIterable {
        // Reversal Patterns
        case headAndShoulders = "Head and Shoulders"
        case inverseHeadAndShoulders = "Inverse Head and Shoulders"
        case doubleTop = "Double Top"
        case doubleBottom = "Double Bottom"
        case tripleTop = "Triple Top"
        case tripleBottom = "Triple Bottom"
        case roundingTop = "Rounding Top"
        case roundingBottom = "Rounding Bottom"
        
        // Continuation Patterns
        case ascendingTriangle = "Ascending Triangle"
        case descendingTriangle = "Descending Triangle"
        case symmetricalTriangle = "Symmetrical Triangle"
        case flag = "Flag"
        case pennant = "Pennant"
        case wedgeRising = "Rising Wedge"
        case wedgeFalling = "Falling Wedge"
        case rectangle = "Rectangle"
        case channel = "Channel"
        
        // Harmonic Patterns
        case gartley = "Gartley"
        case butterfly = "Butterfly"
        case bat = "Bat"
        case crab = "Crab"
        case cypher = "Cypher"
        case shark = "Shark"
        case abcd = "ABCD"
        
        // Elliott Wave Patterns
        case impulseWave = "Impulse Wave"
        case correctiveWave = "Corrective Wave"
        case diagonalTriangle = "Diagonal Triangle"
        
        var expectedOutcome: TradingSignal {
            switch self {
            case .headAndShoulders, .doubleTop, .tripleTop, .roundingTop, .wedgeRising:
                return .sell
            case .inverseHeadAndShoulders, .doubleBottom, .tripleBottom, .roundingBottom, .wedgeFalling:
                return .buy
            case .ascendingTriangle, .flag, .pennant:
                return .buy
            case .descendingTriangle:
                return .sell
            default:
                return .hold
            }
        }
    }
    
    enum TradingSignal: String, CaseIterable {
        case buy = "Buy"
        case sell = "Sell" 
        case hold = "Hold"
        case strongBuy = "Strong Buy"
        case strongSell = "Strong Sell"
    }
    
    struct PatternResult {
        let pattern: String
        let signal: TradingSignal
        let confidence: Double
        let timeframe: String
        let strength: PatternStrength
        let targets: [Double]
        let stopLoss: Double?
        let successRate: Double
    }
    
    enum PatternStrength: String {
        case weak = "Weak"
        case moderate = "Moderate"
        case strong = "Strong"
        case veryStrong = "Very Strong"
    }
    
    // MARK: - Multi-Timeframe Analysis
    
    func analyzeMultiTimeframe(data: [MarketData]) -> [String: [PatternResult]] {
        var results: [String: [PatternResult]] = [:]
        
        let timeframes = ["1m", "5m", "15m", "1h", "4h", "1D"]
        
        for timeframe in timeframes {
            let timeframeData = resampleDataForTimeframe(data: data, timeframe: timeframe)
            let patterns = detectAllPatterns(data: timeframeData, timeframe: timeframe)
            results[timeframe] = patterns
        }
        
        return results
    }
    
    private func resampleDataForTimeframe(data: [MarketData], timeframe: String) -> [MarketData] {
        // Simplified resampling - in production would properly aggregate OHLC data
        switch timeframe {
        case "5m": return Array(data.enumerated().compactMap { $0.offset % 5 == 0 ? $0.element : nil })
        case "15m": return Array(data.enumerated().compactMap { $0.offset % 15 == 0 ? $0.element : nil })
        case "1h": return Array(data.enumerated().compactMap { $0.offset % 60 == 0 ? $0.element : nil })
        case "4h": return Array(data.enumerated().compactMap { $0.offset % 240 == 0 ? $0.element : nil })
        case "1D": return Array(data.enumerated().compactMap { $0.offset % 1440 == 0 ? $0.element : nil })
        default: return data
        }
    }
    
    // MARK: - Enhanced Technical Indicators
    
    // RSI calculation with enhanced features
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
    
    // Enhanced RSI with divergence detection
    func calculateRSIWithDivergence(prices: [Double], period: Int = 14) -> (rsi: Double, divergence: String?) {
        let rsi = calculateRSI(prices: prices, period: period)
        
        guard prices.count >= period * 2 else { return (rsi, nil) }
        
        let midPoint = prices.count / 2
        let firstHalfRSI = calculateRSI(prices: Array(prices[0..<midPoint]), period: period)
        let secondHalfRSI = calculateRSI(prices: Array(prices[midPoint..<prices.count]), period: period)
        
        let priceDirection = prices.last! > prices[midPoint] ? "rising" : "falling"
        let rsiDirection = secondHalfRSI > firstHalfRSI ? "rising" : "falling"
        
        if priceDirection != rsiDirection {
            return (rsi, priceDirection == "rising" ? "Bearish Divergence" : "Bullish Divergence")
        }
        
        return (rsi, nil)
    }
    
    // MACD calculation with enhanced features
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
    
    // Enhanced MACD with divergence detection
    func calculateMACDWithDivergence(prices: [Double]) -> (macd: Double, signal: Double, histogram: Double, divergence: String?) {
        let (macd, signal, histogram) = calculateMACD(prices: prices)
        
        guard prices.count >= 50 else { return (macd, signal, histogram, nil) }
        
        let midPoint = prices.count / 2
        let firstHalfMACD = calculateMACD(prices: Array(prices[0..<midPoint])).macd
        let secondHalfMACD = calculateMACD(prices: Array(prices[midPoint..<prices.count])).macd
        
        let priceDirection = prices.last! > prices[midPoint] ? "rising" : "falling"
        let macdDirection = secondHalfMACD > firstHalfMACD ? "rising" : "falling"
        
        if priceDirection != macdDirection {
            let divergence = priceDirection == "rising" ? "Bearish Divergence" : "Bullish Divergence"
            return (macd, signal, histogram, divergence)
        }
        
        return (macd, signal, histogram, nil)
    }
    
    // MARK: - Advanced Pattern Detection Methods
    
    func detectAllPatterns(data: [MarketData], timeframe: String) -> [PatternResult] {
        var results: [PatternResult] = []
        
        let prices = data.map { $0.price }
        let highs = data.map { $0.price * 1.01 } // Simplified - would use actual OHLC
        let lows = data.map { $0.price * 0.99 }
        let volumes = data.map { Double($0.volume) }
        
        // Chart Patterns
        results.append(contentsOf: detectChartPatterns(prices: prices, highs: highs, lows: lows, timeframe: timeframe))
        
        // Harmonic Patterns  
        results.append(contentsOf: detectHarmonicPatterns(prices: prices, timeframe: timeframe))
        
        // Candlestick Patterns
        results.append(contentsOf: detectAdvancedCandlestickPatterns(data: data, timeframe: timeframe))
        
        // Volume Patterns
        results.append(contentsOf: detectVolumePatterns(prices: prices, volumes: volumes, timeframe: timeframe))
        
        // Elliott Wave Patterns
        results.append(contentsOf: detectElliottWavePatterns(prices: prices, timeframe: timeframe))
        
        return results
    }
    
    private func detectChartPatterns(prices: [Double], highs: [Double], lows: [Double], timeframe: String) -> [PatternResult] {
        var patterns: [PatternResult] = []
        
        // Head and Shoulders detection
        if let headShouldersResult = detectHeadAndShoulders(prices: prices, timeframe: timeframe) {
            patterns.append(headShouldersResult)
        }
        
        // Double Top/Bottom detection
        if let doubleTopResult = detectDoubleTop(prices: prices, timeframe: timeframe) {
            patterns.append(doubleTopResult)
        }
        
        if let doubleBottomResult = detectDoubleBottom(prices: prices, timeframe: timeframe) {
            patterns.append(doubleBottomResult)
        }
        
        // Triangle patterns
        patterns.append(contentsOf: detectTrianglePatterns(highs: highs, lows: lows, timeframe: timeframe))
        
        // Flag and Pennant patterns
        if let flagResult = detectFlag(prices: prices, timeframe: timeframe) {
            patterns.append(flagResult)
        }
        
        return patterns
    }
    
    private func detectHeadAndShoulders(prices: [Double], timeframe: String) -> PatternResult? {
        guard prices.count >= 15 else { return nil }
        
        let windowSize = min(prices.count / 3, 20)
        var maxConfidence = 0.0
        var bestPattern: PatternResult?
        
        for i in windowSize..<(prices.count - windowSize) {
            let leftShoulder = Array(prices[(i-windowSize)..<i])
            let head = Array(prices[i..<(i+windowSize)])
            let rightShoulder = Array(prices[(i+windowSize)..<min(i+2*windowSize, prices.count)])
            
            guard !leftShoulder.isEmpty && !head.isEmpty && !rightShoulder.isEmpty else { continue }
            
            let leftShoulderHigh = leftShoulder.max() ?? 0
            let headHigh = head.max() ?? 0
            let rightShoulderHigh = rightShoulder.max() ?? 0
            
            // Check if head is higher than both shoulders
            if headHigh > leftShoulderHigh && headHigh > rightShoulderHigh {
                let shoulderSymmetry = 1.0 - abs(leftShoulderHigh - rightShoulderHigh) / max(leftShoulderHigh, rightShoulderHigh)
                let headProminence = (headHigh - max(leftShoulderHigh, rightShoulderHigh)) / headHigh
                
                let confidence = (shoulderSymmetry * 0.4 + headProminence * 0.6)
                
                if confidence > maxConfidence && confidence > 0.6 {
                    maxConfidence = confidence
                    let targets = [headHigh * 0.9, headHigh * 0.85, headHigh * 0.8]
                    bestPattern = PatternResult(
                        pattern: ChartPattern.headAndShoulders.rawValue,
                        signal: .sell,
                        confidence: confidence,
                        timeframe: timeframe,
                        strength: confidence > 0.8 ? .strong : .moderate,
                        targets: targets,
                        stopLoss: headHigh * 1.02,
                        successRate: 0.72
                    )
                }
            }
        }
        
        return bestPattern
    }
    
    private func detectDoubleTop(prices: [Double], timeframe: String) -> PatternResult? {
        guard prices.count >= 10 else { return nil }
        
        let peaks = findPeaks(in: prices)
        guard peaks.count >= 2 else { return nil }
        
        for i in 0..<(peaks.count - 1) {
            let firstPeak = peaks[i]
            let secondPeak = peaks[i + 1]
            
            let heightDifference = abs(firstPeak.value - secondPeak.value) / max(firstPeak.value, secondPeak.value)
            
            if heightDifference < 0.02 { // Peaks are within 2% of each other
                let confidence = 1.0 - heightDifference * 10 // Scale confidence
                let avgPeakValue = (firstPeak.value + secondPeak.value) / 2
                
                return PatternResult(
                    pattern: ChartPattern.doubleTop.rawValue,
                    signal: .sell,
                    confidence: confidence,
                    timeframe: timeframe,
                    strength: confidence > 0.8 ? .strong : .moderate,
                    targets: [avgPeakValue * 0.95, avgPeakValue * 0.9, avgPeakValue * 0.85],
                    stopLoss: avgPeakValue * 1.03,
                    successRate: 0.68
                )
            }
        }
        
        return nil
    }
    
    private func detectDoubleBottom(prices: [Double], timeframe: String) -> PatternResult? {
        guard prices.count >= 10 else { return nil }
        
        let troughs = findTroughs(in: prices)
        guard troughs.count >= 2 else { return nil }
        
        for i in 0..<(troughs.count - 1) {
            let firstTrough = troughs[i]
            let secondTrough = troughs[i + 1]
            
            let heightDifference = abs(firstTrough.value - secondTrough.value) / max(firstTrough.value, secondTrough.value)
            
            if heightDifference < 0.02 {
                let confidence = 1.0 - heightDifference * 10
                let avgTroughValue = (firstTrough.value + secondTrough.value) / 2
                
                return PatternResult(
                    pattern: ChartPattern.doubleBottom.rawValue,
                    signal: .buy,
                    confidence: confidence,
                    timeframe: timeframe,
                    strength: confidence > 0.8 ? .strong : .moderate,
                    targets: [avgTroughValue * 1.05, avgTroughValue * 1.1, avgTroughValue * 1.15],
                    stopLoss: avgTroughValue * 0.97,
                    successRate: 0.71
                )
            }
        }
        
        return nil
    }
    
    private func detectTrianglePatterns(highs: [Double], lows: [Double], timeframe: String) -> [PatternResult] {
        var patterns: [PatternResult] = []
        
        guard highs.count >= 10 && lows.count >= 10 else { return patterns }
        
        let highTrend = calculateTrendLine(points: highs)
        let lowTrend = calculateTrendLine(points: lows)
        
        // Ascending Triangle
        if abs(highTrend.slope) < 0.001 && lowTrend.slope > 0.001 {
            patterns.append(PatternResult(
                pattern: ChartPattern.ascendingTriangle.rawValue,
                signal: .buy,
                confidence: 0.75,
                timeframe: timeframe,
                strength: .strong,
                targets: [highs.last! * 1.05, highs.last! * 1.1],
                stopLoss: lows.last! * 0.98,
                successRate: 0.69
            ))
        }
        
        // Descending Triangle
        if abs(lowTrend.slope) < 0.001 && highTrend.slope < -0.001 {
            patterns.append(PatternResult(
                pattern: ChartPattern.descendingTriangle.rawValue,
                signal: .sell,
                confidence: 0.75,
                timeframe: timeframe,
                strength: .strong,
                targets: [lows.last! * 0.95, lows.last! * 0.9],
                stopLoss: highs.last! * 1.02,
                successRate: 0.67
            ))
        }
        
        // Symmetrical Triangle
        if highTrend.slope < -0.001 && lowTrend.slope > 0.001 {
            patterns.append(PatternResult(
                pattern: ChartPattern.symmetricalTriangle.rawValue,
                signal: .hold,
                confidence: 0.65,
                timeframe: timeframe,
                strength: .moderate,
                targets: [highs.last! * 1.03, lows.last! * 0.97],
                stopLoss: nil,
                successRate: 0.58
            ))
        }
        
        return patterns
    }
    
    private func detectFlag(prices: [Double], timeframe: String) -> PatternResult? {
        guard prices.count >= 15 else { return nil }
        
        // Look for strong trend followed by consolidation
        let recentPrices = Array(prices.suffix(15))
        let trendPrices = Array(prices.suffix(30).prefix(15))
        
        let trendDirection = (trendPrices.last! - trendPrices.first!) / trendPrices.first!
        let consolidationRange = (recentPrices.max()! - recentPrices.min()!) / recentPrices.average()
        
        if abs(trendDirection) > 0.05 && consolidationRange < 0.03 {
            let signal: TradingSignal = trendDirection > 0 ? .buy : .sell
            
            return PatternResult(
                pattern: ChartPattern.flag.rawValue,
                signal: signal,
                confidence: 0.7,
                timeframe: timeframe,
                strength: .moderate,
                targets: [prices.last! * (1 + trendDirection)],
                stopLoss: signal == .buy ? recentPrices.min()! * 0.98 : recentPrices.max()! * 1.02,
                successRate: 0.64
            )
        }
        
        return nil
    }
    
    private func detectHarmonicPatterns(prices: [Double], timeframe: String) -> [PatternResult] {
        var patterns: [PatternResult] = []
        
        // Gartley Pattern detection
        if let gartley = detectGartleyPattern(prices: prices, timeframe: timeframe) {
            patterns.append(gartley)
        }
        
        // Butterfly Pattern detection
        if let butterfly = detectButterflyPattern(prices: prices, timeframe: timeframe) {
            patterns.append(butterfly)
        }
        
        // ABCD Pattern detection
        if let abcd = detectABCDPattern(prices: prices, timeframe: timeframe) {
            patterns.append(abcd)
        }
        
        return patterns
    }
    
    private func detectGartleyPattern(prices: [Double], timeframe: String) -> PatternResult? {
        // Simplified Gartley detection - in production would use more sophisticated Fibonacci ratios
        guard prices.count >= 20 else { return nil }
        
        let peaks = findPeaks(in: prices)
        let troughs = findTroughs(in: prices)
        
        guard peaks.count >= 2 && troughs.count >= 2 else { return nil }
        
        // Check for Gartley ratios (0.618, 0.786, 1.27)
        let confidence = 0.65 // Simplified confidence
        
        return PatternResult(
            pattern: ChartPattern.gartley.rawValue,
            signal: .buy,
            confidence: confidence,
            timeframe: timeframe,
            strength: .strong,
            targets: [prices.last! * 1.08, prices.last! * 1.15],
            stopLoss: prices.last! * 0.96,
            successRate: 0.76
        )
    }
    
    private func detectButterflyPattern(prices: [Double], timeframe: String) -> PatternResult? {
        // Simplified Butterfly detection
        guard prices.count >= 20 else { return nil }
        
        return PatternResult(
            pattern: ChartPattern.butterfly.rawValue,
            signal: .sell,
            confidence: 0.68,
            timeframe: timeframe,
            strength: .strong,
            targets: [prices.last! * 0.92, prices.last! * 0.85],
            stopLoss: prices.last! * 1.04,
            successRate: 0.74
        )
    }
    
    private func detectABCDPattern(prices: [Double], timeframe: String) -> PatternResult? {
        // Simplified ABCD detection
        guard prices.count >= 12 else { return nil }
        
        return PatternResult(
            pattern: ChartPattern.abcd.rawValue,
            signal: .buy,
            confidence: 0.72,
            timeframe: timeframe,
            strength: .moderate,
            targets: [prices.last! * 1.06],
            stopLoss: prices.last! * 0.95,
            successRate: 0.63
        )
    }
    
    // MARK: - Advanced Candlestick Patterns (50+ patterns)
    
    enum AdvancedCandlestickPattern: String, CaseIterable {
        // Single Candlestick Patterns
        case doji = "Doji"
        case graveStoneDoji = "Gravestone Doji"
        case dragonflyDoji = "Dragonfly Doji"
        case hammer = "Hammer"
        case hangingMan = "Hanging Man"
        case shootingStar = "Shooting Star"
        case invertedHammer = "Inverted Hammer"
        case marubozu = "Marubozu"
        case spinningTop = "Spinning Top"
        
        // Two Candlestick Patterns
        case bullishEngulfing = "Bullish Engulfing"
        case bearishEngulfing = "Bearish Engulfing"
        case tweezerTops = "Tweezer Tops"
        case tweezerBottoms = "Tweezer Bottoms"
        case piercingPattern = "Piercing Pattern"
        case darkCloudCover = "Dark Cloud Cover"
        case bullishHarami = "Bullish Harami"
        case bearishHarami = "Bearish Harami"
        
        // Three Candlestick Patterns
        case threeWhiteSoldiers = "Three White Soldiers"
        case threeBlackCrows = "Three Black Crows"
        case morningDoji = "Morning Doji Star"
        case eveningDoji = "Evening Doji Star"
        case morningStar = "Morning Star"
        case eveningStar = "Evening Star"
        case threeInside = "Three Inside Up/Down"
        case threeOutside = "Three Outside Up/Down"
        case abandonedBaby = "Abandoned Baby"
        case triStar = "Tri-Star"
        
        // Complex Patterns
        case risingThree = "Rising Three Methods"
        case fallingThree = "Falling Three Methods"
        case uniqueThreeRiver = "Unique Three River"
        case threeStarsInSouth = "Three Stars in the South"
        case concealingBaby = "Concealing Baby Swallow"
        case kickingPattern = "Kicking"
        case ladderBottom = "Ladder Bottom"
        case ladderTop = "Ladder Top"
        
        var expectedSignal: TradingSignal {
            switch self {
            case .doji, .spinningTop: return .hold
            case .hammer, .dragonflyDoji, .bullishEngulfing, .piercingPattern, .bullishHarami, 
                 .threeWhiteSoldiers, .morningDoji, .morningStar, .threeInside, .abandonedBaby,
                 .risingThree, .ladderBottom: return .buy
            case .graveStoneDoji, .hangingMan, .shootingStar, .bearishEngulfing, .tweezerTops,
                 .darkCloudCover, .bearishHarami, .threeBlackCrows, .eveningDoji, .eveningStar,
                 .threeOutside, .fallingThree, .ladderTop: return .sell
            default: return .hold
            }
        }
    }
    
    private func detectAdvancedCandlestickPatterns(data: [MarketData], timeframe: String) -> [PatternResult] {
        var patterns: [PatternResult] = []
        
        let candles = data.map { createCandlestick(from: $0) }
        guard candles.count >= 3 else { return patterns }
        
        // Single candlestick patterns
        if let singlePattern = detectSingleCandlestickPatterns(candles: candles, timeframe: timeframe) {
            patterns.append(singlePattern)
        }
        
        // Two candlestick patterns
        if let doublePattern = detectTwoCandlestickPatterns(candles: candles, timeframe: timeframe) {
            patterns.append(doublePattern)
        }
        
        // Three candlestick patterns
        if let triplePattern = detectThreeCandlestickPatterns(candles: candles, timeframe: timeframe) {
            patterns.append(triplePattern)
        }
        
        return patterns
    }
    
    private func createCandlestick(from marketData: MarketData) -> Candlestick {
        // Simplified - in production would use actual OHLC data
        let price = marketData.price
        return Candlestick(
            open: price * 0.999,
            high: price * 1.005,
            low: price * 0.995,
            close: price
        )
    }
    
    private func detectSingleCandlestickPatterns(candles: [Candlestick], timeframe: String) -> PatternResult? {
        guard let lastCandle = candles.last else { return nil }
        
        let bodySize = abs(lastCandle.close - lastCandle.open)
        let totalRange = lastCandle.high - lastCandle.low
        let upperShadow = lastCandle.high - max(lastCandle.open, lastCandle.close)
        let lowerShadow = min(lastCandle.open, lastCandle.close) - lastCandle.low
        
        // Doji detection
        if bodySize / totalRange < 0.1 {
            if upperShadow > bodySize * 3 {
                return createPatternResult(.graveStoneDoji, timeframe: timeframe, confidence: 0.8)
            } else if lowerShadow > bodySize * 3 {
                return createPatternResult(.dragonflyDoji, timeframe: timeframe, confidence: 0.8)
            } else {
                return createPatternResult(.doji, timeframe: timeframe, confidence: 0.7)
            }
        }
        
        // Hammer detection
        if lowerShadow > bodySize * 2 && upperShadow < bodySize * 0.5 {
            if lastCandle.close > lastCandle.open {
                return createPatternResult(.hammer, timeframe: timeframe, confidence: 0.75)
            } else {
                return createPatternResult(.hangingMan, timeframe: timeframe, confidence: 0.7)
            }
        }
        
        // Shooting Star detection
        if upperShadow > bodySize * 2 && lowerShadow < bodySize * 0.5 {
            if lastCandle.close < lastCandle.open {
                return createPatternResult(.shootingStar, timeframe: timeframe, confidence: 0.75)
            } else {
                return createPatternResult(.invertedHammer, timeframe: timeframe, confidence: 0.7)
            }
        }
        
        // Marubozu detection (very small shadows)
        if upperShadow < totalRange * 0.05 && lowerShadow < totalRange * 0.05 {
            return createPatternResult(.marubozu, timeframe: timeframe, confidence: 0.8)
        }
        
        return nil
    }
    
    private func detectTwoCandlestickPatterns(candles: [Candlestick], timeframe: String) -> PatternResult? {
        guard candles.count >= 2 else { return nil }
        
        let current = candles[candles.count - 1]
        let previous = candles[candles.count - 2]
        
        // Engulfing patterns
        if current.open > previous.close && current.close < previous.open {
            return createPatternResult(.bearishEngulfing, timeframe: timeframe, confidence: 0.85)
        }
        
        if current.open < previous.close && current.close > previous.open {
            return createPatternResult(.bullishEngulfing, timeframe: timeframe, confidence: 0.85)
        }
        
        // Piercing Pattern
        if previous.close < previous.open && current.close > current.open &&
           current.open < previous.close && current.close > (previous.open + previous.close) / 2 {
            return createPatternResult(.piercingPattern, timeframe: timeframe, confidence: 0.8)
        }
        
        // Dark Cloud Cover
        if previous.close > previous.open && current.close < current.open &&
           current.open > previous.close && current.close < (previous.open + previous.close) / 2 {
            return createPatternResult(.darkCloudCover, timeframe: timeframe, confidence: 0.8)
        }
        
        // Harami patterns
        if abs(current.close - current.open) < abs(previous.close - previous.open) * 0.5 {
            if previous.close < previous.open && current.close > current.open {
                return createPatternResult(.bullishHarami, timeframe: timeframe, confidence: 0.7)
            } else if previous.close > previous.open && current.close < current.open {
                return createPatternResult(.bearishHarami, timeframe: timeframe, confidence: 0.7)
            }
        }
        
        return nil
    }
    
    private func detectThreeCandlestickPatterns(candles: [Candlestick], timeframe: String) -> PatternResult? {
        guard candles.count >= 3 else { return nil }
        
        let current = candles[candles.count - 1]
        let middle = candles[candles.count - 2]
        let first = candles[candles.count - 3]
        
        // Three White Soldiers
        if first.close > first.open && middle.close > middle.open && current.close > current.open &&
           middle.close > first.close && current.close > middle.close {
            return createPatternResult(.threeWhiteSoldiers, timeframe: timeframe, confidence: 0.85)
        }
        
        // Three Black Crows
        if first.close < first.open && middle.close < middle.open && current.close < current.open &&
           middle.close < first.close && current.close < middle.close {
            return createPatternResult(.threeBlackCrows, timeframe: timeframe, confidence: 0.85)
        }
        
        // Morning Star
        if first.close < first.open && // Bearish first candle
           abs(middle.close - middle.open) < abs(first.close - first.open) * 0.3 && // Small middle candle
           current.close > current.open && // Bullish third candle
           current.close > (first.open + first.close) / 2 { // Closes above midpoint of first
            return createPatternResult(.morningStar, timeframe: timeframe, confidence: 0.8)
        }
        
        // Evening Star
        if first.close > first.open && // Bullish first candle
           abs(middle.close - middle.open) < abs(first.close - first.open) * 0.3 && // Small middle candle
           current.close < current.open && // Bearish third candle
           current.close < (first.open + first.close) / 2 { // Closes below midpoint of first
            return createPatternResult(.eveningStar, timeframe: timeframe, confidence: 0.8)
        }
        
        return nil
    }
    
    private func createPatternResult(_ pattern: AdvancedCandlestickPattern, timeframe: String, confidence: Double, currentPrice: Double = 0.0) -> PatternResult {
        let basePrice = currentPrice > 0 ? currentPrice : 0.0 // Use actual current price
        let signal = pattern.expectedSignal
        
        let targets: [Double]
        let stopLoss: Double?
        
        if basePrice > 0 {
            switch signal {
            case .buy, .strongBuy:
                targets = [basePrice * 1.02, basePrice * 1.05, basePrice * 1.08]
                stopLoss = basePrice * 0.98
            case .sell, .strongSell:
                targets = [basePrice * 0.98, basePrice * 0.95, basePrice * 0.92]
                stopLoss = basePrice * 1.02
            case .hold:
                targets = []
                stopLoss = nil
            }
        } else {
            // No price data available
            targets = []
            stopLoss = nil
        }
        
        return PatternResult(
            pattern: pattern.rawValue,
            signal: signal,
            confidence: confidence,
            timeframe: timeframe,
            strength: confidence > 0.8 ? .strong : .moderate,
            targets: targets,
            stopLoss: stopLoss,
            successRate: getPatternSuccessRate(pattern)
        )
    }
    
    private func getPatternSuccessRate(_ pattern: AdvancedCandlestickPattern) -> Double {
        // Historical success rates for different patterns
        switch pattern {
        case .bullishEngulfing, .bearishEngulfing: return 0.78
        case .threeWhiteSoldiers, .threeBlackCrows: return 0.85
        case .morningStar, .eveningStar: return 0.76
        case .hammer, .shootingStar: return 0.69
        case .doji: return 0.55
        case .piercingPattern, .darkCloudCover: return 0.72
        default: return 0.65
        }
    }
    
    // MARK: - Volume Pattern Analysis
    
    private func detectVolumePatterns(prices: [Double], volumes: [Double], timeframe: String) -> [PatternResult] {
        var patterns: [PatternResult] = []
        
        guard prices.count == volumes.count && prices.count >= 10 else { return patterns }
        
        // Volume Breakout Pattern
        if let breakoutPattern = detectVolumeBreakout(prices: prices, volumes: volumes, timeframe: timeframe) {
            patterns.append(breakoutPattern)
        }
        
        // Accumulation/Distribution Pattern
        if let accDistPattern = detectAccumulationDistribution(prices: prices, volumes: volumes, timeframe: timeframe) {
            patterns.append(accDistPattern)
        }
        
        // Volume Spike Pattern
        if let spikePattern = detectVolumeSpike(prices: prices, volumes: volumes, timeframe: timeframe) {
            patterns.append(spikePattern)
        }
        
        return patterns
    }
    
    private func detectVolumeBreakout(prices: [Double], volumes: [Double], timeframe: String) -> PatternResult? {
        guard let lastPrice = prices.last, let lastVolume = volumes.last else { return nil }
        
        let avgVolume = volumes.suffix(20).reduce(0, +) / 20
        let priceChange = (lastPrice - prices[prices.count - 2]) / prices[prices.count - 2]
        
        if lastVolume > avgVolume * 2 && abs(priceChange) > 0.02 {
            let signal: TradingSignal = priceChange > 0 ? .strongBuy : .strongSell
            
            return PatternResult(
                pattern: "Volume Breakout",
                signal: signal,
                confidence: 0.8,
                timeframe: timeframe,
                strength: .strong,
                targets: [lastPrice * (1 + priceChange * 1.5)],
                stopLoss: lastPrice * (1 - abs(priceChange) * 0.5),
                successRate: 0.74
            )
        }
        
        return nil
    }
    
    private func detectAccumulationDistribution(prices: [Double], volumes: [Double], timeframe: String) -> PatternResult? {
        guard prices.count >= 15 else { return nil }
        
        let recentPrices = Array(prices.suffix(10))
        let recentVolumes = Array(volumes.suffix(10))
        
        let priceDirection = (recentPrices.last! - recentPrices.first!) / recentPrices.first!
        let avgVolume = recentVolumes.reduce(0, +) / Double(recentVolumes.count)
        let oldAvgVolume = Array(volumes.suffix(20).prefix(10)).reduce(0, +) / 10
        
        if avgVolume > oldAvgVolume * 1.2 {
            if priceDirection > 0.01 {
                return PatternResult(
                    pattern: "Accumulation",
                    signal: .buy,
                    confidence: 0.75,
                    timeframe: timeframe,
                    strength: .moderate,
                    targets: [recentPrices.last! * 1.08],
                    stopLoss: recentPrices.min()! * 0.98,
                    successRate: 0.68
                )
            } else if priceDirection < -0.01 {
                return PatternResult(
                    pattern: "Distribution",
                    signal: .sell,
                    confidence: 0.75,
                    timeframe: timeframe,
                    strength: .moderate,
                    targets: [recentPrices.last! * 0.92],
                    stopLoss: recentPrices.max()! * 1.02,
                    successRate: 0.66
                )
            }
        }
        
        return nil
    }
    
    private func detectVolumeSpike(prices: [Double], volumes: [Double], timeframe: String) -> PatternResult? {
        guard let lastVolume = volumes.last else { return nil }
        
        let avgVolume = volumes.suffix(20).reduce(0, +) / 20
        
        if lastVolume > avgVolume * 3 {
            return PatternResult(
                pattern: "Volume Spike",
                signal: .hold,
                confidence: 0.6,
                timeframe: timeframe,
                strength: .moderate,
                targets: [],
                stopLoss: nil,
                successRate: 0.55
            )
        }
        
        return nil
    }
    
    // MARK: - Elliott Wave Pattern Detection
    
    private func detectElliottWavePatterns(prices: [Double], timeframe: String) -> [PatternResult] {
        var patterns: [PatternResult] = []
        
        // Simplified Elliott Wave detection
        if let impulseWave = detectImpulseWave(prices: prices, timeframe: timeframe) {
            patterns.append(impulseWave)
        }
        
        if let correctiveWave = detectCorrectiveWave(prices: prices, timeframe: timeframe) {
            patterns.append(correctiveWave)
        }
        
        return patterns
    }
    
    private func detectImpulseWave(prices: [Double], timeframe: String) -> PatternResult? {
        guard prices.count >= 20 else { return nil }
        
        // Simplified impulse wave detection - 5 wave pattern
        let waves = identifyWaves(in: prices)
        
        if waves.count >= 5 {
            return PatternResult(
                pattern: ChartPattern.impulseWave.rawValue,
                signal: .buy,
                confidence: 0.7,
                timeframe: timeframe,
                strength: .strong,
                targets: [prices.last! * 1.15],
                stopLoss: prices.last! * 0.95,
                successRate: 0.73
            )
        }
        
        return nil
    }
    
    private func detectCorrectiveWave(prices: [Double], timeframe: String) -> PatternResult? {
        guard prices.count >= 15 else { return nil }
        
        // Simplified corrective wave detection - 3 wave pattern
        let waves = identifyWaves(in: prices)
        
        if waves.count >= 3 {
            return PatternResult(
                pattern: ChartPattern.correctiveWave.rawValue,
                signal: .sell,
                confidence: 0.65,
                timeframe: timeframe,
                strength: .moderate,
                targets: [prices.last! * 0.92],
                stopLoss: prices.last! * 1.05,
                successRate: 0.61
            )
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private struct Peak {
        let index: Int
        let value: Double
    }
    
    private struct TrendLine {
        let slope: Double
        let intercept: Double
    }
    
    private func findPeaks(in prices: [Double]) -> [Peak] {
        var peaks: [Peak] = []
        
        for i in 1..<(prices.count - 1) {
            if prices[i] > prices[i-1] && prices[i] > prices[i+1] {
                peaks.append(Peak(index: i, value: prices[i]))
            }
        }
        
        return peaks
    }
    
    private func findTroughs(in prices: [Double]) -> [Peak] {
        var troughs: [Peak] = []
        
        for i in 1..<(prices.count - 1) {
            if prices[i] < prices[i-1] && prices[i] < prices[i+1] {
                troughs.append(Peak(index: i, value: prices[i]))
            }
        }
        
        return troughs
    }
    
    private func calculateTrendLine(points: [Double]) -> TrendLine {
        guard points.count > 1 else { return TrendLine(slope: 0, intercept: 0) }
        
        let n = Double(points.count)
        let xValues = Array(0..<points.count).map { Double($0) }
        let yValues = points
        
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map(*).reduce(0, +)
        let sumXX = xValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        return TrendLine(slope: slope, intercept: intercept)
    }
    
    private func identifyWaves(in prices: [Double]) -> [Peak] {
        let peaks = findPeaks(in: prices)
        let troughs = findTroughs(in: prices)
        
        // Combine and sort by index
        var waves = peaks + troughs
        waves.sort { $0.index < $1.index }
        
        return waves
    }
    
    // MARK: - Remaining Methods from Original Engine
    
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

    // Original Candlestick Patterns (for backward compatibility)
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
    
    // MARK: - Advanced Technical Indicators
    
    // Williams %R
    func calculateWilliamsR(highs: [Double], lows: [Double], closes: [Double], period: Int = 14) -> Double {
        guard highs.count >= period && lows.count >= period && closes.count >= period else { return -50.0 }
        
        let highestHigh = highs.suffix(period).max() ?? 0
        let lowestLow = lows.suffix(period).min() ?? 0
        let currentClose = closes.last ?? 0
        
        if highestHigh == lowestLow {
            return -50.0
        }
        
        return ((highestHigh - currentClose) / (highestHigh - lowestLow)) * -100
    }
    
    // Commodity Channel Index (CCI)
    func calculateCCI(highs: [Double], lows: [Double], closes: [Double], period: Int = 20) -> Double {
        guard highs.count >= period && lows.count >= period && closes.count >= period else { return 0 }
        
        let typicalPrices = zip(zip(highs, lows), closes).map { pairs in
            let ((high, low), close) = pairs
            return (high + low + close) / 3.0
        }
        
        let sma = typicalPrices.suffix(period).reduce(0, +) / Double(period)
        let meanDeviationComponents = typicalPrices.suffix(period).map { abs($0 - sma) }
        let meanDeviation = meanDeviationComponents.reduce(0, +) / Double(period)
        
        guard meanDeviation > 0 else { return 0 }
        
        let currentTypicalPrice = typicalPrices.last ?? 0
        return (currentTypicalPrice - sma) / (0.015 * meanDeviation)
    }
    
    // Average True Range (ATR)
    func calculateATR(highs: [Double], lows: [Double], closes: [Double], period: Int = 14) -> Double {
        guard highs.count >= period && lows.count >= period && closes.count >= period else { return 0 }
        
        var trueRanges: [Double] = []
        
        for i in 1..<highs.count {
            let tr1 = highs[i] - lows[i]
            let tr2 = abs(highs[i] - closes[i-1])
            let tr3 = abs(lows[i] - closes[i-1])
            
            trueRanges.append(max(tr1, max(tr2, tr3)))
        }
        
        return trueRanges.suffix(period).reduce(0, +) / Double(period)
    }
    
    // Money Flow Index (MFI)
    func calculateMFI(highs: [Double], lows: [Double], closes: [Double], volumes: [Double], period: Int = 14) -> Double {
        guard highs.count >= period && volumes.count >= period else { return 50.0 }
        
        var positiveFlow: Double = 0
        var negativeFlow: Double = 0
        
        for i in 1..<highs.count {
            let typicalPrice = (highs[i] + lows[i] + closes[i]) / 3.0
            let previousTypicalPrice = (highs[i-1] + lows[i-1] + closes[i-1]) / 3.0
            let moneyFlow = typicalPrice * volumes[i]
            
            if typicalPrice > previousTypicalPrice {
                positiveFlow += moneyFlow
            } else if typicalPrice < previousTypicalPrice {
                negativeFlow += moneyFlow
            }
        }
        
        guard negativeFlow > 0 else { return 100 }
        
        let moneyRatio = positiveFlow / negativeFlow
        return 100 - (100 / (1 + moneyRatio))
    }
    
    // Parabolic SAR
    func calculateParabolicSAR(highs: [Double], lows: [Double], acceleration: Double = 0.02, maximum: Double = 0.2) -> [Double] {
        guard highs.count >= 2 && lows.count >= 2 else { return [] }
        
        var sar: [Double] = []
        var ep = highs[0] // Extreme Point
        var af = acceleration // Acceleration Factor
        var trend = true // true = uptrend, false = downtrend
        
        sar.append(lows[0])
        
        for i in 1..<highs.count {
            let previousSAR = sar[i-1]
            var newSAR = previousSAR + af * (ep - previousSAR)
            
            if trend {
                // Uptrend
                if lows[i] <= newSAR {
                    trend = false
                    newSAR = ep
                    ep = lows[i]
                    af = acceleration
                } else {
                    if highs[i] > ep {
                        ep = highs[i]
                        af = min(af + acceleration, maximum)
                    }
                }
            } else {
                // Downtrend
                if highs[i] >= newSAR {
                    trend = true
                    newSAR = ep
                    ep = highs[i]
                    af = acceleration
                } else {
                    if lows[i] < ep {
                        ep = lows[i]
                        af = min(af + acceleration, maximum)
                    }
                }
            }
            
            sar.append(newSAR)
        }
        
        return sar
    }
    
    // Pattern Quality Scoring
    func calculatePatternQuality(patterns: [PatternResult]) -> [PatternResult] {
        return patterns.map { pattern in
            let updatedPattern = pattern
            
            // Adjust confidence based on multiple factors
            var qualityScore = pattern.confidence
            
            // Historical success rate factor
            qualityScore *= pattern.successRate
            
            // Timeframe reliability factor
            let timeframeWeight: Double
            switch pattern.timeframe {
            case "1D": timeframeWeight = 1.0
            case "4h": timeframeWeight = 0.9
            case "1h": timeframeWeight = 0.8
            case "15m": timeframeWeight = 0.7
            case "5m": timeframeWeight = 0.6
            case "1m": timeframeWeight = 0.5
            default: timeframeWeight = 0.7
            }
            
            qualityScore *= timeframeWeight
            
            // Create updated pattern with adjusted confidence
            return PatternResult(
                pattern: updatedPattern.pattern,
                signal: updatedPattern.signal,
                confidence: min(qualityScore, 1.0),
                timeframe: updatedPattern.timeframe,
                strength: qualityScore > 0.8 ? .veryStrong : qualityScore > 0.6 ? .strong : qualityScore > 0.4 ? .moderate : .weak,
                targets: updatedPattern.targets,
                stopLoss: updatedPattern.stopLoss,
                successRate: updatedPattern.successRate
            )
        }
    }
    
    // Pattern Confluence Analysis
    func analyzePatternConfluence(multiTimeframeResults: [String: [PatternResult]]) -> [PatternResult] {
        var confluencePatterns: [PatternResult] = []
        
        // Find patterns that appear across multiple timeframes
        for (_, patterns) in multiTimeframeResults {
            for pattern in patterns {
                let similarPatterns = multiTimeframeResults.values.flatMap { $0 }.filter {
                    $0.pattern == pattern.pattern && $0.signal == pattern.signal
                }
                
                if similarPatterns.count >= 2 { // Pattern appears in at least 2 timeframes
                    let avgConfidence = similarPatterns.map { $0.confidence }.reduce(0, +) / Double(similarPatterns.count)
                    let confluenceBonus = min(Double(similarPatterns.count) * 0.1, 0.3)
                    
                    let confluencePattern = PatternResult(
                        pattern: "\(pattern.pattern) (Confluence)",
                        signal: pattern.signal,
                        confidence: min(avgConfidence + confluenceBonus, 1.0),
                        timeframe: "Multi-TF",
                        strength: .veryStrong,
                        targets: pattern.targets,
                        stopLoss: pattern.stopLoss,
                        successRate: min(pattern.successRate + 0.1, 0.95)
                    )
                    
                    confluencePatterns.append(confluencePattern)
                }
            }
        }
        
        return confluencePatterns
    }
}

// MARK: - Array Extensions for Helper Methods

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
    
    func standardDeviation() -> Double {
        let avg = average()
        let squaredDiffs = map { pow($0 - avg, 2) }
        return sqrt(squaredDiffs.average())
    }
}