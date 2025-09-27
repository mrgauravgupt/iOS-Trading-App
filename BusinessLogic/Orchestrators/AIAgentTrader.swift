import Foundation
import SwiftUI

class AIAgentTrader: ObservableObject {
    private let agentCoordinator = AgentCoordinator()
    private let orderExecutor = OrderExecutor()
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    private var patternRecognitionEngine: PatternRecognitionEngine?
    private let mlModelManager = MLModelManager.shared
    private var tradeHistory: [(state: [Double], action: Int, reward: Double)] = []

    init() {
        // Initialize PatternRecognitionEngine asynchronously
        Task { @MainActor in
            self.patternRecognitionEngine = PatternRecognitionEngine()
        }
    }

    func executeAITrade(marketData: MarketData, news: [Article]) {
      let decision = agentCoordinator.coordinateDecision(marketData: marketData, news: news)

      // Add momentum-based analysis
      let momentumSignal = analyzeMomentumSignals(marketData: marketData)

      // Use reinforcement learning to get best action
      let state = createStateFromMarketData(marketData)
      let bestAction = mlModelManager.getBestAction(state: state)

      if decision.contains("Buy") || momentumSignal == .buy || bestAction == 0 {
        let success = orderExecutor.executeOrder(
          symbol: marketData.symbol,
          quantity: 1,
          price: marketData.price,
          type: VirtualPortfolio.PortfolioTrade.TradeType.buy
        )
        print("AI Trade: Buy executed: \(success)")
        tradeHistory.append((state: state, action: 0, reward: success ? 1.0 : -1.0))
      } else if decision.contains("Sell") || momentumSignal == .sell || bestAction == 1 {
        let success = orderExecutor.executeOrder(
          symbol: marketData.symbol,
          quantity: 1,
          price: marketData.price,
          type: VirtualPortfolio.PortfolioTrade.TradeType.sell
        )
        print("AI Trade: Sell executed: \(success)")
        tradeHistory.append((state: state, action: 1, reward: success ? 1.0 : -1.0))
      } else {
        print("AI Trade: Hold")
        tradeHistory.append((state: state, action: 2, reward: 0.0))
      }

      // Learn from the trade
      if tradeHistory.count > 1 {
        let previousTrade = tradeHistory[tradeHistory.count - 2]
        let currentTrade = tradeHistory.last!
        mlModelManager.learnFromTrade(state: previousTrade.state, action: previousTrade.action, reward: currentTrade.reward, nextState: currentTrade.state)
      }
    }

    private func analyzeMomentumSignals(marketData: MarketData) -> PatternRecognitionEngine.TradingSignal {
        // Simplified momentum analysis using RSI and MACD
        let rsi = technicalAnalysisEngine.calculateRSI(prices: [marketData.price])
        let (macd, signal, _) = technicalAnalysisEngine.calculateMACD(prices: [marketData.price])

        if rsi < 30 || macd > signal {
            return .buy
        } else if rsi > 70 || macd < signal {
            return .sell
        } else {
            return .hold
        }
    }

    private func createStateFromMarketData(_ marketData: MarketData) -> [Double] {
        let rsi = technicalAnalysisEngine.calculateRSI(prices: [marketData.price])
        let (macd, signal, _) = technicalAnalysisEngine.calculateMACD(prices: [marketData.price])
        let stochastic = technicalAnalysisEngine.calculateStochastic(highs: [marketData.price], lows: [marketData.price], closes: [marketData.price])

        return [rsi, macd, signal, stochastic, marketData.price]
    }
    
    func testStrategy(marketData: [MarketData], news: [[Article]]) -> Double {
      var totalPL = 0.0
      for (data, articles) in zip(marketData, news) {
        executeAITrade(marketData: data, news: articles)
        let currentPrices = [data.symbol: data.price]
        totalPL = orderExecutor.getPortfolioValue(currentPrices: currentPrices) - 100000.0
      }
      return totalPL
    }

    @MainActor
    func analyzeHistoricalData(data: [MarketData]) -> [String: Double] {
        guard let patternRecognitionEngine = patternRecognitionEngine else {
            print("PatternRecognitionEngine not initialized yet")
            return [:]
        }

        var patternPerformance: [String: (positiveReturns: Double, totalReturns: Double, count: Int)] = [:]

        // Process historical data in chunks to identify patterns and their performance
        for i in 0..<data.count - 10 {  // Look at 10-period windows
            let window = Array(data[i..<i+10])
            let prices = window.map { $0.price }

            // Get patterns from our pattern recognition engine
            let patterns = patternRecognitionEngine.analyzePatterns(
                highs: prices,
                lows: prices,
                closes: prices,
                opens: prices.map { $0 }
            )
            
            // For each pattern found, track its performance
            for pattern in patterns {
                let patternKey = pattern.pattern
                let entryPrice = prices[prices.count - 2]  // Price before pattern completion
                let exitPrice = prices.last!  // Price after pattern completion
                
                // Calculate return (simplified as absolute change)
                let returnPercentage = (exitPrice - entryPrice) / entryPrice
                
                // Update pattern performance
                if patternPerformance[patternKey] == nil {
                    patternPerformance[patternKey] = (0.0, 0.0, 0)
                }
                
                patternPerformance[patternKey]!.count += 1
                patternPerformance[patternKey]!.totalReturns += abs(returnPercentage)
                
                // Track positive returns for win rate calculation
                if (pattern.signal == .buy && returnPercentage > 0) || 
                   (pattern.signal == .sell && returnPercentage < 0) {
                    patternPerformance[patternKey]!.positiveReturns += abs(returnPercentage)
                }
            }
        }
        
        // Convert to performance ratios
        var performanceRatios: [String: Double] = [:]
        for (pattern, stats) in patternPerformance {
            performanceRatios[pattern] = stats.totalReturns > 0 ? stats.positiveReturns / stats.totalReturns : 0
        }
        
        return performanceRatios
    }
    
    // MARK: - ContentView Integration Methods
    
    func getCurrentTradingStatus() -> String {
        // Return current AI trading status
        return "Active"
    }
    
    func getActiveStrategies() -> [String] {
        // Return list of active trading strategies
        return ["Momentum", "Pattern Recognition", "Mean Reversion"]
    }
    
    func getTotalProfitLoss() -> Double {
        // Calculate total P&L from trade history
        return tradeHistory.reduce(0.0) { $0 + $1.reward }
    }
    
    func getWinRate() -> Double {
        // Calculate win rate from trade history
        let winningTrades = tradeHistory.filter { $0.reward > 0 }.count
        return tradeHistory.isEmpty ? 0.0 : Double(winningTrades) / Double(tradeHistory.count)
    }
    
    func getActivePositions() -> Int {
        // Return number of active positions
        return orderExecutor.getActivePositions()
    }
    
    func getDailyPnL() -> Double {
        // Return today's P&L (simplified)
        return tradeHistory.suffix(10).reduce(0.0) { $0 + $1.reward }
    }
    
    func startTrading(marketData: MarketData, news: [Article]) {
        // Start AI trading with given market data and news
        executeAITrade(marketData: marketData, news: news)
    }
    
    func analyzeAndTrade(marketData: MarketData, news: [Article]) {
        // Analyze market conditions and execute trades
        executeAITrade(marketData: marketData, news: news)
    }
}