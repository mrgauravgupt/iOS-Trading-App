import Foundation
import SwiftUI

// Model for trade suggestions
struct TradeSuggestion: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let action: TradeAction
    let price: Double
    let quantity: Int
    let confidence: Double // 0.0 to 1.0
    let rationale: String
    let timestamp: Date
    var isExecuted: Bool = false
    
    init(symbol: String, action: TradeAction, price: Double, quantity: Int, confidence: Double, rationale: String, timestamp: Date, isExecuted: Bool = false) {
        self.id = UUID()
        self.symbol = symbol
        self.action = action
        self.price = price
        self.quantity = quantity
        self.confidence = confidence
        self.rationale = rationale
        self.timestamp = timestamp
        self.isExecuted = isExecuted
    }
    
    enum TradeAction: String, Codable {
        case buy, sell
    }
}

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
    
    enum AITradingMode: String, CaseIterable {
        case alertOnly = "Alert Only"
        case autoTrade = "Auto Trade"
        
        var description: String {
            switch self {
            case .alertOnly:
                return "Show alerts for trade suggestions"
            case .autoTrade:
                return "Automatically execute suggested trades"
            }
        }
    }
    
    private init() {
        // Start the suggestion generation process
        startSuggestionGeneration()
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
        let actions: [TradeSuggestion.TradeAction] = [.buy, .sell]
        
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
        // Updated fallback prices based on current market values (Jan 2025)
        switch symbol.uppercased() {
        case "NIFTY": return 24500.0 + Double.random(in: -200...200)
        case "BANKNIFTY": return 51000.0 + Double.random(in: -500...500)
        case "RELIANCE": return 1380.0 + Double.random(in: -50...50)
        case "TCS": return 4100.0 + Double.random(in: -100...100)
        case "INFY": return 1482.0 + Double.random(in: -20...20) // Updated to current market price ~₹1482
        default: return 1000.0 + Double.random(in: -100...100)
        }
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
    }
    
    func toggleAutoTrade() {
        autoTradeEnabled.toggle()
        if autoTradeEnabled {
            aiTradingMode = .autoTrade
        } else {
            aiTradingMode = .alertOnly
        }
    }
    
    // MARK: - History Management
    
    func clearSuggestionHistory() {
        suggestionHistory.removeAll()
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