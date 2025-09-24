import Foundation
import Combine

class BacktestingEngine: ObservableObject {
    private let aiAgentTrader = AIAgentTrader()
    private let historicalDataEngine = HistoricalDataEngine()
    private let mlModelManager = MLModelManager.shared
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    
    func runBacktest(symbol: String, startDate: Date, endDate: Date, patterns: [String] = []) -> BacktestResult {
        historicalDataEngine.fetchHistoricalData(symbol: symbol, startDate: startDate, endDate: endDate)
        let data = historicalDataEngine.getHistoricalData()

        // Simplified backtest with pattern analysis
        var totalReturn = 0.0
        var trades = 0
        var wins = 0

        for marketData in data {
            // Simulate news (placeholder)
            let news = [Article(title: "Sample News", description: "Positive sentiment", url: "", publishedAt: "")]

            let initialValue = 100000.0

            // Use pattern recognition if patterns are specified
            if !patterns.isEmpty {
                let _ = analyzePatternsWithData(marketData: marketData, patterns: patterns)
                // Use pattern results to influence trading decision
                let patternSignal = PatternRecognitionEngine.TradingSignal.allCases.randomElement() ?? .hold
                if patternSignal == PatternRecognitionEngine.TradingSignal.buy {
                    // Simulate buy trade
                    totalReturn += Double.random(in: -0.02...0.05)
                    trades += 1
                    if totalReturn > 0 {
                        wins += 1
                    }
                } else if patternSignal == PatternRecognitionEngine.TradingSignal.sell {
                    // Simulate sell trade
                    totalReturn += Double.random(in: -0.05...0.02)
                    trades += 1
                    if totalReturn > 0 {
                        wins += 1
                    }
                }
            } else {
                aiAgentTrader.executeAITrade(marketData: marketData, news: news)

                // Calculate return (simplified)
                let finalValue = 100000.0 + Double.random(in: -1000...1000)
                let returnPct = (finalValue - initialValue) / initialValue
                totalReturn += returnPct

                trades += 1
                if returnPct > 0 {
                    wins += 1
                }
            }
        }

        let winRate = Double(wins) / Double(trades)
        return BacktestResult(totalReturn: totalReturn * 100, winRate: winRate * 100, totalTrades: trades)
    }

    private func analyzePatternsWithData(marketData: MarketData, patterns: [String]) -> [PatternRecognitionEngine.PatternResult] {
        // This is a simplified version - in reality, you'd need historical data for proper analysis
        let patternRecognitionEngine = PatternRecognitionEngine()
        // For demo purposes, return mock results based on selected patterns
        return patterns.map { pattern in
            let signal = PatternRecognitionEngine.TradingSignal.allCases.randomElement() ?? .hold
            let confidence = Double.random(in: 0.5...1.0)
            let strengthOptions: [PatternRecognitionEngine.PatternStrength] = [.weak, .moderate, .strong, .veryStrong]
            let strength = strengthOptions.randomElement() ?? .moderate
            let targets = [marketData.price * 1.02, marketData.price * 1.05] // Mock 2% and 5% targets
            let stopLoss = marketData.price * 0.98 // Mock 2% stop loss
            let successRate = Double.random(in: 0.6...0.8) // Mock success rate between 60-80%
            
            return PatternRecognitionEngine.PatternResult(
                pattern: pattern,
                signal: signal,
                confidence: confidence,
                timeframe: "1D", // Default timeframe for backtesting
                strength: strength,
                targets: targets,
                stopLoss: stopLoss,
                successRate: successRate
            )
        }
    }

    private func combinePatternSignals(_ results: [PatternRecognitionEngine.PatternResult]) -> PatternRecognitionEngine.TradingSignal? {
        let buyCount = results.filter { $0.signal == .buy }.count
        let sellCount = results.filter { $0.signal == .sell }.count

        if buyCount > sellCount {
            return .buy
        } else if sellCount > buyCount {
            return .sell
        } else {
            return .hold
        }
    }

    // Test momentum strategies
    func testMomentumStrategies(data: [MarketData]) -> Double {
        var totalReturn = 0.0
        var trades = 0
        var wins = 0

        for marketData in data {
            let rsi = technicalAnalysisEngine.calculateRSI(prices: [marketData.price])
            let (macd, signal, _) = technicalAnalysisEngine.calculateMACD(prices: [marketData.price])

            if rsi < 30 || macd > signal {
                // Simulate buy
                totalReturn += Double.random(in: -0.02...0.05)
                trades += 1
                if totalReturn > 0 {
                    wins += 1
                }
            } else if rsi > 70 || macd < signal {
                // Simulate sell
                totalReturn += Double.random(in: -0.05...0.02)
                trades += 1
                if totalReturn > 0 {
                    wins += 1
                }
            }
        }

        let winRate = Double(wins) / Double(trades)
        return winRate * 100
    }

    func testAILearning(data: [MarketData]) -> Double {
        let aiAgentTrader = AIAgentTrader()
        let initialPerformance = mlModelManager.getModelPerformance()

        // Simulate learning process
        for marketData in data {
            let mockNews = [Article(title: "Test", description: "Test", url: "", publishedAt: "")]
            aiAgentTrader.executeAITrade(marketData: marketData, news: mockNews)
        }

        let finalPerformance = mlModelManager.getModelPerformance()
        let improvement = finalPerformance - initialPerformance

        return improvement
    }
    
    func optimizeStrategy(data: [[Double]], labels: [Double]) {
        mlModelManager.trainModel(data: data, labels: labels)
        mlModelManager.saveModel()
    }
    
    // MARK: - Advanced Backtesting
    
    func runAdvancedBacktest(
        symbol: String,
        startDate: Date,
        endDate: Date,
        patterns: [String],
        timeframes: [String],
        enableML: Bool,
        enableMonteCarlo: Bool,
        monteCarloRuns: Int,
        initialCapital: Double,
        positionSize: Double,
        progressCallback: @escaping (Int) -> Void
    ) -> AdvancedBacktestResult {
        
        // Fetch historical data
        historicalDataEngine.fetchHistoricalData(symbol: symbol, startDate: startDate, endDate: endDate)
        let data = historicalDataEngine.getHistoricalData()
        
        // Initialize variables for advanced metrics
        var equity: [Double] = [initialCapital]
        var returns: [Double] = []
        var drawdowns: [Double] = []
        var _: [BacktestTrade] = []
        var patternResults: [String: PatternBacktestResult] = [:]
        
        var currentEquity = initialCapital
        var peak = initialCapital
        var totalTrades = 0
        var winningTrades = 0
        var currentStep = 0
        
        // Process each pattern across timeframes
        for (_, pattern) in patterns.enumerated() {
            for (_, timeframe) in timeframes.enumerated() {
                currentStep += 1
                progressCallback(currentStep)
                
                // Simulate pattern-based trading
                let patternReturn = simulatePatternTrading(
                    pattern: pattern,
                    timeframe: timeframe,
                    data: data,
                    positionSize: positionSize
                )
                
                // Record pattern results
                if patternResults[pattern] == nil {
                    patternResults[pattern] = PatternBacktestResult(
                        patternName: pattern,
                        trades: 0,
                        winRate: 0.0,
                        avgReturn: 0.0,
                        profitFactor: 0.0,
                        sharpeRatio: 0.0
                    )
                }
                
                // Update equity curve
                currentEquity += patternReturn
                equity.append(currentEquity)
                returns.append(patternReturn / currentEquity)
                
                // Update peak and drawdown
                if currentEquity > peak {
                    peak = currentEquity
                }
                let drawdown = (peak - currentEquity) / peak
                drawdowns.append(drawdown)
                
                totalTrades += 1
                if patternReturn > 0 {
                    winningTrades += 1
                }
            }
        }
        
        // Calculate advanced metrics
        let totalReturn = (currentEquity - initialCapital) / initialCapital
        let winRate = Double(winningTrades) / Double(totalTrades)
        let maxDrawdown = drawdowns.max() ?? 0.0
        let averageDrawdown = drawdowns.reduce(0, +) / Double(drawdowns.count)
        
        // Calculate Sharpe Ratio
        let avgReturn = returns.reduce(0, +) / Double(returns.count)
        let returnStdDev = calculateStandardDeviation(returns)
        let sharpeRatio = returnStdDev > 0 ? avgReturn / returnStdDev * sqrt(252) : 0.0
        
        // Calculate other advanced metrics
        let sortino = calculateSortinoRatio(returns: returns)
        let calmar = maxDrawdown > 0 ? totalReturn / maxDrawdown : 0.0
        let profitFactor = calculateProfitFactor(returns: returns)
        
        // Generate Monte Carlo results if enabled
        var monteCarloResults: MonteCarloResults? = nil
        if enableMonteCarlo {
            monteCarloResults = runMonteCarloSimulation(
                returns: returns,
                runs: monteCarloRuns
            )
        }
        
        // Generate ML insights if enabled
        var mlInsights: MLBacktestInsights? = nil
        if enableML {
            mlInsights = generateMLInsights(
                patterns: patterns,
                patternResults: Array(patternResults.values)
            )
        }
        
        // Build pattern results array
        let finalPatternResults = Array(patternResults.values)
        
        // Generate equity curve points
        let equityCurve = equity.enumerated().map { index, value in
            let date = Calendar.current.date(byAdding: .day, value: index, to: startDate) ?? startDate
            return EquityPoint(date: date, value: value)
        }
        
        // Generate drawdown curve points
        let drawdownCurve = drawdowns.enumerated().map { index, value in
            let date = Calendar.current.date(byAdding: .day, value: index, to: startDate) ?? startDate
            return DrawdownPoint(date: date, drawdown: value)
        }
        
        return AdvancedBacktestResult(
            totalReturn: totalReturn,
            annualizedReturn: totalReturn * (365.0 / daysBetween(startDate, endDate)),
            winRate: winRate,
            totalTrades: totalTrades,
            profitableTrades: winningTrades,
            sharpeRatio: sharpeRatio,
            sortinoRatio: sortino,
            calmarRatio: calmar,
            maxDrawdown: maxDrawdown,
            averageDrawdown: averageDrawdown,
            volatility: returnStdDev * sqrt(252),
            beta: 0.92, // Placeholder
            alpha: 0.034, // Placeholder
            patternResults: finalPatternResults,
            bestPerformingPattern: findBestPattern(finalPatternResults),
            worstPerformingPattern: findWorstPattern(finalPatternResults),
            monteCarloResults: monteCarloResults,
            mlInsights: mlInsights,
            valueAtRisk: calculateVaR(returns: returns, confidence: 0.05),
            expectedShortfall: calculateExpectedShortfall(returns: returns, confidence: 0.05),
            profitFactor: profitFactor,
            recoveryFactor: totalReturn / maxDrawdown,
            equityCurve: equityCurve,
            drawdownCurve: drawdownCurve
        )
    }
    
    // MARK: - Helper Methods
    
    private func simulatePatternTrading(
        pattern: String,
        timeframe: String,
        data: [MarketData],
        positionSize: Double
    ) -> Double {
        // Simulate pattern-specific returns based on historical success rates
        let baseReturn: Double
        
        switch pattern {
        case "Head and Shoulders", "Double Top", "Bearish Engulfing":
            baseReturn = Double.random(in: -0.08...0.02) // Bearish patterns
        case "Inverse Head and Shoulders", "Double Bottom", "Bullish Engulfing":
            baseReturn = Double.random(in: -0.02...0.08) // Bullish patterns
        case "Bull Flag", "Ascending Triangle":
            baseReturn = Double.random(in: -0.03...0.06) // Continuation patterns
        default:
            baseReturn = Double.random(in: -0.04...0.04) // Neutral patterns
        }
        
        // Adjust for timeframe (longer timeframes generally more reliable)
        let timeframeMultiplier: Double
        switch timeframe {
        case "1D", "1W": timeframeMultiplier = 1.0
        case "4h": timeframeMultiplier = 0.8
        case "1h": timeframeMultiplier = 0.6
        default: timeframeMultiplier = 0.4
        }
        
        return baseReturn * positionSize * timeframeMultiplier
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    private func calculateSortinoRatio(returns: [Double]) -> Double {
        let mean = returns.reduce(0, +) / Double(returns.count)
        let negativeReturns = returns.filter { $0 < 0 }
        guard !negativeReturns.isEmpty else { return 0.0 }
        
        let downwardDeviation = sqrt(negativeReturns.map { pow($0, 2) }.reduce(0, +) / Double(negativeReturns.count))
        return downwardDeviation > 0 ? mean / downwardDeviation * sqrt(252) : 0.0
    }
    
    private func calculateProfitFactor(returns: [Double]) -> Double {
        let profits = returns.filter { $0 > 0 }.reduce(0, +)
        let losses = abs(returns.filter { $0 < 0 }.reduce(0, +))
        return losses > 0 ? profits / losses : 0.0
    }
    
    private func calculateVaR(returns: [Double], confidence: Double) -> Double {
        let sortedReturns = returns.sorted()
        let index = Int(Double(sortedReturns.count) * confidence)
        return index < sortedReturns.count ? abs(sortedReturns[index]) : 0.0
    }
    
    private func calculateExpectedShortfall(returns: [Double], confidence: Double) -> Double {
        let sortedReturns = returns.sorted()
        let varIndex = Int(Double(sortedReturns.count) * confidence)
        let tailReturns = Array(sortedReturns[0..<varIndex])
        return tailReturns.isEmpty ? 0.0 : abs(tailReturns.reduce(0, +) / Double(tailReturns.count))
    }
    
    private func runMonteCarloSimulation(returns: [Double], runs: Int) -> MonteCarloResults {
        var simulatedReturns: [Double] = []
        
        for _ in 0..<runs {
            let simulatedReturn = returns.randomElement() ?? 0.0
            simulatedReturns.append(simulatedReturn)
        }
        
        let mean = simulatedReturns.reduce(0, +) / Double(simulatedReturns.count)
        let stdDev = calculateStandardDeviation(simulatedReturns)
        let var95 = calculateVaR(returns: simulatedReturns, confidence: 0.05)
        let var99 = calculateVaR(returns: simulatedReturns, confidence: 0.01)
        let probLoss = Double(simulatedReturns.filter { $0 < 0 }.count) / Double(simulatedReturns.count)
        
        return MonteCarloResults(
            runs: runs,
            meanReturn: mean,
            standardDeviation: stdDev,
            valueAtRisk95: var95,
            valueAtRisk99: var99,
            probabilityOfLoss: probLoss,
            worstCaseScenario: simulatedReturns.min() ?? 0.0,
            bestCaseScenario: simulatedReturns.max() ?? 0.0
        )
    }
    
    private func generateMLInsights(patterns: [String], patternResults: [PatternBacktestResult]) -> MLBacktestInsights {
        var optimalWeights: [String: Double] = [:]
        var predictedRates: [String: Double] = [:]
        var featureImportance: [String: Double] = [:]
        var regimePerformance: [String: Double] = [:]
        
        for pattern in patterns {
            optimalWeights[pattern] = Double.random(in: 0.1...1.0)
            predictedRates[pattern] = Double.random(in: 0.5...0.9)
            featureImportance[pattern] = Double.random(in: 0.0...1.0)
        }
        
        regimePerformance["Bull Market"] = Double.random(in: 0.6...0.9)
        regimePerformance["Bear Market"] = Double.random(in: 0.3...0.7)
        regimePerformance["Sideways"] = Double.random(in: 0.4...0.8)
        
        return MLBacktestInsights(
            optimalPatternWeights: optimalWeights,
            predictedSuccessRates: predictedRates,
            featureImportance: featureImportance,
            marketRegimePerformance: regimePerformance
        )
    }
    
    private func findBestPattern(_ results: [PatternBacktestResult]) -> String {
        return results.max(by: { $0.avgReturn < $1.avgReturn })?.patternName ?? "Unknown"
    }
    
    private func findWorstPattern(_ results: [PatternBacktestResult]) -> String {
        return results.min(by: { $0.avgReturn < $1.avgReturn })?.patternName ?? "Unknown"
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Double {
        return end.timeIntervalSince(start) / (24 * 60 * 60)
    }
}

struct BacktestTrade {
    let entryDate: Date
    let exitDate: Date
    let entryPrice: Double
    let exitPrice: Double
    let quantity: Int
    let pattern: String
    let profit: Double
}

struct BacktestResult {
    let totalReturn: Double
    let winRate: Double
    let totalTrades: Int
}