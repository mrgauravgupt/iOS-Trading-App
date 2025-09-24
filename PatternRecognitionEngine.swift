import Foundation
import SwiftUI

public class PatternRecognitionEngine: ObservableObject {
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    
    // Use the enhanced TradingSignal from TechnicalAnalysisEngine
    typealias TradingSignal = TechnicalAnalysisEngine.TradingSignal
    typealias PatternResult = TechnicalAnalysisEngine.PatternResult
    typealias PatternStrength = TechnicalAnalysisEngine.PatternStrength
    
    // MARK: - Pattern Alert Structure

    // MARK: - Multi-Timeframe Pattern Analysis
    
    func analyzeComprehensivePatterns(marketData: [MarketData]) -> [String: [PatternResult]] {
        // Use the enhanced multi-timeframe analysis from TechnicalAnalysisEngine
        let multiTimeframeResults = technicalAnalysisEngine.analyzeMultiTimeframe(data: marketData)
        
        // Apply pattern quality scoring
        var qualityAdjustedResults: [String: [PatternResult]] = [:]
        
        for (timeframe, patterns) in multiTimeframeResults {
            let qualityPatterns = technicalAnalysisEngine.calculatePatternQuality(patterns: patterns)
            qualityAdjustedResults[timeframe] = qualityPatterns
        }
        
        return qualityAdjustedResults
    }
    
    // Enhanced pattern analysis with confluence detection
    func analyzeWithConfluence(marketData: [MarketData]) -> (patterns: [String: [PatternResult]], confluence: [PatternResult]) {
        let multiTimeframeResults = analyzeComprehensivePatterns(marketData: marketData)
        let confluencePatterns = technicalAnalysisEngine.analyzePatternConfluence(multiTimeframeResults: multiTimeframeResults)
        
        return (patterns: multiTimeframeResults, confluence: confluencePatterns)
    }
    
    // Real-time pattern scanning for alerts
    func scanForPatternAlerts(marketData: [MarketData], alertThreshold: Double = 0.7) -> [PatternAlert] {
        let analysisResults = analyzeComprehensivePatterns(marketData: marketData)
        var alerts: [PatternAlert] = []
        
        for (timeframe, patterns) in analysisResults {
            for pattern in patterns {
                if pattern.confidence >= alertThreshold {
                    let alert = PatternAlert(
                        pattern: pattern,
                        timeframe: timeframe,
                        timestamp: Date(),
                        urgency: determineUrgency(pattern: pattern)
                    )
                    alerts.append(alert)
                }
            }
        }
        
        // Sort by urgency and confidence
        alerts.sort { first, second in
            if first.urgency == second.urgency {
                return first.pattern.confidence > second.pattern.confidence
            }
            return first.urgency.priority > second.urgency.priority
        }
        
        return alerts
    }
    
    // MARK: - Pattern Alert System
    
    enum AlertUrgency: String, CaseIterable {
        case critical = "CRITICAL"
        case high = "HIGH"
        case medium = "MEDIUM"
        case low = "LOW"
        
        var priority: Int {
            switch self {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
        
        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "yellow"
            case .low: return "blue"
            }
        }
    }
    
    struct PatternAlert {
        let pattern: PatternResult
        let timeframe: String
        let timestamp: Date
        let urgency: AlertUrgency
        
        var alertMessage: String {
            return "\(urgency.rawValue): \(pattern.pattern) detected on \(timeframe) with \(Int(pattern.confidence * 100))% confidence. Signal: \(pattern.signal.rawValue)"
        }
    }
    
    private func determineUrgency(pattern: PatternResult) -> AlertUrgency {
        let confidenceScore = pattern.confidence
        let strengthScore: Double
        
        switch pattern.strength {
        case .veryStrong: strengthScore = 1.0
        case .strong: strengthScore = 0.8
        case .moderate: strengthScore = 0.6
        case .weak: strengthScore = 0.4
        }
        
        let urgencyScore = (confidenceScore + strengthScore + pattern.successRate) / 3.0
        
        if urgencyScore >= 0.9 {
            return .critical
        } else if urgencyScore >= 0.75 {
            return .high
        } else if urgencyScore >= 0.6 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Enhanced Analysis Methods
    
    func analyzePatterns(highs: [Double], lows: [Double], closes: [Double], opens: [Double]) -> [PatternResult] {
        // Create market data from arrays
        let marketData = createMarketData(opens: opens, highs: highs, lows: lows, closes: closes)
        
        // Use comprehensive analysis
        let results = analyzeComprehensivePatterns(marketData: marketData)
        
        // Flatten results from all timeframes
        return results.values.flatMap { $0 }
    }
    
    private func createMarketData(opens: [Double], highs: [Double], lows: [Double], closes: [Double]) -> [MarketData] {
        let minCount = min(opens.count, highs.count, lows.count, closes.count)
        var marketData: [MarketData] = []
        
        for i in 0..<minCount {
            // Simplified MarketData creation - in production would include proper timestamps and volume
            let data = MarketData(
                symbol: "NIFTY",
                price: closes[i],
                volume: 100000, // Simplified
                timestamp: Date().addingTimeInterval(TimeInterval(i * 60)) // 1 minute intervals
            )
            marketData.append(data)
        }
        
        return marketData
    }
    
    // MARK: - Advanced Pattern Recognition Methods
    
    // Sector analysis for market intelligence
    func analyzeSectorMomentum(sectorData: [String: [MarketData]]) -> [String: PatternResult] {
        var sectorAnalysis: [String: PatternResult] = [:]
        
        for (sector, data) in sectorData {
            let analysis = analyzeComprehensivePatterns(marketData: data)
            
            // Find the strongest pattern across all timeframes for this sector
            let allPatterns = analysis.values.flatMap { $0 }
            if let strongestPattern = allPatterns.max(by: { $0.confidence < $1.confidence }) {
                sectorAnalysis[sector] = strongestPattern
            }
        }
        
        return sectorAnalysis
    }
    
    // Market regime detection
    func detectMarketRegime(marketData: [MarketData]) -> MarketRegime {
        let prices = marketData.map { $0.price }
        let volumes = marketData.map { $0.volume }
        
        guard prices.count >= 50 else { return .sideways }
        
        // Calculate trend strength
        let shortMA = technicalAnalysisEngine.calculateSMA(prices: Array(prices.suffix(10)), period: 10)
        let longMA = technicalAnalysisEngine.calculateSMA(prices: Array(prices.suffix(50)), period: 50)
        
        let trendStrength = abs(shortMA - longMA) / longMA
        let volatility = prices.suffix(20).map { $0 }.standardDeviation() / prices.average()
        
        // Determine regime
        if trendStrength > 0.05 {
            return shortMA > longMA ? .trending(.bullish) : .trending(.bearish)
        } else if volatility > 0.02 {
            return .volatile
        } else {
            return .sideways
        }
    }
    
    enum MarketRegime {
        case trending(TrendDirection)
        case sideways
        case volatile
        
        enum TrendDirection {
            case bullish, bearish
        }
        
        var description: String {
            switch self {
            case .trending(.bullish): return "Bullish Trending"
            case .trending(.bearish): return "Bearish Trending"
            case .sideways: return "Sideways/Ranging"
            case .volatile: return "High Volatility"
            }
        }
    }
    
    // Pattern success rate tracking
    func trackPatternPerformance(historicalData: [MarketData], patterns: [PatternResult]) -> [String: Double] {
        var performanceTracking: [String: (correct: Int, total: Int)] = [:]
        
        // Simplified performance tracking - in production would use actual trade outcomes
        for pattern in patterns {
            let key = pattern.pattern
            if performanceTracking[key] == nil {
                performanceTracking[key] = (0, 0)
            }
            
            // Simulate outcome based on pattern's expected performance
            let isCorrect = Double.random(in: 0...1) < pattern.successRate
            
            performanceTracking[key]!.total += 1
            if isCorrect {
                performanceTracking[key]!.correct += 1
            }
        }
        
        // Convert to success rates
        var successRates: [String: Double] = [:]
        for (pattern, stats) in performanceTracking {
            successRates[pattern] = stats.total > 0 ? Double(stats.correct) / Double(stats.total) : 0.0
        }
        
        return successRates
    }

    // Test method to validate pattern recognition
    func testPatternRecognition() -> [PatternResult] {
        let testHighs = [18100.0, 18200.0, 18300.0, 18250.0, 18150.0, 18200.0, 18350.0]
        let testLows = [18000.0, 18100.0, 18200.0, 18150.0, 18050.0, 18100.0, 18250.0]
        let testCloses = [18050.0, 18150.0, 18250.0, 18200.0, 18100.0, 18150.0, 18300.0]
        let testOpens = [18000.0, 18100.0, 18200.0, 18150.0, 18050.0, 18100.0, 18250.0]

        return analyzePatterns(highs: testHighs, lows: testLows, closes: testCloses, opens: testOpens)
    }
    
    // MARK: - Pattern Formation Prediction
    
    func predictPatternFormation(marketData: [MarketData], lookAhead: Int = 5) -> [PotentialPattern] {
        var potentialPatterns: [PotentialPattern] = []
        
        let prices = marketData.map { $0.price }
        guard prices.count >= 20 else { return potentialPatterns }
        
        // Look for forming patterns
        let recentTrend = calculateTrendDirection(prices: Array(prices.suffix(10)))
        let volatility = prices.suffix(20).map { $0 }.standardDeviation()
        
        // Predict potential head and shoulders formation
        if recentTrend == .sideways && volatility > prices.average() * 0.01 {
            potentialPatterns.append(PotentialPattern(
                pattern: "Head and Shoulders",
                probability: 0.65,
                estimatedCompletion: Date().addingTimeInterval(TimeInterval(lookAhead * 60)),
                currentProgress: 0.6
            ))
        }
        
        // Predict triangle breakout
        let support = prices.suffix(20).min() ?? 0
        let resistance = prices.suffix(20).max() ?? 0
        let range = (resistance - support) / prices.average()
        
        if range < 0.03 { // Narrow range indicates potential breakout
            potentialPatterns.append(PotentialPattern(
                pattern: "Triangle Breakout",
                probability: 0.7,
                estimatedCompletion: Date().addingTimeInterval(TimeInterval(lookAhead * 30)),
                currentProgress: 0.8
            ))
        }
        
        return potentialPatterns
    }
    
    struct PotentialPattern {
        let pattern: String
        let probability: Double
        let estimatedCompletion: Date
        let currentProgress: Double // 0.0 to 1.0
        
        var progressDescription: String {
            return "\(Int(currentProgress * 100))% formed"
        }
    }
    
    private func calculateTrendDirection(prices: [Double]) -> TrendDirection {
        guard prices.count >= 5 else { return .sideways }
        
        let firstHalf = Array(prices.prefix(prices.count / 2))
        let secondHalf = Array(prices.suffix(prices.count / 2))
        
        let firstAvg = firstHalf.average()
        let secondAvg = secondHalf.average()
        
        let change = (secondAvg - firstAvg) / firstAvg
        
        if change > 0.02 {
            return .bullish
        } else if change < -0.02 {
            return .bearish
        } else {
            return .sideways
        }
    }
    
    enum TrendDirection {
        case bullish, bearish, sideways
    }
    
    // MARK: - Smart Pattern Filtering
    
    func filterPatternsByMarketConditions(patterns: [PatternResult], marketData: [MarketData]) -> [PatternResult] {
        let regime = detectMarketRegime(marketData: marketData)
        
        return patterns.filter { pattern in
            switch regime {
            case .trending(.bullish):
                // In bullish markets, prioritize buy signals and continuation patterns
                return pattern.signal == .buy || pattern.signal == .strongBuy ||
                       pattern.pattern.contains("Flag") || pattern.pattern.contains("Triangle")
                
            case .trending(.bearish):
                // In bearish markets, prioritize sell signals and reversal patterns
                return pattern.signal == .sell || pattern.signal == .strongSell ||
                       pattern.pattern.contains("Head and Shoulders") || pattern.pattern.contains("Double Top")
                
            case .sideways:
                // In ranging markets, prioritize reversal patterns at extremes
                return pattern.pattern.contains("Double") || pattern.pattern.contains("Support") ||
                       pattern.pattern.contains("Resistance")
                
            case .volatile:
                // In volatile markets, require higher confidence patterns
                return pattern.confidence > 0.8
            }
        }
    }
    
    // MARK: - Pattern Clustering Analysis
    
    func clusterSimilarPatterns(patterns: [PatternResult]) -> [PatternCluster] {
        var clusters: [PatternCluster] = []
        var processedPatterns: Set<String> = []
        
        for pattern in patterns {
            if processedPatterns.contains(pattern.pattern) { continue }
            
            let similarPatterns = patterns.filter { $0.pattern == pattern.pattern }
            processedPatterns.insert(pattern.pattern)
            
            let avgConfidence = similarPatterns.map { $0.confidence }.average()
            let strongestSignal = similarPatterns.max { $0.confidence < $1.confidence }?.signal ?? .hold
            
            clusters.append(PatternCluster(
                patternType: pattern.pattern,
                instances: similarPatterns,
                averageConfidence: avgConfidence,
                dominantSignal: strongestSignal,
                timeframes: Array(Set(similarPatterns.map { $0.timeframe }))
            ))
        }
        
        // Sort by strength (confidence * count)
        clusters.sort { first, second in
            let firstStrength = first.averageConfidence * Double(first.instances.count)
            let secondStrength = second.averageConfidence * Double(second.instances.count)
            return firstStrength > secondStrength
        }
        
        return clusters
    }
    
    struct PatternCluster {
        let patternType: String
        let instances: [PatternResult]
        let averageConfidence: Double
        let dominantSignal: TradingSignal
        let timeframes: [String]
        
        var strength: Double {
            return averageConfidence * Double(instances.count)
        }
        
        var description: String {
            return "\(patternType): \(instances.count) instances across \(timeframes.joined(separator: ", ")), avg confidence: \(Int(averageConfidence * 100))%"
        }
    }
}