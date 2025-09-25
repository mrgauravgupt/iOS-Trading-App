import Foundation
import SwiftUI

// Model for trade suggestions
struct TradeSuggestion: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let action: TradeAction
    let price: Double
    let quantity: Int
    let confidence: Double // 0.0 to 1.0
    let rationale: String
    let timestamp: Date
    var isExecuted: Bool = false
    
    enum TradeAction: String, Codable {
        case buy, sell
    }
}

// Manager class for handling trade suggestions
class TradeSuggestionManager: ObservableObject {
    static let shared = TradeSuggestionManager()
    
    @Published var currentSuggestions: [TradeSuggestion] = []
    @Published var showSuggestionAlert: Bool = false
    @Published var latestSuggestion: TradeSuggestion?
    
    private let orderExecutor = OrderExecutor()
    private var timer: Timer?
    
    private init() {
        // Start the suggestion generation process
        startSuggestionGeneration()
    }
    
    func startSuggestionGeneration() {
        // In a real app, this would connect to a backend service or AI model
        // For demo purposes, we'll use a timer to simulate new suggestions
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.generateSuggestion()
        }
    }
    
    func stopSuggestionGeneration() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateSuggestion() {
        // This would normally come from an AI model or backend service
        // For demo purposes, we're creating a random suggestion
        let symbols = ["NIFTY", "BANKNIFTY", "RELIANCE", "TCS", "INFY"]
        let actions: [TradeSuggestion.TradeAction] = [.buy, .sell]
        
        guard let randomSymbol = symbols.randomElement(),
              let randomAction = actions.randomElement() else { return }
        
        let basePrice = randomSymbol == "NIFTY" ? 22000.0 : (randomSymbol == "BANKNIFTY" ? 48000.0 : 2000.0)
        let priceVariation = Double.random(in: -100...100)
        let price = basePrice + priceVariation
        let quantity = Int.random(in: 1...10)
        let confidence = Double.random(in: 0.7...0.95)
        
        let rationales = [
            "Strong momentum detected",
            "Breakout from resistance level",
            "Oversold condition",
            "Positive news sentiment",
            "Technical pattern completion"
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
        
        // Add to current suggestions and trigger notification
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentSuggestions.append(suggestion)
            self.latestSuggestion = suggestion
            self.showSuggestionAlert = true
            
            // Also send a notification
            self.sendNotification(for: suggestion)
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
    
    private func sendNotification(for suggestion: TradeSuggestion) {
        let notificationManager = NotificationManager.shared
        
        let title = "Trade Suggestion: \(suggestion.action.rawValue.uppercased()) \(suggestion.symbol)"
        let body = "\(suggestion.quantity) shares at \(String(format: "%.2f", suggestion.price)) - \(suggestion.rationale)"
        
        notificationManager.scheduleNotification(
            title: title,
            body: body,
            identifier: suggestion.id.uuidString
        )
    }
    
    // For testing purposes
    func generateTestSuggestion() {
        generateSuggestion()
    }
}