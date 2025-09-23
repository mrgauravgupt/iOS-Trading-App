import Foundation

class AIAgentTrader {
    private let agentCoordinator = AgentCoordinator()
    private let orderExecutor = OrderExecutor()
    
    func executeAITrade(marketData: MarketData, news: [Article]) {
        let decision = agentCoordinator.coordinateDecision(marketData: marketData, news: news)
        
        if decision.contains("Buy") {
            let success = orderExecutor.executeOrder(symbol: marketData.symbol, quantity: 1, price: marketData.price, type: .buy)
            print("AI Trade: Buy executed: \(success)")
        } else if decision.contains("Sell") {
            let success = orderExecutor.executeOrder(symbol: marketData.symbol, quantity: 1, price: marketData.price, type: .sell)
            print("AI Trade: Sell executed: \(success)")
        } else {
            print("AI Trade: Hold")
        }
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
}
