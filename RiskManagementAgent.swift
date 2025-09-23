import Foundation

class RiskManagementAgent: BaseAgent {
    private let maxLossPercentage: Double = 0.02 // 2% max loss
    
    override func makeDecision(marketData: MarketData, news: [Article]) -> String {
        let currentPrice = marketData.price
        let stopLoss = currentPrice * (1 - maxLossPercentage)
        
        if currentPrice <= stopLoss {
            return "Risk: Sell - Stop loss triggered"
        } else {
            return "Risk: Hold - Within acceptable risk limits"
        }
    }
}
