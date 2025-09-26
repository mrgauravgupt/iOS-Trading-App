import Foundation

class PLCalculator {
    private let portfolio = VirtualPortfolio()
    
    func calculateUnrealizedPL(currentPrices: [String: Double]) -> Double {
        var unrealizedPL = 0.0
        let holdings = portfolio.getHoldings()
        
        for (symbol, quantity) in holdings {
            if let currentPrice = currentPrices[symbol] {
                // Assuming we have average buy price stored somewhere
                // For simplicity, using current price as reference
                unrealizedPL += Double(quantity) * (currentPrice - currentPrice) // Placeholder
            }
        }
        
        return unrealizedPL
    }
    
    func calculateRealizedPL() -> Double {
        let trades = portfolio.getTrades()
        var realizedPL = 0.0
        
        var buyPrices: [String: Double] = [:]
        
        for trade in trades {
            if trade.type == .buy {
                buyPrices[trade.symbol] = trade.price
            } else if trade.type == .sell, let buyPrice = buyPrices[trade.symbol] {
                let profit = Double(trade.quantity) * (trade.price - buyPrice)
                realizedPL += profit
                buyPrices.removeValue(forKey: trade.symbol)
            }
        }
        
        return realizedPL
    }
    
    func calculateTotalPL(currentPrices: [String: Double]) -> Double {
        return calculateUnrealizedPL(currentPrices: currentPrices) + calculateRealizedPL()
    }
}
