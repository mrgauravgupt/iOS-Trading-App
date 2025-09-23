import Foundation

class AdvancedRiskManager {
    private let baseStopLossPercentage: Double = 0.02
    private let trailingStopLossPercentage: Double = 0.05
    
    func calculateDynamicStopLoss(currentPrice: Double, entryPrice: Double, volatility: Double) -> Double {
        let baseStopLoss = entryPrice * (1 - baseStopLossPercentage)
        let trailingStopLoss = currentPrice * (1 - trailingStopLossPercentage)
        
        // Adjust based on volatility
        if volatility > 0.1 {
            return max(baseStopLoss, trailingStopLoss)
        } else {
            return baseStopLoss
        }
    }
    
    func optimizePortfolio(holdings: [String: Int], currentPrices: [String: Double]) -> [String: Double] {
        var optimizedWeights: [String: Double] = [:]
        
        // Simple equal weight optimization
        let totalHoldings = holdings.count
        for symbol in holdings.keys {
            optimizedWeights[symbol] = 1.0 / Double(totalHoldings)
        }
        
        return optimizedWeights
    }
    
    func calculateStressTest(holdings: [String: Int], currentPrices: [String: Double], stressFactor: Double) -> Double {
        var stressedValue = 0.0
        for (symbol, quantity) in holdings {
            if let price = currentPrices[symbol] {
                let stressedPrice = price * (1 - stressFactor)
                stressedValue += Double(quantity) * stressedPrice
            }
        }
        return stressedValue
    }
}
