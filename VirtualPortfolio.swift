import Foundation

public struct Trade {
    let symbol: String
    let quantity: Int
    let price: Double
    let type: TradeType
    let timestamp: Date
    
    public enum TradeType {
        case buy, sell
    }
}

public class VirtualPortfolio {
    private var balance: Double = 100000.0 // Starting with 1 lakh
    private var holdings: [String: Int] = [:]
    private var trades: [Trade] = []
    
    func buy(symbol: String, quantity: Int, price: Double) -> Bool {
        let totalCost = Double(quantity) * price
        if balance >= totalCost {
            balance -= totalCost
            holdings[symbol] = (holdings[symbol] ?? 0) + quantity
            trades.append(Trade(symbol: symbol, quantity: quantity, price: price, type: .buy, timestamp: Date()))
            return true
        }
        return false
    }
    
    func sell(symbol: String, quantity: Int, price: Double) -> Bool {
        if let currentQuantity = holdings[symbol], currentQuantity >= quantity {
            let totalValue = Double(quantity) * price
            balance += totalValue
            holdings[symbol] = currentQuantity - quantity
            if holdings[symbol] == 0 {
                holdings.removeValue(forKey: symbol)
            }
            trades.append(Trade(symbol: symbol, quantity: quantity, price: price, type: .sell, timestamp: Date()))
            return true
        }
        return false
    }
    
    func getBalance() -> Double {
        return balance
    }
    
    func getHoldings() -> [String: Int] {
        return holdings
    }
    
    func getTrades() -> [Trade] {
        return trades
    }
    
    func getPortfolioValue(currentPrices: [String: Double]) -> Double {
        var totalValue = balance
        for (symbol, quantity) in holdings {
            if let price = currentPrices[symbol] {
                totalValue += Double(quantity) * price
            }
        }
        return totalValue
    }
}