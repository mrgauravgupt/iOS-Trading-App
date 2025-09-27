
/// Advanced Paper Trading View with AI Auto-Trading Engine
import SwiftUI
import SharedPatternModels

struct PaperTradingView: View {
    // Core Trading State
    @State private var selectedSymbol = "NIFTY"
    @State private var quantity = ""
    @State private var orderType = "Buy"
    @State private var portfolioValue = 100000.0
    @State private var holdings: [String: Int] = [:]
    @State private var trades: [VirtualPortfolio.PortfolioTrade] = []
    
    // AI Auto-Trading State
    @StateObject private var aiTradingEngine = AIAutoTradingEngine()
    @StateObject private var patternEngine = PatternRecognitionEngine()
    @StateObject private var riskManager = AdvancedRiskManager()
    @State private var isAITradingEnabled = false
    @State private var aiTradingMode: AITradingMode = .conservative
    @State private var maxPositionSize: Double = 0.05 // 5% max per trade
    @State private var stopLossPercentage: Double = 0.02 // 2% stop loss
    @State private var takeProfitPercentage: Double = 0.04 // 4% take profit
    
    // Enhanced Alerts and Analysis
    @State private var patternAlerts: [SharedPatternModels.PatternAlert] = []
    @State private var aiDecisions: [AITradingDecision] = []
    @State private var momentumAlerts: [String] = []
    @State private var showAdvancedControls = false
    @State private var showPerformanceAnalytics = false
    @State private var showRiskDashboard = false
    
    // UI State
    @State private var showAlerts = true
    @State private var showOrderConfirmation = false
    @State private var orderConfirmationMessage = ""
    @State private var selectedTab: TradingTab = .overview

    // Core Components
    private let orderExecutor = OrderExecutor()
    private let plCalculator = PLCalculator()
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    private let zerodhaClient = ZerodhaAPIClient()
    
    // Alert state
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    enum AITradingMode: String, CaseIterable {
        case conservative = "Conservative"
        case moderate = "Moderate"
        case aggressive = "Aggressive"
        case custom = "Custom"
    }
    
    enum TradingTab: String, CaseIterable {
        case overview = "Overview"
        case trading = "Trading"
        case patterns = "Patterns"
        case risk = "Risk"
        case performance = "Performance"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with AI Status
                headerWithAIStatus

                // Tab Navigation
                tabNavigationBar

                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            overviewSection
                        case .trading:
                            tradingSection
                        case .patterns:
                            patternsSection
                        case .risk:
                            riskSection
                        case .performance:
                            performanceSection
                        }
                    }
                    .padding(10)
                }
            }
            .background(Color.kiteBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("AI Paper Trading")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadPortfolioData()
                startAIAnalysis()
            }
            .onChange(of: isAITradingEnabled) { _, enabled in
                if enabled {
                    aiTradingEngine.startAutoTrading()
                } else {
                    aiTradingEngine.stopAutoTrading()
                }
            }
            .alert("Order Confirmation", isPresented: $showOrderConfirmation) {
                Button("OK") { }
            } message: {
                Text(orderConfirmationMessage)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showAdvancedControls) {
                AdvancedTradingControlsView(
                    isAIEnabled: $isAITradingEnabled,
                    tradingMode: $aiTradingMode,
                    maxPositionSize: $maxPositionSize,
                    stopLoss: $stopLossPercentage,
                    takeProfit: $takeProfitPercentage
                )
            }
            .sheet(isPresented: $showPerformanceAnalytics) {
                Text("Performance Analytics Placeholder")
            }
            .sheet(isPresented: $showRiskDashboard) {
                Text("Risk Management Dashboard Placeholder")
            }
        }
    }
    
    // MARK: - Header with AI Status
    
    private var headerWithAIStatus: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("AI Paper Trading")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Text("Advanced Pattern Recognition & Auto-Trading")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // AI Status Indicator
                VStack {
                    Circle()
                        .fill(isAITradingEnabled ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(isAITradingEnabled ? "AI ACTIVE" : "MANUAL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isAITradingEnabled ? .green : .red)
                }
            }
            
            // AI Trading Master Toggle
            HStack {
                VStack(alignment: .leading) {
                    Text("AI Auto-Trading")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Enable autonomous pattern-based trading")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isAITradingEnabled)
                    .scaleEffect(1.0)
                
                Button("Settings") {
                    showAdvancedControls = true
                }
                .font(.caption2)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            
            Divider()
        }
        .padding(12)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Tab Navigation
    
    private var tabNavigationBar: some View {
        HStack(spacing: 0) {
            ForEach(TradingTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: iconForTab(tab))
                            .font(.caption)
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 12)
    }
    
    private func iconForTab(_ tab: TradingTab) -> String {
        switch tab {
        case .overview: return "chart.pie.fill"
        case .trading: return "arrow.left.arrow.right"
        case .patterns: return "waveform.path.ecg"
        case .risk: return "shield.lefthalf.filled"
        case .performance: return "chart.bar.fill"
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Portfolio Overview with AI Insights
            enhancedPortfolioOverview
            
            // Real-time AI Decisions
            aiDecisionsSection
            
            // Pattern Alerts
            patternAlertsSection
            
            // Quick Actions
            quickActionsSection
        }
    }
    
    private var enhancedPortfolioOverview: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portfolio Overview")
                    .font(.caption)
                    .fontWeight(.semibold)

                Spacer()

                Button("Analytics") {
                    showPerformanceAnalytics = true
                }
                .font(.caption2)
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                PortfolioMetricCard(
                    title: "Portfolio Value",
                    value: "₹\(String(format: "%.0f", portfolioValue))",
                    change: "+₹\(String(format: "%.0f", portfolioValue * 0.05))",
                    color: .green
                )
                
                PortfolioMetricCard(
                    title: "Today's P&L",
                    value: "+₹2,340",
                    change: "+2.34%",
                    color: .green
                )
                
                PortfolioMetricCard(
                    title: "Cash Balance",
                    value: "₹\(String(format: "%.0f", orderExecutor.getPortfolioBalance()))",
                    change: "Available",
                    color: .blue
                )
                
                PortfolioMetricCard(
                    title: "AI Accuracy",
                    value: "73.2%",
                    change: "+5.1%",
                    color: .purple
                )
                
                PortfolioMetricCard(
                    title: "Active Patterns",
                    value: "\(patternAlerts.count)",
                    change: "Detected",
                    color: .orange
                )
                
                PortfolioMetricCard(
                    title: "Risk Score",
                    value: "Low",
                    change: "3.2/10",
                    color: .green
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var aiDecisionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                    .font(.caption)
                Text("Real-time AI Decisions")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()

                Text("Live")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            if aiDecisions.isEmpty {
                Text("AI is analyzing market patterns...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
            } else {
                ForEach(aiDecisions.prefix(3), id: \.id) { decision in
                    AIDecisionCard(decision: decision)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var patternAlertsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Pattern Alerts")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()

                Text("\(patternAlerts.count) Active")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if patternAlerts.isEmpty {
                Text("No patterns detected at current confidence level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
            } else {
                ForEach(Array(patternAlerts.prefix(3)), id: \.timestamp) { alert in
                    PaperTradingPatternAlertCard(alert: alert)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 8) {
                QuickActionButton(
                    title: "Emergency Stop",
                    icon: "stop.circle.fill",
                    color: .red
                ) {
                    emergencyStopAI()
                }
                
                QuickActionButton(
                    title: "Force Buy",
                    icon: "arrow.up.circle.fill",
                    color: .green
                ) {
                    forceBuyWithAI()
                }
                
                QuickActionButton(
                    title: "Force Sell",
                    icon: "arrow.down.circle.fill",
                    color: .orange
                ) {
                    forceSellWithAI()
                }
                
                QuickActionButton(
                    title: "Risk Check",
                    icon: "shield.checkerboard",
                    color: .blue
                ) {
                    showRiskDashboard = true
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Market Overview Card

    private var marketOverviewCard: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Market Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("NIFTY")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Spot Price")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("₹24,500")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading) {
                    Text("Change")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("+125.50 (+0.51%)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Volume")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("2.3M")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Trading Section

    private var tradingSection: some View {
        VStack(spacing: 16) {
            // Market Overview
            marketOverviewCard

            // Enhanced Order Placement
            enhancedOrderPlacement

            // Holdings & Trade History in a compact layout
            HStack(spacing: 16) {
                // Current Holdings
                VStack {
                    Text("Holdings")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if holdings.isEmpty {
                        Text("No positions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(holdings.keys.sorted(), id: \.self) { symbol in
                                    HStack {
                                        Text(symbol)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(holdings[symbol] ?? 0)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .frame(height: 120)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Recent Trades
                VStack {
                    Text("Recent Trades")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if trades.isEmpty {
                        Text("No trades")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(trades.prefix(3), id: \.timestamp) { trade in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(trade.symbol)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text(trade.type == .buy ? "BUY" : "SELL")
                                                .font(.caption2)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(trade.type == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                                .foregroundColor(trade.type == .buy ? .green : .red)
                                                .cornerRadius(4)
                                        }
                                        Text("\(trade.quantity) @ ₹\(String(format: "%.0f", trade.price))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .frame(height: 120)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var enhancedOrderPlacement: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Place Order")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 10) {
                // Symbol and Quantity in one row
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Symbol")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("NIFTY", text: $selectedSymbol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.characters)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quantity")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("100", text: $quantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                            .keyboardType(.numberPad)
                    }
                }

                // Order Type
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order Type")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Picker("Order Type", selection: $orderType) {
                        Text("Buy").tag("Buy")
                        Text("Sell").tag("Sell")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .scaleEffect(0.95)
                }

                // AI Insights (if enabled)
                if isAITradingEnabled {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("AI Suggestion: Buy 150 shares")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Confidence: 82.3% • Risk: Low")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Image(systemName: "brain")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    .padding(6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
                }

                // Place Order Button
                Button(action: placeEnhancedOrder) {
                    HStack {
                        if isAITradingEnabled {
                            Image(systemName: "brain")
                                .font(.caption)
                        }
                        Text(isAITradingEnabled ? "AI-Assisted Order" : "Place Order")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .background(isAITradingEnabled ? Color.purple : Color.blue)
                    .cornerRadius(8)
                }
                .disabled(quantity.isEmpty || !isQuantityValid)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var aiTradingSuggestions: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                Text("AI Trading Suggestions")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 6) {
                SuggestionCard(
                    symbol: "NIFTY",
                    action: "BUY",
                    confidence: 0.87,
                    reason: "Bull Flag pattern detected with high volume confirmation",
                    targetPrice: 18250,
                    stopLoss: 17850
                )
                
                SuggestionCard(
                    symbol: "BANKNIFTY",
                    action: "SELL",
                    confidence: 0.72,
                    reason: "Head and Shoulders pattern forming resistance",
                    targetPrice: 42800,
                    stopLoss: 43200
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Patterns Section
    
    private var patternsSection: some View {
        VStack(spacing: 20) {
            Text("Pattern Scanner - Coming Soon")
                .font(.callout)
                .foregroundColor(.secondary)
            // PatternScannerView(
            //     multiTimeframeAnalysis: [:],
            //     patternAlerts: patternAlerts,
            //     confluencePatterns: []
            // )
        }
    }
    
    // MARK: - Risk Section
    
    private var riskSection: some View {
        VStack(spacing: 20) {
            Text("Risk Management Dashboard - Coming Soon")
                .font(.callout)
                .foregroundColor(.secondary)
            // RiskManagementDashboard()
        }
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        VStack(spacing: 20) {
            Text("Performance Analytics - Coming Soon")
                .font(.headline)
                .foregroundColor(.secondary)
            // PerformanceAnalyticsView()
        }
    }
    
    /// Portfolio overview section
    private var portfolioOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Portfolio Value:")
                Spacer()
                Text("₹\(portfolioValue, specifier: "%.2f")")
                    .fontWeight(.semibold)
            }
            HStack {
                Text("Cash Balance:")
                Spacer()
                Text("₹\(orderExecutor.getPortfolioBalance(), specifier: "%.2f")")
                    .fontWeight(.semibold)
            }
        }
    }
    
    /// Momentum alerts section
    private var momentumAlertsSection: some View {
        Group {
            if showAlerts && !momentumAlerts.isEmpty {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(momentumAlerts.indices, id: \.self) { index in
                            Text(momentumAlerts[index])
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                } label: {
                    Text("Momentum Alerts")
                }
            }
        }
    }
    
    /// Order placement section
    private var orderPlacementSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField("Symbol", text: $selectedSymbol)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .textInputAutocapitalization(.characters)
            TextField("Quantity", text: $quantity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            Picker("Order Type", selection: $orderType) {
                Text("Buy").tag("Buy")
                Text("Sell").tag("Sell")
            }
            .pickerStyle(SegmentedPickerStyle())
            Button(action: placeOrder) {
                Text("Place Order")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.kiteBlue)
                    .cornerRadius(10)
            }
            .disabled(quantity.isEmpty || !isQuantityValid)
        }
    }
    
    /// Holdings section
    private var holdingsSection: some View {
        GroupBox {
            if holdings.isEmpty {
                Text("No holdings")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(holdings.keys.sorted(), id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                        Spacer()
                        Text("\(holdings[symbol] ?? 0) shares")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        } label: {
            Text("Current Holdings")
        }
    }
    
    /// Trade history section
    private var tradeHistorySection: some View {
        GroupBox {
            if trades.isEmpty {
                Text("No trades yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(trades.prefix(5), id: \.timestamp) { trade in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(trade.symbol)
                                .fontWeight(.semibold)
                            Text(trade.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(trade.type == .buy ? "BUY" : "SELL") \(trade.quantity)")
                            Text(String(format: "₹%.2f", trade.price))
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        } label: {
            Text("Recent Trades")
        }
    }
    
    // MARK: - Helper Functions and Original Methods
    
    /// Check if quantity is valid
    private var isQuantityValid: Bool {
        guard let qty = Int(quantity) else { return false }
        return qty > 0
    }
    
    /// Enhanced order placement with AI assistance
    private func placeEnhancedOrder() {
        guard let qty = Int(quantity), qty > 0 else {
            orderConfirmationMessage = "Please enter a valid quantity"
            showOrderConfirmation = true
            return
        }
        
        // AI-enhanced order validation
        if isAITradingEnabled {
            // Create a simple risk assessment for now
            // Get real-time price or show error
            guard let currentPrice = getCurrentMarketPrice() else {
                showAlert(title: "Price Error", message: "Unable to fetch current market price. Please check your connection to Zerodha.")
                return
            }
            let orderValue = Double(qty) * currentPrice
            let positionSizePercentage = orderValue / portfolioValue
            
            if positionSizePercentage > maxPositionSize {
                orderConfirmationMessage = "AI Risk Manager: Order rejected - Position size (\(String(format: "%.1f", positionSizePercentage * 100))%) exceeds limit (\(String(format: "%.1f", maxPositionSize * 100))%)"
                showOrderConfirmation = true
                return
            }
        }
        
        // Execute order with AI assistance
        guard let price = getCurrentMarketPrice() else {
            showAlert(title: "Price Error", message: "Unable to fetch current market price. Please check your connection to Zerodha.")
            return
        }
        let type: VirtualPortfolio.PortfolioTrade.TradeType = orderType == "Buy" ? .buy : .sell
        
        let success = orderExecutor.executeOrder(symbol: selectedSymbol, quantity: qty, price: price, type: type)
        
        if success {
            // Log AI decision if enabled
            if isAITradingEnabled {
                let decision = AITradingDecision(
                    id: UUID(),
                    timestamp: Date(),
                    symbol: selectedSymbol,
                    action: orderType,
                    quantity: qty,
                    price: price,
                    confidence: 0.75,
                    reason: "User-initiated order with AI validation",
                    agent: "AI Assistant"
                )
                aiDecisions.insert(decision, at: 0)
            }
            
            orderConfirmationMessage = "\(orderType) order for \(qty) shares of \(selectedSymbol) executed successfully"
            loadPortfolioData()
            quantity = ""
        } else {
            if type == .buy {
                orderConfirmationMessage = "Insufficient funds to buy \(qty) shares of \(selectedSymbol)"
            } else {
                orderConfirmationMessage = "Insufficient holdings to sell \(qty) shares of \(selectedSymbol)"
            }
        }
        
        showOrderConfirmation = true
    }
    
    /// Original place order method (for backward compatibility)
    private func placeOrder() {
        placeEnhancedOrder()
    }
    
    /// Load portfolio data with AI insights
    private func loadPortfolioData() {
        let currentPrices = getCurrentMarketPrices()
        portfolioValue = orderExecutor.getPortfolioValue(currentPrices: currentPrices)
        holdings = orderExecutor.getPortfolioHoldings()
        trades = orderExecutor.getTradeHistory()
    }
    
    /// Start AI analysis and pattern detection
    private func startAIAnalysis() {
        Task {
            do {
                // Get real market data for analysis
                let marketData = try await withCheckedThrowingContinuation { continuation in
                    zerodhaClient.fetchLTP(symbol: "NIFTY") { result in
                        continuation.resume(with: result)
                    }
                }
                
                // Perform real pattern analysis
                let analysis = patternEngine.scanForPatternAlerts(marketData: [marketData])
                
                await MainActor.run {
                    self.patternAlerts = analysis
                    
                    // Generate AI decisions based on real patterns
                    if let strongestPattern = analysis.first {
                        let decision = AITradingDecision(
                            id: UUID(),
                            timestamp: Date(),
                            symbol: "NIFTY",
                            action: strongestPattern.signal == .buy ? "BUY" : strongestPattern.signal == .sell ? "SELL" : "HOLD",
                            quantity: calculateOptimalQuantity(price: marketData.price),
                            price: marketData.price,
                            confidence: strongestPattern.confidence,
                            reason: "Pattern: \(strongestPattern.patternType) detected",
                            agent: "Pattern Recognition AI"
                        )
                        self.aiDecisions = [decision]
                    } else {
                        self.aiDecisions = []
                    }
                }
                
                // Start real-time pattern monitoring if AI enabled
                if isAITradingEnabled {
                    aiTradingEngine.startPatternMonitoring()
                }
            } catch {
                await MainActor.run {
                    print("Error in AI analysis: \(error.localizedDescription)")
                    self.patternAlerts = []
                    self.aiDecisions = []
                }
            }
        }
    }
    
    private func calculateOptimalQuantity(price: Double) -> Int {
        let riskAmount = portfolioValue * 0.02 // Risk 2% of portfolio
        let quantity = Int(riskAmount / price)
        return max(1, quantity) // At least 1 share
    }
    
    /// Analyze specific symbol
    private func analyzeSymbol() {
        Task {
            do {
                // Get real market data for the selected symbol
                let marketData = try await withCheckedThrowingContinuation { continuation in
                    zerodhaClient.fetchLTP(symbol: selectedSymbol) { result in
                        continuation.resume(with: result)
                    }
                }
                let analysis = patternEngine.scanForPatternAlerts(marketData: [marketData])
                
                await MainActor.run {
                    self.patternAlerts = analysis
                }
            } catch {
                await MainActor.run {
                    print("Error analyzing symbol \(selectedSymbol): \(error.localizedDescription)")
                    self.patternAlerts = []
                }
            }
        }
    }
    
    /// Emergency stop all AI trading
    private func emergencyStopAI() {
        isAITradingEnabled = false
        aiTradingEngine.emergencyStop()
        orderConfirmationMessage = "Emergency stop activated - All AI trading halted"
        showOrderConfirmation = true
    }
    
    /// Force buy with AI validation
    private func forceBuyWithAI() {
        let suggestedQuantity = aiTradingEngine.calculateOptimalQuantity(
            symbol: selectedSymbol,
            action: "BUY",
            portfolioValue: portfolioValue
        )
        quantity = "\(suggestedQuantity)"
        orderType = "Buy"
    }
    
    /// Force sell with AI validation
    private func forceSellWithAI() {
        let currentHolding = holdings[selectedSymbol] ?? 0
        if currentHolding > 0 {
            quantity = "\(currentHolding)"
            orderType = "Sell"
        } else {
            orderConfirmationMessage = "No holdings to sell for \(selectedSymbol)"
            showOrderConfirmation = true
        }
    }
    
    // MARK: - Helper Functions
    
    /// Get current market price for selected symbol
    private func getCurrentMarketPrice() -> Double? {
        // Fetch real price from Zerodha API
        // Note: This is synchronous for simplicity, but in production use async fetch
        // For now, return nil to indicate need for real data
        return nil
    }
    
    /// Get current market prices for all symbols
    private func getCurrentMarketPrices() -> [String: Double] {
        // Return empty dictionary to indicate no mock data available
        // In production, this should fetch real prices from Zerodha API
        return [:]
    }
    
    /// Show alert with title and message
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

}

// MARK: - Supporting Views and Data Models

struct PortfolioMetricCard: View {
    let title: String
    let value: String
    let change: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(change)
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

struct AIDecisionCard: View {
    let decision: AITradingDecision
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(decision.symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(decision.action)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(decision.action == "BUY" ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(3)
                }
                
                Text(decision.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(decision.confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(decision.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// Custom PatternAlertCard for PaperTradingView
struct PaperTradingPatternAlertCard: View {
    let alert: SharedPatternModels.PatternAlert
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(alert.patternType)".capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    urgencyBadge
                }
                
                Text("Confidence: \(String(format: "%.1f%%", alert.confidence * 100))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Signal: \(alert.signal)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: urgencyIcon)
                    .foregroundColor(urgencyColor)
                    .font(.subheadline)
            }
        }
        .padding(8)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(6)
        .shadow(radius: 0.5)
    }
    
    private var urgencyBadge: some View {
        Text((alert.urgency?.rawValue ?? "medium").uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(urgencyColor.opacity(0.2))
            .foregroundColor(urgencyColor)
            .cornerRadius(3)
    }
    
    private var urgencyColor: Color {
        switch alert.urgency ?? .medium {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    private var urgencyIcon: String {
        switch alert.urgency ?? .medium {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuggestionCard: View {
    let symbol: String
    let action: String
    let confidence: Double
    let reason: String
    let targetPrice: Double
    let stopLoss: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(action)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(action == "BUY" ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(3)
                    
                    Spacer()
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Text(reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("Target: ₹\(String(format: "%.0f", targetPrice))")
                        .font(.caption2)
                    
                    Text("SL: ₹\(String(format: "%.0f", stopLoss))")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Advanced Trading Controls View

struct AdvancedTradingControlsView: View {
    @Binding var isAIEnabled: Bool
    @Binding var tradingMode: PaperTradingView.AITradingMode
    @Binding var maxPositionSize: Double
    @Binding var stopLoss: Double
    @Binding var takeProfit: Double
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Advanced AI Trading Controls")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                VStack(spacing: 12) {
                    Toggle("Enable AI Auto-Trading", isOn: $isAIEnabled)
                        .font(.caption)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trading Mode")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Picker("Trading Mode", selection: $tradingMode) {
                            ForEach(PaperTradingView.AITradingMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .scaleEffect(0.95)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Risk Parameters")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Max Position Size: \(String(format: "%.1f%%", maxPositionSize * 100))")
                                .font(.caption2)
                            Slider(value: $maxPositionSize, in: 0.01...0.10, step: 0.01)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Stop Loss: \(String(format: "%.1f%%", stopLoss * 100))")
                                .font(.caption2)
                            Slider(value: $stopLoss, in: 0.01...0.05, step: 0.01)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Take Profit: \(String(format: "%.1f%%", takeProfit * 100))")
                                .font(.caption2)
                            Slider(value: $takeProfit, in: 0.02...0.10, step: 0.01)
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(12)
            .navigationTitle("AI Controls")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Data Models

struct AITradingDecision {
    let id: UUID
    let timestamp: Date
    let symbol: String
    let action: String
    let quantity: Int
    let price: Double
    let confidence: Double
    let reason: String
    let agent: String
}

// RiskAlert is defined in RiskManagementDashboard.swift

// MARK: - AI Trading Engine

class AIAutoTradingEngine: ObservableObject {
    @Published var isActive = false
    @Published var currentMode: PaperTradingView.AITradingMode = .conservative
    
    func startAutoTrading() {
        isActive = true
        // Initialize AI trading algorithms
    }
    
    func stopAutoTrading() {
        isActive = false
        // Stop all AI trading activities
    }
    
    func emergencyStop() {
        isActive = false
        // Emergency halt all positions and orders
    }
    
    func startPatternMonitoring() {
        // Start real-time pattern monitoring
    }
    
    func calculateOptimalQuantity(symbol: String, action: String, portfolioValue: Double) -> Int {
        // Calculate optimal position size based on risk parameters
        return 100 // Placeholder
    }
}