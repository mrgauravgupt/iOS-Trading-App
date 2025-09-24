import Foundation

class BacktestingEngine {
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
                let patternResults = analyzePatternsWithData(marketData: marketData, patterns: patterns)
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
            return PatternRecognitionEngine.PatternResult(pattern: pattern, signal: signal, confidence: confidence)
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
}

struct BacktestResult {
    let totalReturn: Double
    let winRate: Double
    let totalTrades: Int
}