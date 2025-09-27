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
    private var patternRecognitionEngine: PatternRecognitionEngine?
    private let aiAgentTrader = AIAgentTrader()
    private var timer: Timer?
    
    // UserDefaults keys
    private let suggestionHistoryKey = "TradeSuggestionManager.suggestionHistory"
    private let aiTradingModeKey = "TradeSuggestionManager.aiTradingMode"
    private let autoTradeEnabledKey = "TradeSuggestionManager.autoTradeEnabled"
    
    private var connectionObserver: NSObjectProtocol?
    private var webSocketObserver: NSObjectProtocol?
    
    private init() {
        // Load saved data
        loadFromUserDefaults()

        // Initialize PatternRecognitionEngine asynchronously
        Task { @MainActor in
            self.patternRecognitionEngine = PatternRecognitionEngine()
        }

        // Set up observers for connection status changes
        connectionObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DataConnectionStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleConnectionStatusChanged()
        }

        webSocketObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WebSocketStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleConnectionStatusChanged()
        }

        // Start the suggestion generation process if we have real-time data
        handleConnectionStatusChanged()
    }
    
    deinit {
        if let observer = connectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = webSocketObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func handleConnectionStatusChanged() {
        // Stop any existing timer
        stopSuggestionGeneration()
        
        // Get references to the shared instances from ContentView
        // We need to find a way to access the shared instances
        DispatchQueue.main.async {
            // Use NotificationCenter to request the current connection status
            NotificationCenter.default.post(name: NSNotification.Name("RequestConnectionStatus"), object: nil)
        }
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
    
    // Properties to track connection status
    private var isDataAvailable = false
    private var isWebSocketConnected = false
    
    // Method to update connection status
    func updateConnectionStatus(dataAvailable: Bool, webSocketConnected: Bool) {
        isDataAvailable = dataAvailable
        isWebSocketConnected = webSocketConnected
        
        // If both are available, start generating suggestions
        if isDataAvailable && isWebSocketConnected {
            startSuggestionGeneration()
        } else {
            stopSuggestionGeneration()
        }
    }
    
    func startSuggestionGeneration() {
        // Only start if not already running
        if timer == nil {
            print("Starting trade suggestion generation with real-time data")
            // Generate suggestions every 60 seconds based on live market data
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.generateSuggestion()
            }
        }
    }
    
    func stopSuggestionGeneration() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateSuggestion() {
        // Check if we have real-time data available using stored status
        guard isDataAvailable else {
            print("Trade suggestions disabled: No real-time data available")
            return
        }

        // Check if WebSocket is connected using stored status
        guard isWebSocketConnected else {
            print("Trade suggestions disabled: WebSocket not connected")
            return
        }

        // Generate intelligent suggestion based on pattern analysis
        generateIntelligentSuggestion()
    }

    /// Generate intelligent trade suggestions based on pattern analysis and ML insights
    private func generateIntelligentSuggestion() {
        guard let patternRecognitionEngine = patternRecognitionEngine else {
            print("PatternRecognitionEngine not initialized yet")
            return
        }

        let symbols = ["NIFTY", "BANKNIFTY", "RELIANCE", "TCS", "INFY"]

        // Analyze each symbol and find the best trading opportunity
        var highestConfidence = 0.0

        for symbol in symbols {
            fetchRealMarketPrice(for: symbol) { [weak self] realPrice in
                guard let self = self else { return }

                guard let price = realPrice, price > 0 else {
                    print("Skipping \(symbol): No real price available")
                    return
                }

                // Create market data for pattern analysis
                let marketData = [MarketData(symbol: symbol, price: price, volume: 100000, timestamp: Date())]

                // Run pattern analysis on main actor - use async/await pattern
                Task {
                    await MainActor.run {
                        // Get pattern analysis results
                        let patternResults = patternRecognitionEngine.analyzeComprehensivePatterns(marketData: marketData)

                        // Find the strongest pattern across all timeframes
                        var strongestPattern: PatternRecognitionEngine.PatternResult?
                        var maxStrength = 0.0

                        for (_, patterns) in patternResults {
                            for pattern in patterns {
                                let strength = pattern.confidence * pattern.successRate
                                if strength > maxStrength {
                                    maxStrength = strength
                                    strongestPattern = pattern
                                }
                            }
                        }

                        guard let pattern = strongestPattern else {
                            print("No strong patterns found for \(symbol)")
                            return
                        }

                        // Get ML-based insights for this pattern
                        let insights = patternRecognitionEngine.getPatternInsights(pattern: pattern.pattern, marketData: marketData)

                        // Calculate final confidence combining pattern strength and ML insights
                        let finalConfidence = min(1.0, (pattern.confidence + insights.mlConfidence) / 2.0)

                        // Only consider suggestions with high confidence
                        guard finalConfidence >= 0.75 else {
                            print("Pattern confidence too low for \(symbol): \(finalConfidence)")
                            return
                        }

                        // Determine action based on pattern signal and market regime
                        let action: TradeAction
                        switch pattern.signal {
                        case .buy, .strongBuy:
                            action = .buy
                        case .sell, .strongSell:
                            action = .sell
                        default:
                            action = insights.recommendedAction.contains("Buy") ? .buy : .sell
                        }

                        // Calculate quantity based on confidence and risk level
                        let baseQuantity = 1
                        let confidenceMultiplier = Int(finalConfidence * 5) // 1-5 based on confidence
                        let quantity = baseQuantity * confidenceMultiplier

                        // Generate rationale based on pattern and ML insights
                        let rationale = self.generateIntelligentRationale(
                            pattern: pattern,
                            insights: insights,
                            symbol: symbol,
                            confidence: finalConfidence
                        )

                        let suggestion = TradeSuggestion(
                            symbol: symbol,
                            action: action,
                            price: price,
                            quantity: quantity,
                            confidence: finalConfidence,
                            rationale: rationale,
                            timestamp: Date()
                        )

                        // Process the suggestion if it has the highest confidence so far
                        if finalConfidence > highestConfidence {
                            highestConfidence = finalConfidence
                            // Process the best suggestion
                            self.processSuggestion(suggestion)
                        }
                    }
                }
            }
        }
    }

    /// Generate intelligent rationale based on pattern analysis and ML insights
    private func generateIntelligentRationale(
        pattern: PatternRecognitionEngine.PatternResult,
        insights: PatternRecognitionEngine.PatternInsights,
        symbol: String,
        confidence: Double
    ) -> String {
        var rationale = "\(pattern.pattern) pattern detected on \(symbol) with \(Int(confidence * 100))% confidence. "

        // Add market regime context
        switch insights.marketRegime {
        case .trending:
            rationale += "Market is in trending regime, supporting directional momentum. "
        case .ranging:
            rationale += "Market is ranging, focusing on mean reversion opportunities. "
        case .volatile:
            rationale += "Market is volatile, requiring careful position sizing. "
        case .quiet:
            rationale += "Market is quiet, looking for breakout opportunities. "
        case .breakout:
            rationale += "Market is breaking out, supporting momentum trades. "
        case .reversal:
            rationale += "Market is reversing, supporting contrarian positions. "
        }

        // Add ML insights
        rationale += insights.recommendedAction

        // Add risk assessment
        rationale += " Risk level: \(insights.riskLevel)."

        // Add pattern-specific details
        if pattern.targets.count > 0 {
            rationale += " Target: ₹\(String(format: "%.2f", pattern.targets[0]))"
        }

        if let stopLoss = pattern.stopLoss, stopLoss > 0 {
            rationale += ", Stop Loss: ₹\(String(format: "%.2f", stopLoss))"
        }

        return rationale
    }

    /// Process and handle the generated suggestion
    private func processSuggestion(_ suggestion: TradeSuggestion) {
        // Add to current suggestions and history
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
    
    private func getFallbackPrice(for symbol: String) -> Double? {
        // We no longer use fallback prices - return nil to indicate no data
        print("Error: No real-time price available for \(symbol)")
        return nil
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
    
    // Generate a suggestion based on real market data
    func generateTestSuggestion() {
        generateSuggestion()
    }
}