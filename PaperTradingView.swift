import SwiftUI

/// Advanced Paper Trading View with AI Auto-Trading Engine
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
    @State private var patternAlerts: [PatternRecognitionEngine.PatternAlert] = []
    @State private var riskAlerts: [RiskAlert] = []
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
                    .padding()
                }
            }
            .background(Color.kiteBackground.ignoresSafeArea())
            .navigationTitle("AI Paper Trading")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadPortfolioData()
                startAIAnalysis()
            }
            .onChange(of: isAITradingEnabled) { enabled in
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
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("AI Paper Trading")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Advanced Pattern Recognition & Auto-Trading")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // AI Status Indicator
                VStack {
                    Circle()
                        .fill(isAITradingEnabled ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
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
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Enable autonomous pattern-based trading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isAITradingEnabled)
                    .scaleEffect(1.2)
                
                Button("Settings") {
                    showAdvancedControls = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Divider()
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Tab Navigation
    
    private var tabNavigationBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(TradingTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(Color(.systemBackground))
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
        VStack(spacing: 16) {
            HStack {
                Text("Portfolio Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Analytics") {
                    showPerformanceAnalytics = true
                }
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var aiDecisionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text("Real-time AI Decisions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("Live")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if aiDecisions.isEmpty {
                Text("AI is analyzing market patterns...")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(aiDecisions.prefix(3), id: \.id) { decision in
                    AIDecisionCard(decision: decision)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var patternAlertsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
                Text("Pattern Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("\(patternAlerts.count) Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if patternAlerts.isEmpty {
                Text("No patterns detected at current confidence level")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(patternAlerts.prefix(3)), id: \.timestamp) { alert in
                    PatternAlertCard(alert: alert)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Trading Section
    
    private var tradingSection: some View {
        VStack(spacing: 20) {
            // Enhanced Order Placement
            enhancedOrderPlacement
            
            // AI Suggestions
            aiTradingSuggestions
            
            // Holdings
            SectionCard("Current Holdings") { holdingsSection }
            
            // Trade History
            SectionCard("Recent Trades") { tradeHistorySection }
        }
    }
    
    private var enhancedOrderPlacement: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Place Order")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Toggle("AI Assist", isOn: .constant(true))
                    .scaleEffect(0.8)
            }
            
            VStack(spacing: 12) {
                HStack {
                    TextField("Symbol", text: $selectedSymbol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.characters)
                    
                    Button("Analyze") {
                        analyzeSymbol()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                HStack {
                    TextField("Quantity", text: $quantity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    VStack(alignment: .leading) {
                        Text("AI Suggested: 150")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Risk: Low")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Picker("Order Type", selection: $orderType) {
                    Text("Buy").tag("Buy")
                    Text("Sell").tag("Sell")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // AI Risk Assessment
                HStack {
                    VStack(alignment: .leading) {
                        Text("Position Size: \(String(format: "%.1f%%", maxPositionSize * 100))")
                            .font(.caption)
                        Text("Stop Loss: \(String(format: "%.1f%%", stopLossPercentage * 100))")
                            .font(.caption)
                        Text("Take Profit: \(String(format: "%.1f%%", takeProfitPercentage * 100))")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("AI Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("82.3%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: placeEnhancedOrder) {
                    HStack {
                        if isAITradingEnabled {
                            Image(systemName: "brain")
                        }
                        Text(isAITradingEnabled ? "AI-Assisted Order" : "Place Order")
                    }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(isAITradingEnabled ? Color.purple : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(quantity.isEmpty || !isQuantityValid)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var aiTradingSuggestions: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("AI Trading Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Patterns Section
    
    private var patternsSection: some View {
        VStack(spacing: 20) {
            PatternScannerView(
                multiTimeframeAnalysis: [:],
                patternAlerts: patternAlerts,
                confluencePatterns: []
            )
        }
    }
    
    // MARK: - Risk Section
    
    private var riskSection: some View {
        VStack(spacing: 20) {
            RiskManagementDashboard()
        }
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        VStack(spacing: 20) {
            PerformanceAnalyticsView()
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
                            Text("₹\(trade.price, specifier: "%.2f")")
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
            let orderValue = Double(qty) * 18000.0 // Placeholder price
            let positionSizePercentage = orderValue / portfolioValue
            
            if positionSizePercentage > maxPositionSize {
                orderConfirmationMessage = "AI Risk Manager: Order rejected - Position size (\(positionSizePercentage * 100, specifier: "%.1f")%) exceeds limit (\(maxPositionSize * 100, specifier: "%.1f")%)"
                showOrderConfirmation = true
                return
            }
        }
        
        // Execute order with AI assistance
        let price = 18000.0 // Placeholder - would be real-time price
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
        portfolioValue = orderExecutor.getPortfolioValue(currentPrices: ["NIFTY": 18000.0])
        holdings = orderExecutor.getPortfolioHoldings()
        trades = orderExecutor.getTradeHistory()
    }
    
    /// Start AI analysis and pattern detection
    private func startAIAnalysis() {
        // Generate sample pattern alerts using proper PatternRecognitionEngine.PatternAlert structure
        let bullFlagPattern = TechnicalAnalysisEngine.PatternResult(
            pattern: "Bull Flag",
            signal: .buy,
            confidence: 0.87,
            timeframe: "1h",
            strength: .strong,
            targets: [18500.0, 19000.0],
            stopLoss: 17500.0,
            successRate: 0.75
        )
        
        let headShouldersPattern = TechnicalAnalysisEngine.PatternResult(
            pattern: "Head and Shoulders",
            signal: .sell,
            confidence: 0.73,
            timeframe: "4h",
            strength: .moderate,
            targets: [17500.0, 17000.0],
            stopLoss: 18200.0,
            successRate: 0.68
        )
        
        patternAlerts = [
            PatternRecognitionEngine.PatternAlert(
                pattern: bullFlagPattern,
                timeframe: "1h",
                timestamp: Date(),
                urgency: .high
            ),
            PatternRecognitionEngine.PatternAlert(
                pattern: headShouldersPattern,
                timeframe: "4h",
                timestamp: Date(),
                urgency: .medium
            )
        ]
        
        // Generate sample AI decisions
        aiDecisions = [
            AITradingDecision(
                id: UUID(),
                timestamp: Date(),
                symbol: "NIFTY",
                action: "BUY",
                quantity: 150,
                price: 18000.0,
                confidence: 0.82,
                reason: "Bull Flag breakout with volume confirmation",
                agent: "Pattern Recognition AI"
            )
        ]
        
        // Start real-time pattern monitoring if AI enabled
        if isAITradingEnabled {
            aiTradingEngine.startPatternMonitoring()
        }
    }
    
    /// Analyze specific symbol
    private func analyzeSymbol() {
        // Implement symbol-specific analysis
        // Create sample market data for the selected symbol
        let sampleData = [
            MarketData(open: 18000, high: 18100, low: 17950, close: 18050, volume: 1000000, timestamp: Date())
        ]
        let analysis = patternEngine.scanForPatternAlerts(marketData: sampleData)
        // Update UI with analysis results
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

}

// MARK: - Supporting Views and Data Models

struct PortfolioMetricCard: View {
    let title: String
    let value: String
    let change: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(change)
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AIDecisionCard: View {
    let decision: AITradingDecision
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(decision.symbol)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(decision.action)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(decision.action == "BUY" ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Text(decision.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(decision.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(decision.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct PatternAlertCard: View {
    let alert: PatternRecognitionEngine.PatternAlert
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.pattern.pattern)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Circle()
                        .fill(urgencyColor(alert.urgency))
                        .frame(width: 8, height: 8)
                }
                
                Text(alert.alertMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(alert.pattern.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text(alert.timeframe)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func urgencyColor(_ urgency: PatternRecognitionEngine.AlertUrgency) -> Color {
        switch urgency {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(12)
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(symbol)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(action)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(action == "BUY" ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Text(reason)
                    .font(.caption)
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
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
            VStack(spacing: 20) {
                Text("Advanced AI Trading Controls")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Toggle("Enable AI Auto-Trading", isOn: $isAIEnabled)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trading Mode")
                            .font(.headline)
                        
                        Picker("Trading Mode", selection: $tradingMode) {
                            ForEach(PaperTradingView.AITradingMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Risk Parameters")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Position Size: \(String(format: "%.1f%%", maxPositionSize * 100))")
                            Slider(value: $maxPositionSize, in: 0.01...0.10, step: 0.01)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stop Loss: \(String(format: "%.1f%%", stopLoss * 100))")
                            Slider(value: $stopLoss, in: 0.01...0.05, step: 0.01)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Take Profit: \(String(format: "%.1f%%", takeProfit * 100))")
                            Slider(value: $takeProfit, in: 0.02...0.10, step: 0.01)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
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

struct RiskAlert {
    let id: UUID
    let type: RiskType
    let severity: Severity
    let message: String
    let timestamp: Date
    
    enum RiskType {
        case portfolioExposure, correlationRisk, volatilitySpike, drawdown
    }
    
    enum Severity {
        case low, medium, high, critical
    }
}

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