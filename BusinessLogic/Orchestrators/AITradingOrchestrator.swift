import UIKit
import Foundation
import SwiftUI
import Combine


// MARK: - AI Trading Orchestrator
@MainActor
class AITradingOrchestrator: ObservableObject {
    // MARK: - Published Properties
    @Published var isAutoTradingEnabled: Bool = false
    @Published var currentPositions: [OptionsPosition] = []
    @Published var dailyPnL: Double = 0.0
    @Published var riskMetrics: RiskMetrics = RiskMetrics()
    @Published var tradingStatus: TradingStatus = .stopped
    @Published var lastSignal: IntradayTradingSignal?
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var isInitialized: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let dataProvider = NIFTYOptionsDataProvider()
    private let patternEngine = IntradayPatternEngine()
    private let riskManager = AdvancedRiskManager()
    private let orderExecutor = OptionsOrderExecutor()
    private let trainingManager = HistoricalTrainingManager()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var tradingTimer: Timer?
    private var riskMonitoringTimer: Timer?
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
        initializeSystem()
    }
    
    deinit {
        // stopAutoTrading()
    }
    
    // MARK: - Public Methods
    func startAutoTrading() async {
        guard !isAutoTradingEnabled else { return }
        
        do {
            // Initialize all components
            try await initializeComponents()
            
            // Start real-time data streams
            dataProvider.startRealTimeDataStream()
            
            // Begin pattern recognition
            // await patternEngine.startRealTimeAnalysis()
            
            // Start trading loop
            startTradingLoop()
            
            // Start risk monitoring
            startRiskMonitoring()
            
            isAutoTradingEnabled = true
            tradingStatus = .running
            errorMessage = nil
            
            print("✅ AI Auto Trading Started Successfully")
            
        } catch {
            errorMessage = "Failed to start auto trading: \(error.localizedDescription)"
            print("❌ Failed to start auto trading: \(error)")
        }
    }
    
    func stopAutoTrading() {
        guard isAutoTradingEnabled else { return }
        
        // Stop timers
        tradingTimer?.invalidate()
        riskMonitoringTimer?.invalidate()
        
        // Stop data streams
        dataProvider.stopRealTimeDataStream()
        // await patternEngine.stopRealTimeAnalysis()
        
        isAutoTradingEnabled = false
        tradingStatus = .stopped
        
        print("🛑 AI Auto Trading Stopped")
    }
    
    func pauseAutoTrading() {
        guard isAutoTradingEnabled else { return }
        
        tradingTimer?.invalidate()
        tradingStatus = .paused
        
        print("⏸️ AI Auto Trading Paused")
    }
    
    func resumeAutoTrading() {
        guard isAutoTradingEnabled && tradingStatus == .paused else { return }
        
        startTradingLoop()
        tradingStatus = .running
        
        print("▶️ AI Auto Trading Resumed")
    }
    
    func emergencyStop(reason: String) async {
        print("🚨 EMERGENCY STOP: \(reason)")
        
        // Close all positions immediately
        await closeAllPositions(reason: "Emergency Stop: \(reason)")
        
        // Stop auto trading
        stopAutoTrading()
        
        // Update status
        tradingStatus = .emergencyStopped
        errorMessage = "Emergency Stop: \(reason)"
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Subscribe to pattern engine signals
        patternEngine.$detectedPatterns
            .sink { [weak self] patterns in
                Task { @MainActor in
                    await self?.processPatternSignals(patterns)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to risk manager alerts
        // riskManager.$riskAlerts
        //     .sink { [weak self] alerts in
        //         Task { @MainActor in
        //             await self?.handleRiskAlerts(alerts)
        //         }
        //     }
        //     .store(in: &cancellables)
        
        // Subscribe to position updates
        orderExecutor.$positions
            .assign(to: \.currentPositions, on: self)
            .store(in: &cancellables)
    }
    
    private func initializeSystem() {
        Task {
            do {
                // Initialize data provider
                try await dataProvider.initialize()
                
                // Initialize pattern engine
                try await patternEngine.initialize()
                
                // Initialize risk manager
                try await riskManager.initialize()
                
                // Initialize order executor
                try await orderExecutor.initialize()
                
                isInitialized = true
                print("✅ AI Trading System Initialized")
                
            } catch {
                errorMessage = "System initialization failed: \(error.localizedDescription)"
                print("❌ System initialization failed: \(error)")
            }
        }
    }
    
    private func initializeComponents() async throws {
        // Ensure all components are ready
        guard isInitialized else {
            throw TradingError.systemNotInitialized
        }
        
        // Load trained models
        // try await trainingManager.loadTrainedModels()
        
        // Validate market hours
        guard isMarketOpen() else {
            throw TradingError.marketClosed
        }
        
        // Check risk limits
        // try await riskManager.validateSystemRisk()
    }
    
    private func startTradingLoop() {
        tradingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.executeTradingCycle()
            }
        }
    }
    
    private func startRiskMonitoring() {
        riskMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.monitorRisk()
            }
        }
    }
    
    private func executeTradingCycle() async {
        guard isAutoTradingEnabled && tradingStatus == .running else { return }
        
        do {
            // Get latest market data
            let optionsChain = dataProvider.currentOptionsChain
            
            // Analyze patterns
            // let patterns = await patternEngine.analyzeCurrentMarket(optionsChain)
            let patterns: [IntradayPattern] = []
            
            // Generate trading signals
            let signals = generateTradingSignals(from: patterns, optionsChain: optionsChain)
            
            // Execute trades based on signals
            for signal in signals {
                await executeTradeSignal(signal)
            }
            
            // Update performance metrics
            await updatePerformanceMetrics()
            
        } catch {
            print("❌ Trading cycle error: \(error)")
            errorMessage = "Trading cycle error: \(error.localizedDescription)"
        }
    }
    
    private func generateTradingSignals(from patterns: [IntradayPattern], optionsChain: NIFTYOptionsChain?) -> [IntradayTradingSignal] {
        guard let optionsChain = optionsChain else { return [] }
        
        var signals: [IntradayTradingSignal] = []
        
        for pattern in patterns {
            // Only process high-confidence patterns
            guard pattern.confidence > 0.7 else { continue }
            
            // Generate signal based on pattern type
            if let signal = createSignalFromPattern(pattern, optionsChain: optionsChain) {
                signals.append(signal)
            }
        }
        
        return signals
    }
    
    private func createSignalFromPattern(_ pattern: IntradayPattern, optionsChain: NIFTYOptionsChain) -> IntradayTradingSignal? {
        let atmStrike = optionsChain.getATMStrike()
        
        switch pattern.direction {
        case .bullish:
            let callOption = optionsChain.callOptions.first { $0.strikePrice == atmStrike }
            guard let contract = callOption else { return nil }
            
            return IntradayTradingSignal(
                contract: contract,
                signalType: .breakoutBuy,
                confidence: pattern.confidence,
                entryPrice: contract.currentPrice,
                targetPrice: optionsChain.underlyingPrice * 1.02,
                stopLoss: optionsChain.underlyingPrice * 0.98,
                timeframe: pattern.timeframe,
                patterns: [pattern.type.rawValue],
                technicalIndicators: [:],
                timestamp: Date(),
                expiryTime: Date().addingTimeInterval(3600)
            )
            
        case .bearish:
            let putOption = optionsChain.putOptions.first { $0.strikePrice == atmStrike }
            guard let contract = putOption else { return nil }
            
            return IntradayTradingSignal(
                contract: contract,
                signalType: .breakdownSell,
                confidence: pattern.confidence,
                entryPrice: contract.currentPrice,
                targetPrice: optionsChain.underlyingPrice * 0.98,
                stopLoss: optionsChain.underlyingPrice * 1.02,
                timeframe: pattern.timeframe,
                patterns: [pattern.type.rawValue],
                technicalIndicators: [:],
                timestamp: Date(),
                expiryTime: Date().addingTimeInterval(3600)
            )
            
        default:
            return nil
        }
    }
    
    private func executeTradeSignal(_ signal: IntradayTradingSignal) async {
        do {
            // Validate signal with risk manager
            // guard await riskManager.validateTradeSignal(signal) else {
            //     print("⚠️ Signal rejected by risk manager: \(signal.symbol)")
            //     return
            // }
            
            // Calculate position size
            // let positionSize = await riskManager.calculatePositionSize(for: signal)
            let positionSize = 1
            
            // Create order
            let order = OptionsOrder(
                symbol: signal.symbol,
                action: signal.action,
                quantity: positionSize,
                orderType: .market,
                price: signal.entryPrice,
                strikePrice: signal.strikePrice,
                expiryDate: signal.expiryDate,
                optionType: signal.optionType
            )
            
            // Execute order
            let result = try await orderExecutor.executeOrder(order)
            
            if result.isSuccessful {
                lastSignal = signal
                print("✅ Trade executed: \(signal.symbol) - \(signal.action)")
            } else {
                print("❌ Trade execution failed: \(result.errorMessage ?? "Unknown error")")
            }
            
        } catch {
            print("❌ Error executing trade signal: \(error)")
        }
    }
    
    private func processPatternSignals(_ patterns: [IntradayPattern]) async {
        // Process high-confidence patterns for immediate action
        let highConfidencePatterns = patterns.filter { $0.confidence > 0.8 }
        
        for pattern in highConfidencePatterns {
            print("🎯 High confidence pattern detected: \(pattern.type.rawValue) - \(pattern.confidence)")
        }
    }
    
    private func handleRiskAlerts(_ alerts: [RiskAlert]) async {
        for alert in alerts {
            switch alert.severity {
            case .critical:
                await emergencyStop(reason: alert.message)
            case .high:
                pauseAutoTrading()
                print("⚠️ High risk alert: \(alert.message)")
            case .medium:
                print("⚠️ Medium risk alert: \(alert.message)")
            case .low:
                print("ℹ️ Low risk alert: \(alert.message)")
            }
        }
    }
    
    private func monitorRisk() async {
        // do {
        //     // Update risk metrics
        //     riskMetrics = await riskManager.calculateCurrentRisk(positions: currentPositions)
        //     
        //     // Check for risk violations
        //     await riskManager.checkRiskLimits(positions: currentPositions)
        //     
        // } catch {
        //     print("❌ Risk monitoring error: \(error)")
        // }
    }
    
    private func updatePerformanceMetrics() async {
        // Calculate daily P&L
        dailyPnL = currentPositions.reduce(0) { $0 + $1.unrealizedPnL }
        
        // Update performance metrics
        performanceMetrics = PerformanceMetrics(
            winRate: currentPositions.isEmpty ? 0 : Double(currentPositions.filter { $0.unrealizedPnL > 0 }.count) / Double(currentPositions.count),
            profitFactor: calculateProfitFactor(),
            totalTrades: currentPositions.count,
            periodReturn: dailyPnL
        )
    }
    
    private func closeAllPositions(reason: String) async {
        for position in currentPositions {
            do {
                let closeOrder = OptionsOrder(
                    symbol: position.symbol,
                    action: position.quantity > 0 ? .sell : .buy,
                    quantity: abs(position.quantity),
                    orderType: .market,
                    price: position.currentPrice, // Use current market price for closing
                    strikePrice: position.strikePrice,
                    expiryDate: position.expiryDate,
                    optionType: position.optionType
                )
                
                _ = try await orderExecutor.executeOrder(closeOrder)
                print("✅ Closed position: \(position.symbol)")
                
            } catch {
                print("❌ Failed to close position \(position.symbol): \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isMarketOpen() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if it's a weekday
        let weekday = calendar.component(.weekday, from: now)
        guard weekday >= 2 && weekday <= 6 else { return false } // Monday to Friday
        
        // Check market hours (9:15 AM to 3:30 PM IST)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        let marketStart = 9 * 60 + 15 // 9:15 AM in minutes
        let marketEnd = 15 * 60 + 30 // 3:30 PM in minutes
        let currentTime = hour * 60 + minute
        
        return currentTime >= marketStart && currentTime <= marketEnd
    }
    
    private func formatExpiryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMMyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func calculateAverageWin() -> Double {
        let winningPositions = currentPositions.filter { $0.unrealizedPnL > 0 }
        guard !winningPositions.isEmpty else { return 0 }
        return winningPositions.reduce(0) { $0 + $1.unrealizedPnL } / Double(winningPositions.count)
    }
    
    private func calculateAverageLoss() -> Double {
        let losingPositions = currentPositions.filter { $0.unrealizedPnL < 0 }
        guard !losingPositions.isEmpty else { return 0 }
        return abs(losingPositions.reduce(0) { $0 + $1.unrealizedPnL } / Double(losingPositions.count))
    }
    
    private func calculateProfitFactor() -> Double {
        let totalWins = currentPositions.filter { $0.unrealizedPnL > 0 }.reduce(0) { $0 + $1.unrealizedPnL }
        let totalLosses = abs(currentPositions.filter { $0.unrealizedPnL < 0 }.reduce(0) { $0 + $1.unrealizedPnL })
        
        guard totalLosses > 0 else { return totalWins > 0 ? Double.infinity : 0 }
        return totalWins / totalLosses
    }
}

// RiskAlert is defined in RiskManagementDashboard.swift
