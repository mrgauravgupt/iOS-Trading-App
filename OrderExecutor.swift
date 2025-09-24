import Foundation

class OrderExecutor {
    private let portfolio = VirtualPortfolio()
    
    func executeOrder(symbol: String, quantity: Int, price: Double, type: VirtualPortfolio.PortfolioTrade.TradeType) -> Bool {
        switch type {
        case .buy:
            return portfolio.buy(symbol: symbol, quantity: quantity, price: price)
        case .sell:
            return portfolio.sell(symbol: symbol, quantity: quantity, price: price)
        }
    }
    
    func getPortfolioBalance() -> Double {
        return portfolio.getBalance()
    }
    
    func getPortfolioHoldings() -> [String: Int] {
        return portfolio.getHoldings()
    }
    
    func getPortfolioValue(currentPrices: [String: Double]) -> Double {
        return portfolio.getPortfolioValue(currentPrices: currentPrices)
    }
    
    func getTradeHistory() -> [VirtualPortfolio.PortfolioTrade] {
        return portfolio.getTrades()
    }
}