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

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
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

                    // AI Trading Status Widget
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

                    // Real-time Pattern Alerts
                    if !patternAlerts.isEmpty {
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

                    // Quick Access Navigation
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

                    // Multi-timeframe Analysis
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

                    // Enhanced Market Intelligence
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

                    // Quick actions
                    SectionCard("Quick Actions") {
                        QuickActionButtons(onQuickOrder: { showQuickOrderSheet = true })
                    }

                    // News Feed
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

                    Spacer(minLength: 16)
                }
                .padding()
            }
            .background(Color.kiteBackground.ignoresSafeArea())
            .sheet(isPresented: $showQuickOrderSheet) {
                // Minimal quick order sheet forwarding user to Paper Trading
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
            .onAppear {
                loadNews()
                startPatternAnalysis()
                
                marketDataProvider.onTick = { tick in
                    DispatchQueue.main.async {
                        self.marketData = "\(tick.symbol) ₹\(String(format: "%.2f", tick.price))"
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
                            self.initializePatternAnalysis()
                        case .failure(let error):
                            self.chartData = []
                            print("Historical fetch error: \(error.localizedDescription)")
                            self.marketData = "Historical fetch failed — verify access token via Settings › Test Connection."
                        }
                    }
                }
            }
            .sheet(isPresented: $showLogin) {
                // Present login when creds missing
                NavigationView {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.blue)
                        Text("Zerodha Login Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Go to Settings to enter API Key & Secret, then tap 'Login with Zerodha'. The access token will be saved automatically.")
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
                }
                .presentationDetents([.medium])
            }
            .tabItem {
                Image(systemName: "house")
                Text("Dashboard")
            }
            .tag(0)
            
            // AI Control Center Tab
            AIControlCenterView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Control")
                }
                .tag(1)
            
            // Analytics Tab
            PerformanceAnalyticsView()
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
            RiskManagementDashboard()
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
            PatternScannerView(
                multiTimeframeAnalysis: multiTimeframeAnalysis,
                patternAlerts: patternAlerts,
                confluencePatterns: confluencePatterns
            )
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func initializePatternAnalysis() {
        guard !chartData.isEmpty else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let analysisResult = self.patternEngine.analyzeWithConfluence(marketData: self.chartData)
            let regime = self.patternEngine.detectMarketRegime(marketData: self.chartData)
            let alerts = self.patternEngine.scanForPatternAlerts(marketData: self.chartData)
            
            DispatchQueue.main.async {
                self.multiTimeframeAnalysis = analysisResult.patterns
                self.confluencePatterns = analysisResult.confluence
                self.marketRegime = regime
                self.patternAlerts = alerts
                self.lastPatternUpdate = Date()
            }
        }
    }
    
    private func updatePatternAnalysis() {
        guard !chartData.isEmpty else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let analysisResult = self.patternEngine.analyzeWithConfluence(marketData: self.chartData)
            let regime = self.patternEngine.detectMarketRegime(marketData: self.chartData)
            let alerts = self.patternEngine.scanForPatternAlerts(marketData: self.chartData)
            
            DispatchQueue.main.async {
                self.multiTimeframeAnalysis = analysisResult.patterns
                self.confluencePatterns = analysisResult.confluence
                self.marketRegime = regime
                self.patternAlerts = alerts
                self.lastPatternUpdate = Date()
            }
        }
    }
    
    private func startAITrading() {
        guard !chartData.isEmpty else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Initialize AI trading with current market data
            self.aiTrader.executeAITrade(marketData: self.chartData.last!, news: self.articles)
        }
    }
    
    private func performAITrading() {
        guard let latestData = chartData.last else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.aiTrader.executeAITrade(marketData: latestData, news: self.articles)
        }
    }
    
    private func regimeColor(_ regime: PatternRecognitionEngine.MarketRegime) -> Color {
        switch regime {
        case .trending(.bullish): return .green
        case .trending(.bearish): return .red
        case .sideways: return .blue
        case .volatile: return .orange
        }
    }
    
    private func signalColor(_ signal: TechnicalAnalysisEngine.TradingSignal) -> Color {
        switch signal {
        case .buy, .strongBuy: return .green
        case .sell, .strongSell: return .red
        case .hold: return .gray
        }
    }
    
    private func totalActivePatterns() -> Int {
        return multiTimeframeAnalysis.values.flatMap { $0 }.count
    }
    
    private func averageConfidence() -> Double {
        let allPatterns = multiTimeframeAnalysis.values.flatMap { $0 }
        guard !allPatterns.isEmpty else { return 0 }
        return allPatterns.map { $0.confidence }.reduce(0, +) / Double(allPatterns.count)
    }
}

// MARK: - Supporting Views

struct QuickAccessButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MarketDataWidget: View {
    let marketData: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live Market Data")
                .font(.headline)
                .foregroundColor(.blue)

            if marketData.isEmpty || marketData == "No data" {
                Text("No live data available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Text(marketData)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            HStack {
                Text("Last Updated:")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(Date().formatted())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PortfolioSummaryCard: View {
    @State private var totalValue = 100000.0
    @State private var dailyPL = 250.0
    @State private var winRate = 65.0

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Portfolio Summary")
                .font(.headline)
                .foregroundColor(.green)

            HStack {
                VStack(alignment: .leading) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(totalValue, specifier: "%.2f")")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Daily P&L")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(dailyPL, specifier: "%.2f")")
                        .font(.title2)
                        .foregroundColor(dailyPL >= 0 ? .green : .red)
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(winRate, specifier: "%.1f")%")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Active Trades")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("5")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
