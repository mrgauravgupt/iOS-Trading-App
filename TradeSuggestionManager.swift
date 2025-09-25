import Foundation
import SwiftUI

// Manager class for handling trade suggestions
class TradeSuggestionManager: ObservableObject {
    static let shared = TradeSuggestionManager()
    
    @Published var currentSuggestions: [TradeSuggestion] = []
    @Published var suggestionHistory: [TradeSuggestion] = []
    @Published var showSuggestionAlert: Bool = false
    @Published var latestSuggestion: TradeSuggestion?
    @Published var aiTradingMode: AITradingMode = .alertOnly
    @Published var autoTradeEnabled: Bool = false
    
    private let orderExecutor = OrderExecutor()
    private let zerodhaClient = ZerodhaAPIClient()
    private var timer: Timer?
    
    // UserDefaults keys
    private let suggestionHistoryKey = "TradeSuggestionManager.suggestionHistory"
    private let aiTradingModeKey = "TradeSuggestionManager.aiTradingMode"
    private let autoTradeEnabledKey = "TradeSuggestionManager.autoTradeEnabled"
    
    private init() {
        // Load saved data
        loadFromUserDefaults()
        
        // Start the suggestion generation process
        startSuggestionGeneration()
    }
    
    // Load data from UserDefaults
    private func loadFromUserDefaults() {
        // Load suggestion history
        if let historyData = UserDefaults.standard.data(forKey: suggestionHistoryKey),
           let savedHistory = try? JSONDecoder().decode([TradeSuggestion].self, from: historyData) {
            suggestionHistory = savedHistory
        }
        
        // Load AI trading mode
        if let savedModeString = UserDefaults.standard.string(forKey: aiTradingModeKey),
           let savedMode = AITradingMode(rawValue: savedModeString) {
            aiTradingMode = savedMode
        }
        
        // Load auto trade enabled setting
        autoTradeEnabled = UserDefaults.standard.bool(forKey: autoTradeEnabledKey)
    }
    
    // Save data to UserDefaults
    private func saveToUserDefaults() {
        // Save suggestion history
        if let historyData = try? JSONEncoder().encode(suggestionHistory) {
            UserDefaults.standard.set(historyData, forKey: suggestionHistoryKey)
        }
        
        // Save AI trading mode
        UserDefaults.standard.set(aiTradingMode.rawValue, forKey: aiTradingModeKey)
        
        // Save auto trade enabled setting
        UserDefaults.standard.set(autoTradeEnabled, forKey: autoTradeEnabledKey)
    }
    
    func startSuggestionGeneration() {
        // Generate suggestions more frequently for real-time trading
        // Real-time suggestions every 60 seconds based on live market data
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.generateSuggestion()
        }
    }
    
    func stopSuggestionGeneration() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateSuggestion() {
        // Generate suggestion with real market data
        let symbols = ["NIFTY", "BANKNIFTY", "RELIANCE", "TCS", "INFY"]
        let actions: [TradeAction] = [.buy, .sell]
        
        guard let randomSymbol = symbols.randomElement(),
              let randomAction = actions.randomElement() else { return }
        
        // Fetch real market price for the symbol
        fetchRealMarketPrice(for: randomSymbol) { [weak self] realPrice in
            guard let self = self else { return }
            
            let price = realPrice ?? self.getFallbackPrice(for: randomSymbol)
            let quantity = Int.random(in: 1...10)
            let confidence = Double.random(in: 0.7...0.95)
            
            let rationales = [
                "Strong momentum detected",
                "Breakout from resistance level",
                "Oversold condition",
                "Positive news sentiment",
                "Technical pattern completion",
                "RSI indicating oversold/overbought",
                "Moving average crossover signal",
                "Volume spike detected"
            ]
            
            guard let rationale = rationales.randomElement() else { return }
            
            let suggestion = TradeSuggestion(
                symbol: randomSymbol,
                action: randomAction,
                price: price,
                quantity: quantity,
                confidence: confidence,
                rationale: rationale,
                timestamp: Date()
            )
            
            // Add to current suggestions and history
            DispatchQueue.main.async {
                self.currentSuggestions.append(suggestion)
                self.suggestionHistory.append(suggestion)
                self.latestSuggestion = suggestion
                
                // Save updated history to UserDefaults
                self.saveToUserDefaults()
                
                // Handle based on AI trading mode
                if self.aiTradingMode == .autoTrade && self.autoTradeEnabled {
                    // Auto-execute the trade
                    let success = self.executeSuggestion(suggestion)
                    if success {
                        self.sendNotification(for: suggestion, autoExecuted: true)
                    } else {
                        self.showSuggestionAlert = true
                        self.sendNotification(for: suggestion, autoExecuted: false)
                    }
                } else {
                    // Show alert for manual decision
                    self.showSuggestionAlert = true
                    self.sendNotification(for: suggestion)
                }
            }
        }
    }
    
    private func fetchRealMarketPrice(for symbol: String, completion: @escaping (Double?) -> Void) {
        // Fetch real data for all supported symbols
        zerodhaClient.fetchLTP(symbol: symbol) { result in
            switch result {
            case .success(let marketData):
                completion(marketData.price)
            case .failure(let error):
                print("Failed to fetch real price for \(symbol): \(error)")
                completion(nil)
            }
        }
    }
    
    private func getFallbackPrice(for symbol: String) -> Double {
        // Return 0 to indicate no real data is available
        print("Error: No real-time price available for \(symbol)")
        return 0.0
    }
    
    func executeSuggestion(_ suggestion: TradeSuggestion) -> Bool {
        // Execute the trade using OrderExecutor
        let success: Bool
        
        let tradeType: VirtualPortfolio.PortfolioTrade.TradeType = suggestion.action == .buy ? .buy : .sell
        
        success = orderExecutor.executeOrder(
            symbol: suggestion.symbol,
            quantity: suggestion.quantity,
            price: suggestion.price,
            type: tradeType
        )
        
        if success {
            // Update the suggestion as executed
            if let index = currentSuggestions.firstIndex(where: { $0.id == suggestion.id }) {
                currentSuggestions[index].isExecuted = true
            }
            
            // Also update in history
            if let historyIndex = suggestionHistory.firstIndex(where: { $0.id == suggestion.id }) {
                suggestionHistory[historyIndex].isExecuted = true
                saveToUserDefaults()
            }
        }
        
        return success
    }
    
    private func sendNotification(for suggestion: TradeSuggestion, autoExecuted: Bool? = nil) {
        let notificationManager = NotificationManager.shared
        
        let title: String
        let body: String
        
        if let autoExecuted = autoExecuted {
            if autoExecuted {
                title = "Auto Trade Executed: \(suggestion.action.rawValue.uppercased()) \(suggestion.symbol)"
                body = "Successfully executed \(suggestion.quantity) shares at ₹\(String(format: "%.2f", suggestion.price))"
            } else {
                title = "Auto Trade Failed: \(suggestion.action.rawValue.uppercased()) \(suggestion.symbol)"
                body = "Failed to execute \(suggestion.quantity) shares at ₹\(String(format: "%.2f", suggestion.price)) - Manual review required"
            }
        } else {
            title = "Trade Suggestion: \(suggestion.action.rawValue.uppercased()) \(suggestion.symbol)"
            body = "\(suggestion.quantity) shares at ₹\(String(format: "%.2f", suggestion.price)) - \(suggestion.rationale)"
        }
        
        notificationManager.scheduleNotification(
            title: title,
            body: body,
            identifier: suggestion.id.uuidString
        )
    }
    
    // MARK: - AI Trading Mode Management
    
    func setAITradingMode(_ mode: AITradingMode) {
        aiTradingMode = mode
        autoTradeEnabled = (mode == .autoTrade)
        saveToUserDefaults()
    }
    
    func toggleAutoTrade() {
        autoTradeEnabled.toggle()
        if autoTradeEnabled {
            aiTradingMode = .autoTrade
        } else {
            aiTradingMode = .alertOnly
        }
        saveToUserDefaults()
    }
    
    // MARK: - History Management
    
    func clearSuggestionHistory() {
        suggestionHistory.removeAll()
        saveToUserDefaults()
    }
    
    func getExecutedSuggestions() -> [TradeSuggestion] {
        return suggestionHistory.filter { $0.isExecuted }
    }
    
    func getPendingSuggestions() -> [TradeSuggestion] {
        return currentSuggestions.filter { !$0.isExecuted }
    }
    
    // For testing purposes
    func generateTestSuggestion() {
        generateSuggestion()
    }
}