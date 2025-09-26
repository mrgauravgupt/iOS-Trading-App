import UIKit
import Foundation
import SwiftUI

public class PatternRecognitionEngine: ObservableObject {
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    private let mlModelManager = MLModelManager.shared

    // ML-based adaptive thresholds
    private var adaptiveThresholds: [String: Double] = [:]
    private var patternPerformanceHistory: [String: [PatternPerformance]] = [:]
    private var marketConditionHistory: [MarketCondition] = []

    // Use the enhanced TradingSignal from TechnicalAnalysisEngine
    typealias TradingSignal = TechnicalAnalysisEngine.TradingSignal
    typealias PatternResult = TechnicalAnalysisEngine.PatternResult
    typealias PatternStrength = TechnicalAnalysisEngine.PatternStrength

    // MARK: - ML-Based Pattern Enhancement

    struct PatternPerformance {
        let pattern: String
        let confidence: Double
        let marketRegime: MarketRegime
        let outcome: Bool // true if profitable
        let timestamp: Date
        let holdingPeriod: Int // in minutes
        let features: [Double] // ML features used for prediction
    }

    struct MarketCondition {
        let regime: MarketRegime
        let volatility: Double
        let volume: Double
        let timestamp: Date
        let sentimentScore: Double // Market sentiment
        let momentum: Double // Momentum indicator
    }

    // ML-based pattern detection features
    var patternFeatureExtractor = PatternFeatureExtractor()
    private var neuralNetworkPredictor = NeuralNetworkPredictor()
    var ensembleModel = EnsemblePatternModel()
    
    // MARK: - Pattern Alert Structure

    // MARK: - ML-Enhanced Pattern Analysis
    
    func analyzeComprehensivePatterns(marketData: [MarketData]) -> [String: [PatternResult]] {
        // Use the enhanced multi-timeframe analysis from TechnicalAnalysisEngine
        let multiTimeframeResults = technicalAnalysisEngine.analyzeMultiTimeframe(data: marketData)
        
        // Apply ML-based confidence adjustment
        var mlAdjustedResults: [String: [PatternResult]] = [:]
        
        for (timeframe, patterns) in multiTimeframeResults {
            let mlPatterns = adjustPatternConfidenceWithML(patterns: patterns, marketData: marketData)
            let qualityPatterns = technicalAnalysisEngine.calculatePatternQuality(patterns: mlPatterns)
            mlAdjustedResults[timeframe] = qualityPatterns
        }
        
        // Update adaptive thresholds based on recent performance
        updateAdaptiveThresholds()
        
        return mlAdjustedResults
    }
    
    private func adjustPatternConfidenceWithML(patterns: [PatternResult], marketData: [MarketData]) -> [PatternResult] {
        let regime = detectMarketRegime(marketData: marketData)
        let volatility = marketData.map { $0.price }.standardDeviation()
        
        // Create state for ML model
        let state: [Double] = [
            regime == .bullish ? 1.0 : 0.0,
            regime == .bearish ? 1.0 : 0.0,
            volatility,
            Double(marketData.count)
        ]
        
        let mlAdjustment = mlModelManager.makePrediction(input: state)
        
        return patterns.map { pattern in
            // Adjust confidence based on ML prediction and historical performance
            let baseAdjustment = mlAdjustment * 0.1 // ML contributes 10% to confidence
            let historicalAdjustment = getHistoricalPerformanceAdjustment(for: pattern.pattern, regime: regime)

            let adjustedConfidence = min(1.0, max(0.0, pattern.confidence + baseAdjustment + historicalAdjustment))

            // Create new PatternResult with adjusted confidence
            return PatternResult(
                pattern: pattern.pattern,
                signal: pattern.signal,
                confidence: adjustedConfidence,
                timeframe: pattern.timeframe,
                strength: pattern.strength,
                targets: pattern.targets,
                stopLoss: pattern.stopLoss,
                successRate: pattern.successRate
            )
        }
    }
    
    private func getHistoricalPerformanceAdjustment(for pattern: String, regime: MarketRegime) -> Double {
        guard let history = patternPerformanceHistory[pattern] else { return 0.0 }
        
        let relevantHistory = history.filter { $0.marketRegime == regime }
        guard !relevantHistory.isEmpty else { return 0.0 }
        
        let successRate = Double(relevantHistory.filter { $0.outcome }.count) / Double(relevantHistory.count)
        let adjustment = (successRate - 0.5) * 0.2 // Adjust by up to 20% based on success rate
        
        return adjustment
    }
    
    private func updateAdaptiveThresholds() {
        // Update thresholds based on recent market conditions and pattern performance
        for patternType in adaptiveThresholds.keys {
            if let history = patternPerformanceHistory[patternType], !history.isEmpty {
                let recentHistory = Array(history.suffix(10)) // Last 10 occurrences
                let successRate = Double(recentHistory.filter { $0.outcome }.count) / Double(recentHistory.count)
                
                // Adaptive threshold: lower for successful patterns, higher for failures
                let baseThreshold: Double = 0.7
                let adjustment = (0.5 - successRate) * 0.2 // Adjust by up to 20%
                adaptiveThresholds[patternType] = max(0.5, min(0.9, baseThreshold + adjustment))
            } else {
                adaptiveThresholds[patternType] = 0.7 // Default
            }
        }
    }
    
    func getAdaptiveThreshold(for pattern: String) -> Double {
        return adaptiveThresholds[pattern] ?? 0.7
    }
    
    func recordPatternOutcome(pattern: String, confidence: Double, regime: MarketRegime, outcome: Bool, holdingPeriod: Int) {
        let performance = PatternPerformance(
            pattern: pattern,
            confidence: confidence,
            marketRegime: regime,
            outcome: outcome,
            timestamp: Date(),
            holdingPeriod: holdingPeriod,
            features: [confidence, Double(holdingPeriod)] // Basic features
        )
        
        if patternPerformanceHistory[pattern] == nil {
            patternPerformanceHistory[pattern] = []
        }
        patternPerformanceHistory[pattern]?.append(performance)
        
        // Keep only last 100 records per pattern to manage memory
        if patternPerformanceHistory[pattern]?.count ?? 0 > 100 {
            patternPerformanceHistory[pattern]?.removeFirst()
        }
        
        // Record market condition
        let volatility = marketConditionHistory.last?.volatility ?? 0.0
        let volume = marketConditionHistory.last?.volume ?? 0.0
        marketConditionHistory.append(MarketCondition(
            regime: regime,
            volatility: volatility,
            volume: volume,
            timestamp: Date(),
            sentimentScore: 0.5, // Neutral sentiment
            momentum: 0.0 // No momentum
        ))
        
        // Train ML model with this outcome
        let state: [Double] = [confidence, regime == .bullish ? 1.0 : 0.0, Double(holdingPeriod)]
        let reward = outcome ? 1.0 : -1.0
        mlModelManager.learnFromTrade(state: state, action: outcome ? 0 : 1, reward: reward, nextState: state)
    }
    
    // Enhanced pattern analysis with confluence detection
    func analyzeWithConfluence(marketData: [MarketData]) -> (patterns: [String: [PatternResult]], confluence: [PatternResult]) {
        let multiTimeframeResults = analyzeComprehensivePatterns(marketData: marketData)
        let confluencePatterns = technicalAnalysisEngine.analyzePatternConfluence(multiTimeframeResults: multiTimeframeResults)
        
        return (patterns: multiTimeframeResults, confluence: confluencePatterns)
    }
    
    // Real-time pattern scanning for alerts with adaptive thresholds
    func scanForPatternAlerts(marketData: [MarketData], alertThreshold: Double = 0.7) -> [PatternAlert] {
        let analysisResults = analyzeComprehensivePatterns(marketData: marketData)
        var alerts: [PatternAlert] = []

        for (timeframe, patterns) in analysisResults {
            for pattern in patterns {
                // Use adaptive threshold for this pattern type
                let adaptiveThreshold = getAdaptiveThreshold(for: pattern.pattern)
                let effectiveThreshold = min(alertThreshold, adaptiveThreshold)

                if pattern.confidence >= effectiveThreshold {
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
    
    struct PatternAlert: Identifiable {
        let id = UUID()
        let pattern: PatternResult
        let timeframe: String
        let timestamp: Date
        let urgency: AlertUrgency
        
        var alertMessage: String {
            return "\(urgency.rawValue): \(pattern.pattern) detected on \(timeframe) with \(Int(pattern.confidence * 100))% confidence. Signal: \(pattern.signal.rawValue)"
        }
    }
    
    struct ConfluencePattern: Identifiable {
        let id = UUID()
        let patterns: [PatternResult]
        let timeframes: [String]
        let overallConfidence: Double
        let signal: TechnicalAnalysisEngine.TradingSignal
        let strength: PatternStrength
        let timestamp: Date
        
        var description: String {
            let patternNames = patterns.map { $0.pattern }.joined(separator: ", ")
            let timeframeList = timeframes.joined(separator: ", ")
            return "\(patternNames) confluence across \(timeframeList)"
        }
        
        var confluenceScore: Double {
            let timeframeBonus = Double(timeframes.count) * 0.1
            let patternBonus = Double(patterns.count) * 0.05
            return min(overallConfidence + timeframeBonus + patternBonus, 1.0)
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

        guard prices.count >= 50 else { return .sideways }
        
        // Calculate trend strength
        let shortMA = technicalAnalysisEngine.calculateSMA(prices: Array(prices.suffix(10)), period: 10)
        let longMA = technicalAnalysisEngine.calculateSMA(prices: Array(prices.suffix(50)), period: 50)
        
        let trendStrength = abs(shortMA - longMA) / longMA
        let volatility = prices.suffix(20).map { $0 }.standardDeviation() / prices.average()
        
        // Determine regime
        if trendStrength > 0.05 {
            return shortMA > longMA ? .bullish : .bearish
        } else if volatility > 0.02 {
            return .volatile
        } else {
            return .sideways
        }
    }
    
    enum MarketRegime {
        case bullish
        case bearish
        case sideways
        case volatile
        
        var description: String {
            switch self {
            case .bullish: return "Bullish"
            case .bearish: return "Bearish"
            case .sideways: return "Sideways"
            case .volatile: return "Volatile"
            }
        }
    }
    
    // Pattern success rate tracking - requires actual trade outcome data
    func trackPatternPerformance(historicalData: [MarketData], patterns: [PatternResult], tradeOutcomes: [String: Bool] = [:]) -> [String: Double] {
        guard !tradeOutcomes.isEmpty else {
            print("Error: No trade outcome data available for pattern performance tracking")
            return [:]
        }
        
        var performanceTracking: [String: (correct: Int, total: Int)] = [:]
        
        // Track performance based on actual trade outcomes
        for pattern in patterns {
            let key = pattern.pattern
            if performanceTracking[key] == nil {
                performanceTracking[key] = (0, 0)
            }
            
            // Use actual trade outcome if available
            if let outcome = tradeOutcomes[key] {
                performanceTracking[key]!.total += 1
                if outcome {
                    performanceTracking[key]!.correct += 1
                }
            }
        }
        
        // Convert to success rates
        var successRates: [String: Double] = [:]
        for (pattern, stats) in performanceTracking {
            successRates[pattern] = stats.total > 0 ? Double(stats.correct) / Double(stats.total) : 0.0
        }
        
        return successRates
    }

    // Pattern recognition validation - requires real market data
    func validatePatternRecognition(marketData: [MarketData]) -> [PatternResult] {
        guard !marketData.isEmpty else {
            print("Error: No market data available for pattern recognition")
            return []
        }
        
        let highs = marketData.map { $0.price } // Simplified - would need actual OHLC data
        let lows = marketData.map { $0.price }
        let closes = marketData.map { $0.price }
        let opens = marketData.map { $0.price }

        return analyzePatterns(highs: highs, lows: lows, closes: closes, opens: opens)
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
            case .bullish:
                // In bullish markets, prioritize buy signals and continuation patterns
                return pattern.signal == .buy || pattern.signal == .strongBuy ||
                       pattern.pattern.contains("Flag") || pattern.pattern.contains("Triangle")
                
            case .bearish:
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
    
    // MARK: - ContentView Integration Methods
    
    func analyzeMultiTimeframe(data: [MarketData]) -> [String: [PatternResult]] {
        return technicalAnalysisEngine.analyzeMultiTimeframe(data: data)
    }
    
    func generateAlerts(from analysis: [String: [PatternResult]]) -> [PatternAlert] {
        var alerts: [PatternAlert] = []
        
        for (timeframe, patterns) in analysis {
            for pattern in patterns {
                if pattern.confidence >= 0.7 { // Alert threshold
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
            if first.urgency.priority != second.urgency.priority {
                return first.urgency.priority > second.urgency.priority
            }
            return first.pattern.confidence > second.pattern.confidence
        }
        
        return alerts
    }
    
    func findConfluencePatterns(analysis: [String: [PatternResult]]) -> [PatternResult] {
        return technicalAnalysisEngine.analyzePatternConfluence(multiTimeframeResults: analysis)
    }
    
    func determineMarketRegime(data: [MarketData]) -> MarketRegime {
        return detectMarketRegime(marketData: data)
    }

    // MARK: - Advanced ML Components

    /// Feature extractor for pattern recognition
    class PatternFeatureExtractor {
        func extractFeatures(from marketData: [MarketData], pattern: PatternResult, technicalAnalysisEngine: TechnicalAnalysisEngine) -> [Double] {
            let prices = marketData.map { $0.price }
            let volumes = marketData.map { Double($0.volume) }

            // Price-based features
            let returns = calculateReturns(prices: prices)
            let volatility = prices.standardDeviation()
            let momentum = calculateMomentum(prices: prices, period: 10)

            // Volume-based features
            let volumeMA = technicalAnalysisEngine.calculateSMA(prices: volumes, period: 20)
            let volumeRatio = volumes.last ?? 0 / volumeMA

            // Pattern-specific features
            let patternStrength = pattern.strength == .veryStrong ? 1.0 :
                                 pattern.strength == .strong ? 0.8 :
                                 pattern.strength == .moderate ? 0.6 : 0.4

            let signalStrength = pattern.signal == .strongBuy || pattern.signal == .strongSell ? 1.0 : 0.7

            return [
                pattern.confidence,
                patternStrength,
                signalStrength,
                volatility,
                momentum,
                volumeRatio,
                returns.last ?? 0,
                Double(marketData.count)
            ]
        }

        private func calculateReturns(prices: [Double]) -> [Double] {
            guard prices.count > 1 else { return [] }
            var returns: [Double] = []
            for i in 1..<prices.count {
                returns.append((prices[i] - prices[i-1]) / prices[i-1])
            }
            return returns
        }

        private func calculateMomentum(prices: [Double], period: Int) -> Double {
            guard prices.count >= period else { return 0 }
            let recent = Array(prices.suffix(period))
            let older = Array(prices.suffix(period * 2).prefix(period))
            return (recent.average() - older.average()) / older.average()
        }
    }

    /// Neural network predictor for pattern confidence
    class NeuralNetworkPredictor {
        private var weights: [[Double]] = []
        private var biases: [Double] = []
        private let learningRate = 0.01

        init() {
            initializeNetwork()
        }

        private func initializeNetwork() {
            // Simple 2-layer network: 8 inputs -> 16 hidden -> 1 output
            weights = [
                Array(repeating: Double.random(in: -0.1...0.1), count: 16), // Input to hidden
                Array(repeating: Double.random(in: -0.1...0.1), count: 1)   // Hidden to output
            ]
            biases = [Double.random(in: -0.1...0.1), Double.random(in: -0.1...0.1)]
        }

        func predict(features: [Double]) -> Double {
            // Forward pass
            let hidden = sigmoid(dotProduct(weights[0], features) + biases[0])
            let output = sigmoid(hidden * weights[1][0] + biases[1])
            return output
        }

        func train(features: [Double], target: Double) {
            let prediction = predict(features: features)
            let error = target - prediction

            // Backpropagation (simplified)
            let outputDelta = error * sigmoidDerivative(prediction)
            let hiddenDelta = outputDelta * weights[1][0] * sigmoidDerivative(predict(features: features))

            // Update weights and biases
            for i in 0..<weights[0].count {
                weights[0][i] += learningRate * hiddenDelta * features[i % features.count]
            }
            weights[1][0] += learningRate * outputDelta * predict(features: features)
            biases[1] += learningRate * outputDelta
            biases[0] += learningRate * hiddenDelta
        }

        private func sigmoid(_ x: Double) -> Double {
            return 1 / (1 + exp(-x))
        }

        private func sigmoidDerivative(_ x: Double) -> Double {
            return x * (1 - x)
        }

        private func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
            return zip(a, b).map(*).reduce(0, +)
        }
    }

    /// Ensemble model combining multiple ML approaches
    class EnsemblePatternModel {
        private var models: [String: NeuralNetworkPredictor] = [:]
        private var modelWeights: [String: Double] = [:]
        private var deepLearningModel: DeepLearningPatternModel?

        init() {
            initializeModels()
            initializeDeepLearningModel()
        }

        private func initializeModels() {
            let patternTypes = ["HeadAndShoulders", "DoubleTop", "Triangle", "Flag", "CupAndHandle"]
            for pattern in patternTypes {
                models[pattern] = NeuralNetworkPredictor()
                modelWeights[pattern] = 1.0
            }
        }

        private func initializeDeepLearningModel() {
            deepLearningModel = DeepLearningPatternModel()
        }

        func predictEnsemble(pattern: String, features: [Double]) -> Double {
            guard let model = models[pattern] else {
                return features.first ?? 0.5 // Fallback to base confidence
            }

            let basePrediction = model.predict(features: features)
            let weight = modelWeights[pattern] ?? 1.0

            // Combine with historical performance
            let historicalAdjustment = calculateHistoricalAdjustment(for: pattern)

            // Add deep learning prediction if available
            let deepPrediction = deepLearningModel?.predict(pattern: pattern, features: features) ?? basePrediction
            let deepWeight = 0.3 // 30% weight to deep learning

            let combinedPrediction = (basePrediction * weight + historicalAdjustment + deepPrediction * deepWeight) / (weight + 1.0 + deepWeight)

            return min(1.0, max(0.0, combinedPrediction))
        }

        func trainEnsemble(pattern: String, features: [Double], target: Double) {
            guard let model = models[pattern] else { return }
            model.train(features: features, target: target)

            // Train deep learning model
            deepLearningModel?.train(pattern: pattern, features: features, target: target)

            // Update model weight based on recent performance
            let recentAccuracy = calculateRecentAccuracy(for: pattern)
            modelWeights[pattern] = max(0.1, recentAccuracy)
        }

        private func calculateHistoricalAdjustment(for pattern: String) -> Double {
            // This would use historical pattern performance data
            // For now, return a small adjustment
            return Double.random(in: -0.1...0.1)
        }

        private func calculateRecentAccuracy(for pattern: String) -> Double {
            // Calculate accuracy over recent predictions
            // For now, return a default value
            return 0.7
        }
    }

    /// Deep Learning Model for Advanced Pattern Recognition
    class DeepLearningPatternModel {
        private var patternNetworks: [String: DeepNeuralNetwork] = [:]
        private var attentionMechanism: AttentionLayer?

        init() {
            initializeNetworks()
            attentionMechanism = AttentionLayer()
        }

        private func initializeNetworks() {
            let patternTypes = ["HeadAndShoulders", "DoubleTop", "Triangle", "Flag", "CupAndHandle"]
            for pattern in patternTypes {
                patternNetworks[pattern] = DeepNeuralNetwork(inputSize: 8, hiddenSizes: [64, 32, 16], outputSize: 1)
            }
        }

        func predict(pattern: String, features: [Double]) -> Double {
            guard let network = patternNetworks[pattern] else {
                return features.first ?? 0.5
            }

            // Apply attention mechanism to focus on relevant features
            let attendedFeatures = attentionMechanism?.applyAttention(to: features) ?? features

            return network.predict(features: attendedFeatures)
        }

        func train(pattern: String, features: [Double], target: Double) {
            guard let network = patternNetworks[pattern] else { return }

            // Apply attention mechanism
            let attendedFeatures = attentionMechanism?.applyAttention(to: features) ?? features

            network.train(features: attendedFeatures, target: target, learningRate: 0.001, epochs: 10)

            // Update attention mechanism
            attentionMechanism?.updateAttention(features: features, target: target)
        }
    }

    /// Deep Neural Network Implementation
    class DeepNeuralNetwork {
        private var layers: [NeuralLayer] = []
        private let learningRate: Double

        init(inputSize: Int, hiddenSizes: [Int], outputSize: Int, learningRate: Double = 0.01) {
            self.learningRate = learningRate

            // Input layer
            layers.append(NeuralLayer(inputSize: inputSize, outputSize: hiddenSizes.first ?? 32))

            // Hidden layers
            for i in 0..<hiddenSizes.count - 1 {
                layers.append(NeuralLayer(inputSize: hiddenSizes[i], outputSize: hiddenSizes[i + 1]))
            }

            // Output layer
            layers.append(NeuralLayer(inputSize: hiddenSizes.last ?? 32, outputSize: outputSize))
        }

        func predict(features: [Double]) -> Double {
            var activations = features

            for layer in layers {
                activations = layer.forward(activations)
            }

            return activations.first ?? 0.0
        }

        func train(features: [Double], target: Double, learningRate: Double, epochs: Int) {
            for _ in 0..<epochs {
                // Forward pass
                var activations = features
                var layerOutputs: [[Double]] = [activations]

                for layer in layers {
                    activations = layer.forward(activations)
                    layerOutputs.append(activations)
                }

                // Backward pass
                var error = [target - activations[0]]
                for i in (0..<layers.count).reversed() {
                    error = layers[i].backward(error, learningRate: learningRate, previousActivations: layerOutputs[i])
                }
            }
        }
    }

    /// Neural Layer for Deep Network
    class NeuralLayer {
        private var weights: [[Double]]
        private var biases: [Double]
        private var lastInput: [Double] = []
        private var lastOutput: [Double] = []

        init(inputSize: Int, outputSize: Int) {
            // Initialize weights and biases randomly
            weights = (0..<outputSize).map { _ in
                (0..<inputSize).map { _ in Double.random(in: -0.1...0.1) }
            }
            biases = Array(repeating: 0.0, count: outputSize)
        }

        func forward(_ input: [Double]) -> [Double] {
            lastInput = input
            var output: [Double] = []

            for i in 0..<weights.count {
                var sum = biases[i]
                for j in 0..<input.count {
                    sum += weights[i][j] * input[j]
                }
                output.append(tanh(sum)) // Tanh activation
            }

            lastOutput = output
            return output
        }

        func backward(_ error: [Double], learningRate: Double, previousActivations: [Double]) -> [Double] {
            var nextError: [Double] = Array(repeating: 0.0, count: lastInput.count)

            for i in 0..<weights.count {
                let delta = error[i] * (1 - lastOutput[i] * lastOutput[i]) // Derivative of tanh

                for j in 0..<weights[i].count {
                    nextError[j] += weights[i][j] * delta
                    weights[i][j] += learningRate * delta * lastInput[j]
                }

                biases[i] += learningRate * delta
            }

            return nextError
        }
    }

    /// Attention Mechanism for Feature Focus
    class AttentionLayer {
        private var attentionWeights: [Double] = []

        init() {
            // Initialize attention weights (one per feature)
            attentionWeights = Array(repeating: 1.0/8.0, count: 8) // Assuming 8 features
        }

        func applyAttention(to features: [Double]) -> [Double] {
            return zip(features, attentionWeights).map { $0 * $1 }
        }

        func updateAttention(features: [Double], target: Double) {
            // Simple attention update based on prediction error
            let prediction = applyAttention(to: features).reduce(0, +)
            let error = target - prediction

            // Update attention weights based on feature importance
            for i in 0..<attentionWeights.count {
                let gradient = error * features[i]
                attentionWeights[i] += 0.001 * gradient
            }

            // Normalize attention weights
            let sum = attentionWeights.reduce(0, +)
            attentionWeights = attentionWeights.map { $0 / sum }
        }
    }

    // MARK: - Enhanced ML Methods

    /// Advanced pattern detection using ML ensemble
    func detectPatternsWithML(marketData: [MarketData]) -> [PatternResult] {
        let basePatterns = technicalAnalysisEngine.analyzeMultiTimeframe(data: marketData)
        var enhancedPatterns: [PatternResult] = []

        for (timeframe, patterns) in basePatterns {
            for pattern in patterns {
                let features = patternFeatureExtractor.extractFeatures(from: marketData, pattern: pattern, technicalAnalysisEngine: technicalAnalysisEngine)
                let mlConfidence = ensembleModel.predictEnsemble(pattern: pattern.pattern, features: features)

                // Combine base confidence with ML prediction
                let combinedConfidence = (pattern.confidence + mlConfidence) / 2.0

                let enhancedPattern = PatternResult(
                    pattern: pattern.pattern,
                    signal: pattern.signal,
                    confidence: combinedConfidence,
                    timeframe: timeframe,
                    strength: pattern.strength,
                    targets: pattern.targets,
                    stopLoss: pattern.stopLoss,
                    successRate: pattern.successRate
                )

                enhancedPatterns.append(enhancedPattern)
            }
        }

        return enhancedPatterns
    }

    /// Train ML models with pattern performance data
    func trainMLModels(with performances: [PatternPerformance]) {
        for performance in performances {
            ensembleModel.trainEnsemble(
                pattern: performance.pattern,
                features: performance.features,
                target: performance.outcome ? 1.0 : 0.0
            )
        }
    }

    /// Get ML-based pattern insights
    func getPatternInsights(pattern: String, marketData: [MarketData]) -> PatternInsights {
        let features = patternFeatureExtractor.extractFeatures(from: marketData, pattern: PatternResult(
            pattern: pattern,
            signal: .hold,
            confidence: 0.5,
            timeframe: "1H",
            strength: .moderate,
            targets: [],
            stopLoss: 0,
            successRate: 0.5
        ), technicalAnalysisEngine: technicalAnalysisEngine)

        let mlPrediction = ensembleModel.predictEnsemble(pattern: pattern, features: features)
        let regime = detectMarketRegime(marketData: marketData)

        return PatternInsights(
            pattern: pattern,
            mlConfidence: mlPrediction,
            marketRegime: regime,
            recommendedAction: mlPrediction > 0.7 ? "Strong Signal" : "Monitor",
            riskLevel: calculateRiskLevel(prediction: mlPrediction, regime: regime)
        )
    }

    struct PatternInsights {
        let pattern: String
        let mlConfidence: Double
        let marketRegime: MarketRegime
        let recommendedAction: String
        let riskLevel: String
    }

    private func calculateRiskLevel(prediction: Double, regime: MarketRegime) -> String {
        let baseRisk = 1.0 - prediction

        switch regime {
        case .volatile:
            return baseRisk > 0.6 ? "High" : baseRisk > 0.4 ? "Medium" : "Low"
        case .bullish, .bearish:
            return baseRisk > 0.5 ? "Medium" : "Low"
        case .sideways:
            return baseRisk > 0.7 ? "High" : baseRisk > 0.5 ? "Medium" : "Low"
        }
    }
}
