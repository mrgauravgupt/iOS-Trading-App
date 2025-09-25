import Foundation

public class VirtualPortfolio {
    // MARK: - Data Models
    public struct PortfolioTrade: Codable {
        let symbol: String
        let quantity: Int
        let price: Double
        let type: TradeType
        let timestamp: Date
        
        public enum TradeType: String, Codable {
            case buy, sell
        }
    }
    
    // MARK: - Properties
    private var balance: Double = 100000.0 // Starting with 1 lakh
    private var holdings: [String: Int] = [:]
    private var trades: [PortfolioTrade] = []
    
    // MARK: - UserDefaults Keys
    private let balanceKey = "VirtualPortfolio.balance"
    private let holdingsKey = "VirtualPortfolio.holdings"
    private let tradesKey = "VirtualPortfolio.trades"
    
    // MARK: - Initialization
    init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Trading Methods
    func buy(symbol: String, quantity: Int, price: Double) -> Bool {
        let totalCost = Double(quantity) * price
        if balance >= totalCost {
            balance -= totalCost
            holdings[symbol] = (holdings[symbol] ?? 0) + quantity
            trades.append(PortfolioTrade(symbol: symbol, quantity: quantity, price: price, type: .buy, timestamp: Date()))
            saveToUserDefaults()
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
            trades.append(PortfolioTrade(symbol: symbol, quantity: quantity, price: price, type: .sell, timestamp: Date()))
            saveToUserDefaults()
            return true
        }
        return false
    }
    
    // MARK: - Getter Methods
    func getBalance() -> Double {
        return balance
    }
    
    func getHoldings() -> [String: Int] {
        return holdings
    }
    
    func getTrades() -> [PortfolioTrade] {
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
    
    // MARK: - Persistence Methods
    
    /// Save portfolio data to UserDefaults
    private func saveToUserDefaults() {
        // Save balance
        UserDefaults.standard.set(balance, forKey: balanceKey)
        
        // Save holdings
        if let holdingsData = try? JSONEncoder().encode(holdings) {
            UserDefaults.standard.set(holdingsData, forKey: holdingsKey)
        }
        
        // Save trades
        if let tradesData = try? JSONEncoder().encode(trades) {
            UserDefaults.standard.set(tradesData, forKey: tradesKey)
        }
    }
    
    /// Load portfolio data from UserDefaults
    private func loadFromUserDefaults() {
        // Load balance
        if let savedBalance = UserDefaults.standard.object(forKey: balanceKey) as? Double {
            balance = savedBalance
        }
        
        // Load holdings
        if let holdingsData = UserDefaults.standard.data(forKey: holdingsKey),
           let savedHoldings = try? JSONDecoder().decode([String: Int].self, from: holdingsData) {
            holdings = savedHoldings
        }
        
        // Load trades
        if let tradesData = UserDefaults.standard.data(forKey: tradesKey),
           let savedTrades = try? JSONDecoder().decode([PortfolioTrade].self, from: tradesData) {
            trades = savedTrades
        }
    }
    
    /// Reset portfolio data (for testing purposes)
    func resetPortfolio() {
        balance = 100000.0
        holdings = [:]
        trades = []
        saveToUserDefaults()
    }
}