import SwiftUI

struct ContentView: View {
    @State private var articles: [Article] = []
    @State private var isLoading = false
    @State private var marketData: String = "No data"
    @State private var portfolioValue: Double = 100000.0
    @State private var pnl: Double = 0.0
    @State private var selectedTab: Int = 0
    @State private var showQuickOrderSheet = false
    @State private var chartData: [MarketData] = []
    @State private var showLogin = false
    @State private var patternAlerts: [PatternRecognitionEngine.PatternAlert] = []
    @State private var multiTimeframeAnalysis: [String: [TechnicalAnalysisEngine.PatternResult]] = [:]
    @State private var confluencePatterns: [TechnicalAnalysisEngine.PatternResult] = []
    @State private var marketRegime: PatternRecognitionEngine.MarketRegime = .sideways
    @State private var showPatternScanner = false
    @State private var aiTradingEnabled = false
    @State private var lastPatternUpdate = Date()
    
    private let sentimentAnalyzer = SentimentAnalyzer()
    private let marketDataProvider = ZerodhaMarketDataProvider()
    private let historicalProvider = ZerodhaHistoricalDataProvider()
    private let virtualPortfolio = VirtualPortfolio()
    private let patternEngine = PatternRecognitionEngine()
    private let aiTrader = AIAgentTrader()

    // MARK: - Dashboard View
    private var dashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text("Dashboard")
                        .font(.largeTitle).bold()
                    Text("Live NIFTY overview and news")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Market snapshot with AI status
                marketOverviewSection
                
                // AI Trading Status Widget
                aiTradingStatusSection

                // Real-time Pattern Alerts
                if !patternAlerts.isEmpty {
                    patternAlertsSection
                }

                // Quick Access Navigation
                quickAccessSection

                // Multi-timeframe Analysis
                multiTimeframeAnalysisSection

                // Enhanced Market Intelligence
                marketIntelligenceSection

                // Quick actions
                SectionCard("Quick Actions") {
                    QuickActionButtons(onQuickOrder: { showQuickOrderSheet = true })
                }

                // News Feed
                newsFeedSection

                Spacer(minLength: 16)
            }
            .padding()
        }
        .background(Color.kiteBackground.ignoresSafeArea())
        .sheet(isPresented: $showQuickOrderSheet) {
            quickOrderSheet
        }
        .onAppear {
            loadNews()
            startPatternAnalysis()
            setupMarketDataProvider()
        }
        .sheet(isPresented: $showLogin) {
            loginSheet
        }
    }
    
    // MARK: - Dashboard Sections
    private var marketOverviewSection: some View {
        SectionCard("Market Overview") {
            VStack(alignment: .leading, spacing: 12) {
                MarketDataWidget(marketData: marketData)
                
                // Market Regime Indicator
                HStack {
                    Text("Market Regime:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(marketRegime.description)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(regimeColor(marketRegime))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                HStack(spacing: 12) {
                    StatChip(label: "Portfolio", value: "₹" + String(format: "%.2f", portfolioValue))
                    StatChip(label: "P&L", value: "₹" + String(format: "%.2f", pnl), color: pnl >= 0 ? .green : .red)
                    StatChip(label: "Cash", value: "₹" + String(format: "%.2f", virtualPortfolio.getBalance()))
                }
            }
        }
    }
    
    private var aiTradingStatusSection: some View {
        SectionCard("AI Trading Status") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: aiTradingEnabled ? "brain.head.profile" : "brain.head.profile.fill")
                        .foregroundColor(aiTradingEnabled ? .green : .gray)
                    Text("AI Auto-Trading")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $aiTradingEnabled)
                        .onChange(of: aiTradingEnabled) { enabled in
                            if enabled {
                                startAITrading()
                            }
                        }
                }
                
                if aiTradingEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("AI agents active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Text("Last analysis: \(lastPatternUpdate, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !confluencePatterns.isEmpty {
                            Text("Confluence patterns detected: \(confluencePatterns.count)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private var patternAlertsSection: some View {
        SectionCard("Pattern Alerts") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(patternAlerts.prefix(5).enumerated()), id: \.offset) { index, alert in
                    PatternAlertRow(alert: alert)
                        .onTapGesture {
                            // Could open detailed pattern view
                        }
                }
                
                if patternAlerts.count > 5 {
                    Button("View All \(patternAlerts.count) Alerts") {
                        showPatternScanner = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var quickAccessSection: some View {
        SectionCard("Quick Access") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    QuickAccessButton(
                        title: "Pattern Scanner",
                        icon: "waveform.path.ecg",
                        color: .purple
                    ) {
                        showPatternScanner = true
                    }
                    
                    QuickAccessButton(
                        title: "AI Control",
                        icon: "brain.head.profile",
                        color: .blue
                    ) {
                        selectedTab = 1
                    }
                }
                
                HStack(spacing: 12) {
                    QuickAccessButton(
                        title: "Analytics",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    ) {
                        selectedTab = 2
                    }
                    
                    QuickAccessButton(
                        title: "Risk Dashboard",
                        icon: "shield.fill",
                        color: .red
                    ) {
                        selectedTab = 6
                    }
                }
            }
        }
    }
    
    private var multiTimeframeAnalysisSection: some View {
        SectionCard("Multi-Timeframe Analysis") {
            VStack(alignment: .leading, spacing: 10) {
                if multiTimeframeAnalysis.isEmpty {
                    Text("Analyzing patterns across timeframes...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(["1D", "4h", "1h", "15m"], id: \.self) { timeframe in
                        if let patterns = multiTimeframeAnalysis[timeframe], !patterns.isEmpty {
                            TimeframeAnalysisRow(timeframe: timeframe, patterns: patterns)
                        }
                    }
                }
                
                Button("View Pattern Scanner") {
                    showPatternScanner = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var marketIntelligenceSection: some View {
        SectionCard("Market Intelligence") {
            VStack(alignment: .leading, spacing: 10) {
                // Confluence Patterns
                if !confluencePatterns.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Strong Confluence Patterns")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ForEach(Array(confluencePatterns.prefix(3).enumerated()), id: \.offset) { index, pattern in
                            HStack {
                                Circle()
                                    .fill(signalColor(pattern.signal))
                                    .frame(width: 8, height: 8)
                                Text(pattern.pattern)
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(pattern.confidence * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    Divider()
                }
                
                // Pattern Statistics
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Patterns")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(totalActivePatterns())")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Avg Confidence")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int(averageConfidence() * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private var newsFeedSection: some View {
        SectionCard("News & Sentiment") {
            if isLoading {
                ProgressView("Loading news...")
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(articles) { article in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(article.title)
                                .font(.headline)
                            if let description = article.description {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                let sentiment = sentimentAnalyzer.analyzeSentiment(for: description)
                                Text("Sentiment: \(sentiment)")
                                    .font(.caption)
                                    .foregroundStyle(sentiment == "Positive" ? .green : sentiment == "Negative" ? .red : .blue)
                            } else {
                                Text("No description available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(article.publishedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private var quickOrderSheet: some View {
        VStack(spacing: 16) {
            Text("Quick Order")
                .font(.title2)
                .fontWeight(.semibold)
            Text("For full controls, use the Paper Trading tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Go to Paper Trading") {
                showQuickOrderSheet = false
                selectedTab = 1 // Paper Trading tab index
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.height(240)])
    }
    
    private var loginSheet: some View {
        VStack(spacing: 16) {
            Text("Zerodha Login Required")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Please configure your Zerodha API credentials in Settings to access live market data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                // Close the overlay/sheet first, then switch tab
                showLogin = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    selectedTab = 4
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.medium])
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            dashboardView
            .tabItem {
                Image(systemName: "house")
                Text("Dashboard")
            }
            .tag(0)
            
            // AI Control Center Tab
            Text("AI Control Center - Coming Soon")
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Control")
                }
                .tag(1)
            
            // Analytics Tab
            Text("Performance Analytics - Coming Soon")
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
                .tag(2)
            
            // Paper Trading Tab
            PaperTradingView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Paper Trading")
                }
                .tag(3)
            
            // Backtesting Tab
            BacktestingView()
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Backtesting")
                }
                .tag(4)
            
            // Chart Tab
            ChartView(data: chartData)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Chart")
                }
                .tag(5)
            
            // Risk Management Tab
            Text("Risk Management - Coming Soon")
                .tabItem {
                    Image(systemName: "shield.fill")
                    Text("Risk")
                }
                .tag(6)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(7)
        }
        .sheet(isPresented: $showPatternScanner) {
            Text("Pattern Scanner - Coming Soon")
                .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupMarketDataProvider() {
        marketDataProvider.onTick = { tick in
            DispatchQueue.main.async {
                self.marketData = "\(tick.symbol) ₹\(String(format: "%.2f", tick.price))"
                
                // Update portfolio value
                let currentPrices = [tick.symbol: tick.price]
                self.portfolioValue = self.virtualPortfolio.getPortfolioValue(currentPrices: currentPrices)
                self.pnl = self.portfolioValue - 100000.0
                
                // Update chart data with new tick
                let newData = MarketData(symbol: tick.symbol, price: tick.price, volume: tick.volume, timestamp: Date())
                self.chartData.append(newData)
                
                // Keep only last 200 data points
                if self.chartData.count > 200 {
                    self.chartData.removeFirst()
                }
                
                // Trigger AI trading if enabled
                if self.aiTradingEnabled {
                    self.performAITrading()
                }
                
                // Update pattern analysis every 30 seconds
                if Date().timeIntervalSince(self.lastPatternUpdate) > 30 {
                    self.updatePatternAnalysis()
                }
            }
        }
        
        marketDataProvider.onError = { err in
            DispatchQueue.main.async {
                print("Market data error: \(err.localizedDescription)")
                self.showLogin = true
                self.marketData = "No data — check Zerodha credentials in Settings and use Test Connection."
            }
        }

        // If creds exist, connect to real WS; else show login UI
        let hasCreds = !Config.zerodhaAPIKey().isEmpty && !Config.zerodhaAccessToken().isEmpty
        if hasCreds {
            marketDataProvider.connect()
            marketDataProvider.subscribe(symbols: ["NIFTY"])
        } else {
            self.showQuickOrderSheet = false
            self.showLogin = true
        }

        // Load historical data for chart (real data only)
        historicalProvider.fetchCandles(symbol: "NIFTY") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.chartData = data
                    // Initialize pattern analysis with historical data
                    self.updatePatternAnalysis()
                case .failure(let error):
                    print("Error fetching historical data: \(error)")
                }
            }
        }
    }
    
    private func loadNews() {
        isLoading = true
        NewsAPIClient().fetchIndianMarketNews { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedArticles):
                    self.articles = fetchedArticles
                case .failure(let error):
                    print("Error fetching news: \(error)")
                }
            }
        }
    }
    
    private func startPatternAnalysis() {
        // Initialize pattern analysis timer
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updatePatternAnalysis()
            }
        }
    }
    
    private func updatePatternAnalysis() {
        guard !chartData.isEmpty else { return }
        
        // Update multi-timeframe analysis
        multiTimeframeAnalysis = patternEngine.analyzeMultiTimeframe(data: chartData)
        
        // Generate pattern alerts
        patternAlerts = patternEngine.generateAlerts(from: multiTimeframeAnalysis)
        
        // Find confluence patterns
        confluencePatterns = patternEngine.findConfluencePatterns(analysis: multiTimeframeAnalysis)
        
        // Update market regime
        marketRegime = patternEngine.determineMarketRegime(data: chartData)
        
        lastPatternUpdate = Date()
    }
    
    private func startAITrading() {
        // Initialize AI trading
        guard let currentData = chartData.last else { return }
        aiTrader.startTrading(
            marketData: currentData,
            news: [] // Empty news array for now
        )
    }
    
    private func performAITrading() {
        // Perform AI trading analysis and execution
        guard let currentData = chartData.last else { return }
        aiTrader.analyzeAndTrade(
            marketData: currentData,
            news: [] // Empty news array for now
        )
    }
    
    private func totalActivePatterns() -> Int {
        return multiTimeframeAnalysis.values.flatMap { $0 }.count
    }
    
    private func averageConfidence() -> Double {
        let allPatterns = multiTimeframeAnalysis.values.flatMap { $0 }
        guard !allPatterns.isEmpty else { return 0.0 }
        return allPatterns.map { $0.confidence }.reduce(0, +) / Double(allPatterns.count)
    }
    
    private func regimeColor(_ regime: PatternRecognitionEngine.MarketRegime) -> Color {
        switch regime {
        case .bullish: return .green
        case .bearish: return .red
        case .sideways: return .orange
        case .volatile: return .purple
        }
    }
    
    private func signalColor(_ signal: TechnicalAnalysisEngine.TradingSignal) -> Color {
        switch signal {
        case .buy, .strongBuy: return .green
        case .sell, .strongSell: return .red
        case .hold: return .gray
        }
    }
}

// MARK: - Supporting Views

struct MarketDataWidget: View {
    let marketData: String
    
    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(.blue)
            Text(marketData)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

struct QuickAccessButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct PerformanceWidget: View {
    let title: String
    let value: String
    let change: String
    let winRate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.purple)
            
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(change)
                    .font(.subheadline)
                    .foregroundColor(change.hasPrefix("+") ? .green : .red)
            }

            ProgressView(value: winRate / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct QuickActionButtons: View {
    let onQuickOrder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.purple)

            HStack(spacing: 15) {
                Button(action: onQuickOrder) {
                    Text("Quick Order")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }

                Button(action: {
                    print("Refresh button tapped")
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Missing Row Components

struct PatternAlertRow: View {
    let alert: PatternRecognitionEngine.PatternAlert
    
    var body: some View {
        HStack {
            Circle()
                .fill(urgencyColor(alert.urgency))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.pattern.pattern)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(alert.timeframe)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(alert.pattern.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(alert.pattern.signal.rawValue)
                    .font(.caption2)
                    .foregroundColor(signalColor(alert.pattern.signal))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func urgencyColor(_ urgency: PatternRecognitionEngine.AlertUrgency) -> Color {
        switch urgency {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    private func signalColor(_ signal: TechnicalAnalysisEngine.TradingSignal) -> Color {
        switch signal {
        case .buy, .strongBuy: return .green
        case .sell, .strongSell: return .red
        case .hold: return .gray
        }
    }
}

struct TimeframeAnalysisRow: View {
    let timeframe: String
    let patterns: [TechnicalAnalysisEngine.PatternResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(timeframe)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text("\(patterns.count) patterns")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let topPattern = patterns.first {
                HStack {
                    Text(topPattern.pattern)
                        .font(.caption2)
                    
                    Spacer()
                    
                    Text("\(Int(topPattern.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(signalColor(topPattern.signal))
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func signalColor(_ signal: TechnicalAnalysisEngine.TradingSignal) -> Color {
        switch signal {
        case .buy, .strongBuy: return .green
        case .sell, .strongSell: return .red
        case .hold: return .gray
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}