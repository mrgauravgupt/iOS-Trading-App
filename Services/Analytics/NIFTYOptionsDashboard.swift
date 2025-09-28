import SwiftUI
import Charts
import Combine
import SharedCoreModels

// MARK: - NIFTY Options Dashboard
struct NIFTYOptionsDashboard: View {
    @StateObject private var dataProvider = NIFTYOptionsDataProvider()
    @StateObject private var aiOrchestrator = AITradingOrchestrator()
    @StateObject private var patternEngine = IntradayPatternEngine()
    
    @State private var selectedTimeframe: Timeframe = .fiveMinute
    @State private var showingSettings = false
    
    private var availableExpiries: [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        for i in 0..<4 {
            if let date = calendar.date(byAdding: .weekOfYear, value: i, to: today) {
                // Normalize the date to remove time components
                if let normalizedDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) {
                    dates.append(normalizedDate)
                }
            }
        }
        return dates
    }
    
    // Initialize selectedExpiry after availableExpiries is defined
    @State private var selectedExpiry: Date = {
        let calendar = Calendar.current
        let today = Date()
        // Use the first available expiry date (current week)
        if let date = calendar.date(byAdding: .weekOfYear, value: 0, to: today),
           let normalizedDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) {
            return normalizedDate
        }
        return today
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Market Overview Card
                    MarketOverviewCard()
                    
                    // AI Trading Status Card
                    AITradingStatusCard()
                    
                    // Options Chain Heatmap
                    OptionsChainHeatmap()
                    
                    // Active Positions Card
                    ActivePositionsCard()
                    
                    // Pattern Alerts Card
                    PatternAlertsCard()
                    
                    // Risk Metrics Card
                    RiskMetricsCard()
                    
                    // Performance Analytics Card
                    PerformanceAnalyticsCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("NIFTY Options AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NIFTY Options AI")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            startRealTimeUpdates()
        }
        .onDisappear {
            stopRealTimeUpdates()
        }
        .sheet(isPresented: $showingSettings) {
            NIFTYOptionsSettingsView()
        }
    }
    
    // MARK: - Market Overview Card
    @ViewBuilder
    private func MarketOverviewCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Market Overview")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(dataProvider.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(dataProvider.isConnected ? "LIVE" : "OFFLINE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(dataProvider.isConnected ? .green : .red)
                }
            }
            
            if let currentData = dataProvider.realTimeData {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NIFTY 50")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "₹%.2f", currentData.niftySpotPrice))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                            Text("+0.00")
                                .font(.caption)
                            Text("(+0.00%)")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("VIX")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", currentData.vix))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("IV: 0.0%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading market data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - AI Trading Status Card
    @ViewBuilder
    private func AITradingStatusCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Trading Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                Button(action: {
                    Task {
                        if aiOrchestrator.isAutoTradingEnabled {
                            aiOrchestrator.stopAutoTrading()
                        } else {
                            await aiOrchestrator.startAutoTrading()
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: aiOrchestrator.isAutoTradingEnabled ? "stop.fill" : "play.fill")
                            .font(.caption)
                        Text(aiOrchestrator.isAutoTradingEnabled ? "Stop" : "Start")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(aiOrchestrator.isAutoTradingEnabled ? .red : .green)
                    .cornerRadius(8)
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor(for: aiOrchestrator.tradingStatus))
                            .frame(width: 8, height: 8)
                        Text(statusText(for: aiOrchestrator.tradingStatus))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily P&L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "₹%.2f", aiOrchestrator.dailyPnL))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(aiOrchestrator.dailyPnL >= 0 ? .green : .red)
                }
            }
            
            if let lastSignal = aiOrchestrator.lastSignal {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(lastSignal.action.rawValue.uppercased()) \(lastSignal.symbol)")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(String(format: "Confidence: %.0f%%", lastSignal.confidence * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(lastSignal.patterns.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Options Chain Heatmap
    @ViewBuilder
    private func OptionsChainHeatmap() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Options Chain")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Expiry", selection: Binding(
                    get: { self.selectedExpiry },
                    set: { self.selectedExpiry = self.ensureValidExpiryDate($0) }
                )) {
                    ForEach(availableExpiries, id: \.self) { expiry in
                        Text(formatExpiryDate(expiry))
                            .tag(expiry)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(.caption)
            }
            
            if let optionsChain = dataProvider.currentOptionsChain {
                OptionsChainView(optionsChain: optionsChain)
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading options chain...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Active Positions Card
    @ViewBuilder
    private func ActivePositionsCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Active Positions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(aiOrchestrator.currentPositions.count) positions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if aiOrchestrator.currentPositions.isEmpty {
                Text("No active positions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 60)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(aiOrchestrator.currentPositions, id: \.id) { position in
                        PositionRowView(position: position)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Pattern Alerts Card
    @ViewBuilder
    private func PatternAlertsCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Pattern Alerts")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName)
                        .tag(timeframe)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(.caption)
            }
            
            let recentPatterns = patternEngine.detectedPatterns
                .filter { $0.timeframe.rawValue == selectedTimeframe.rawValue }
                .prefix(3)
            
            if recentPatterns.isEmpty {
                Text("No recent patterns detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 60)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(recentPatterns)) { pattern in
                        PatternAlertRowView(pattern: pattern)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Risk Metrics Card
    @ViewBuilder
    private func RiskMetricsCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Risk Metrics")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                RiskMetricView(
                    title: "Portfolio Value",
                    value: String(format: "₹%.0f", aiOrchestrator.riskMetrics.portfolioValue),
                    color: .blue
                )
                
                RiskMetricView(
                    title: "Total Exposure",
                    value: String(format: "₹%.0f", aiOrchestrator.riskMetrics.totalExposure),
                    color: .orange
                )
                
                RiskMetricView(
                    title: "Max Drawdown",
                    value: String(format: "%.1f%%", aiOrchestrator.riskMetrics.maxDrawdown * 100),
                    color: .red
                )
                
                RiskMetricView(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", aiOrchestrator.riskMetrics.sharpeRatio),
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Performance Analytics Card
    @ViewBuilder
    private func PerformanceAnalyticsCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Performance Analytics")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", aiOrchestrator.performanceMetrics.winRate * 100))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profit Factor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", aiOrchestrator.performanceMetrics.profitFactor))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Trades")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(aiOrchestrator.performanceMetrics.totalTrades)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func startRealTimeUpdates() {
        dataProvider.startRealTimeDataStream()
    }
    
    private func stopRealTimeUpdates() {
        dataProvider.stopRealTimeDataStream()
    }
    
    private func statusColor(for status: TradingStatus) -> Color {
        switch status {
        case .running:
            return .green
        case .paused:
            return .orange
        case .stopped:
            return .gray
        case .emergencyStopped:
            return .red
        }
    }
    
    private func statusText(for status: TradingStatus) -> String {
        switch status {
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        case .emergencyStopped:
            return "Emergency Stop"
        }
    }
    
    private func formatExpiryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
    
    // This function ensures the date passed to the Picker has a valid tag
    private func ensureValidExpiryDate(_ date: Date) -> Date {
        // Find the closest available expiry date
        let calendar = Calendar.current
        let normalizedInput = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) ?? date
        
        // If the date is in the available expiries, use it
        if availableExpiries.contains(normalizedInput) {
            return normalizedInput
        }
        
        // Otherwise, use the first available expiry
        return availableExpiries.first ?? date
    }
}

// MARK: - Supporting Views
struct OptionsChainView: View {
    let optionsChain: NIFTYOptionsChain
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Strike")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 60)
                
                Text("CE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                
                Text("PE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .foregroundColor(.secondary)
            
            Divider()
            
            // Options data
            let atmStrike = optionsChain.getATMStrike()
            let relevantStrikes = getRelevantStrikes(atmStrike: atmStrike)
            
            ForEach(relevantStrikes, id: \.self) { strike in
                OptionsChainRowView(
                    strike: strike,
                    callOption: optionsChain.callOptions.first { $0.strikePrice == strike },
                    putOption: optionsChain.putOptions.first { $0.strikePrice == strike },
                    isATM: strike == atmStrike
                )
            }
        }
        .frame(maxHeight: 200)
    }
    
    private func getRelevantStrikes(atmStrike: Double) -> [Double] {
        let range = 5 // Show ±5 strikes around ATM
        var strikes: [Double] = []
        
        for i in -range...range {
            strikes.append(atmStrike + Double(i * 50))
        }
        
        return strikes.sorted()
    }
}

struct OptionsChainRowView: View {
    let strike: Double
    let callOption: NIFTYOptionContract?
    let putOption: NIFTYOptionContract?
    let isATM: Bool
    
    var body: some View {
        HStack {
            Text("\(Int(strike))")
                .font(.caption)
                .fontWeight(isATM ? .bold : .regular)
                .foregroundColor(isATM ? .blue : .primary)
                .frame(width: 60)
            
            // Call option
            VStack(spacing: 2) {
                Text(String(format: "₹%.2f", callOption?.currentPrice ?? 0))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(String(format: "IV: %.0f%%", callOption?.impliedVolatility ?? 0))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .background(isATM ? Color.blue.opacity(0.1) : Color.clear)
            
            // Put option
            VStack(spacing: 2) {
                Text(String(format: "₹%.2f", putOption?.currentPrice ?? 0))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(String(format: "IV: %.0f%%", putOption?.impliedVolatility ?? 0))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .background(isATM ? Color.blue.opacity(0.1) : Color.clear)
        }
        .padding(.vertical, 2)
    }
}

struct PositionRowView: View {
    let position: OptionsPosition
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(position.symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(position.quantity) lots")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "₹%.2f", position.unrealizedPnL))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(position.unrealizedPnL >= 0 ? .green : .red)
                
                Text(String(format: "₹%.2f", position.currentPrice))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PatternAlertRowView: View {
    let pattern: IntradayPattern
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(pattern.direction.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f%%", pattern.confidence * 100))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(confidenceColor(pattern.confidence))
                
                Text(timeAgo(pattern.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

struct RiskMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NIFTYOptionsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
// PatternTimeframe and PatternType extensions are defined in NIFTYOptionsDataModels.swift
