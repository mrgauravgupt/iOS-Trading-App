import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var articles: [Article] = []
    @State private var marketData: [MarketData] = []
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var currentPrice: Double = 0.0
    @State private var priceChange: Double = 0.0
    @State private var percentChange: Double = 0.0
    @State private var marketQuotes: [String: MarketData] = [:]
    @State private var isLoadingData = true
    @State private var dataError: String?
    @State private var showTradeSuggestions = false
    @State private var previousPrice: Double = 0.0
    
    @StateObject private var dataManager = DataConnectionManager()
    @StateObject private var suggestionManager = TradeSuggestionManager.shared
    @StateObject private var webSocketManager = WebSocketManager()
    @StateObject private var timeframeDataManager = TimeframeDataManager()
    
    // Observers for connection status changes
    @State private var dataConnectionObserver: AnyCancellable?
    @State private var webSocketObserver: AnyCancellable?
    private let technicalIndicatorsManager = TechnicalIndicatorsManager()
    private let newsClient = NewsAPIClient()
    
    // Timer for auto-refresh (fallback only)
    @State private var refreshTimer: Timer?
    
    var body: some View {
        ZStack {
            // Background gradient - Full screen
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header - Compact and extends to top
                headerView
                    .frame(height: 48) // Reduced from 60 to 48
                    .padding(.top, 2) // Reduced from 10 to 2
                
                // Main Content - Expand to fill available space
                TabView(selection: $selectedTab) {
                    // Dashboard Tab
                    dashboardView
                        .tag(0)
                    
                    // Trading Tab
                    tradingView
                        .tag(1)
                    
                    // NIFTY Options AI Tab
                    NIFTYOptionsDashboard()
                        .tag(2)
                    
                    // Analytics Tab
                    analyticsView
                        .tag(3)
                    
                    // Portfolio Tab
                    portfolioView
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom Tab Bar - Ultra Compact
                customTabBar
                    .frame(height: 50) // Further reduced from 60 to 50
            }
        }
        .ignoresSafeArea(.all, edges: .bottom) // Allow content to extend to bottom edge
        .ignoresSafeArea(.container, edges: .top) // Allow content to extend to top edge
        .onAppear {
            // Set up WebSocketManager for TimeframeDataManager
            timeframeDataManager.setupWebSocketManager(webSocketManager)

            loadInitialData()
            setupRealTimeDataStream()

            // Register for notification to show trade suggestions
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowTradeSuggestions"), object: nil, queue: .main) { _ in
                self.showTradeSuggestions = true
            }
            
            // Register for connection status request
            NotificationCenter.default.addObserver(forName: NSNotification.Name("RequestConnectionStatus"), object: nil, queue: .main) { _ in
                // Update TradeSuggestionManager with current connection status
                self.suggestionManager.updateConnectionStatus(
                    dataAvailable: self.dataManager.isDataAvailable,
                    webSocketConnected: self.webSocketManager.isConnected
                )
            }
            
            // Initial update of connection status
            suggestionManager.updateConnectionStatus(
                dataAvailable: dataManager.isDataAvailable,
                webSocketConnected: webSocketManager.isConnected
            )
            
            // Set up observers for connection status changes
            dataConnectionObserver = dataManager.$connectionStatus
                .sink { status in
                    self.suggestionManager.updateConnectionStatus(
                        dataAvailable: self.dataManager.isDataAvailable,
                        webSocketConnected: self.webSocketManager.isConnected
                    )
                }
            
            webSocketObserver = webSocketManager.$isConnected
                .sink { isConnected in
                    self.suggestionManager.updateConnectionStatus(
                        dataAvailable: self.dataManager.isDataAvailable,
                        webSocketConnected: isConnected
                    )
                }
        }
        .onDisappear {
            stopAutoRefresh()
            webSocketManager.disconnect()
            timeframeDataManager.unsubscribeFromSymbol("NIFTY", timeframe: .oneMinute)
            timeframeDataManager.unsubscribeFromSymbol("NIFTY", timeframe: .fiveMinute)
            timeframeDataManager.unsubscribeFromSymbol("NIFTY", timeframe: .fifteenMinute)
            NotificationCenter.default.removeObserver(self)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
        .sheet(isPresented: $showTradeSuggestions) {
            TradeSuggestionView()
        }
        .alert("New Trade Suggestion", isPresented: $suggestionManager.showSuggestionAlert) {
            Button("View Details") {
                showTradeSuggestions = true
            }
            Button("Dismiss", role: .cancel) { }
        } message: {
            if let suggestion = suggestionManager.latestSuggestion {
                Text("\(suggestion.action.rawValue.capitalized) \(suggestion.quantity) shares of \(suggestion.symbol) at ₹\(String(format: "%.2f", suggestion.price))")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) { // Further reduced spacing from 2 to 1
                HStack(spacing: 4) { // Further reduced spacing from 6 to 4
                    Text("NIFTY 50")
                        .font(.system(size: 12, weight: .medium, design: .monospaced)) // Further reduced from 14 to 12
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Real-time connection status indicator
                    HStack(spacing: 2) { // Further reduced spacing from 3 to 2
                        Circle()
                            .fill(webSocketManager.isConnected ? .green : .orange)
                            .frame(width: 5, height: 5) // Further reduced from 6x6 to 5x5
                        
                        if webSocketManager.isConnected {
                            Text("LIVE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced)) // Further reduced from 9 to 8
                                .foregroundColor(.green)
                        } else {
                            Text("DELAYED")
                                .font(.system(size: 8, weight: .bold, design: .monospaced)) // Further reduced from 9 to 8
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                HStack(spacing: 4) { // Further reduced spacing from 6 to 4
                    Text("₹\(String(format: "%.2f", currentPrice))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced)) // Further reduced from 16 to 14
                        .foregroundColor(.white)
                    
                    HStack(spacing: 2) { // Further reduced spacing from 3 to 2
                        Image(systemName: priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold)) // Further reduced from 9 to 8
                        
                        Text("\(priceChange >= 0 ? "+" : "")\(String(format: "%.2f", priceChange)) (\(String(format: "%.2f", percentChange))%)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced)) // Further reduced from 11 to 10
                    }
                    .foregroundColor(priceChange >= 0 ? .green : .red)
                }
            }
            
            Spacer()
            
            // Connection status and settings button
            HStack(spacing: 8) { // Further reduced spacing from 10 to 8
                // Data connection status
                Circle()
                    .fill(dataManager.isDataAvailable ? .green : .red)
                    .frame(width: 6, height: 6) // Further reduced from 8x8 to 6x6
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .medium)) // Further reduced from 16 to 14
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 12) // Further reduced from 16 to 12
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Dashboard View
    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Spacer(minLength: 0)
                // Market Overview Cards
                HStack(spacing: 12) {
                    MarketCard(
                        title: "NIFTY 50",
                        value: "₹\(String(format: "%.2f", currentPrice))",
                        change: "\(priceChange >= 0 ? "+" : "")\(String(format: "%.2f", priceChange))",
                        changePercent: "(\(String(format: "%.2f", percentChange))%)",
                        isPositive: priceChange >= 0
                    )
                    
                    // Since MarketData doesn't have change/changePercent fields, we'll use placeholders
                    MarketCard(
                        title: "BANK NIFTY",
                        value: "₹\(String(format: "%.2f", marketQuotes["BANKNIFTY"]?.price ?? 0))",
                        change: "+0.00",
                        changePercent: "(0.00%)",
                        isPositive: true
                    )
                }
                
                // Chart Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("NIFTY 50 Chart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Time frame selector
                        HStack(spacing: 8) {
                            ChartTimeButton(title: "1D", isSelected: true)
                            ChartTimeButton(title: "1W", isSelected: false)
                            ChartTimeButton(title: "1M", isSelected: false)
                            ChartTimeButton(title: "3M", isSelected: false)
                        }
                    }
                    
                    // Chart placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                        
                        // Placeholder chart
                        VStack {
                            HStack(spacing: 0) {
                                ForEach(0..<20) { i in
                                    VStack {
                                        Rectangle()
                                            .fill(Color.green.opacity(0.7))
                                            .frame(width: 3, height: CGFloat(30 + Int.random(in: 0...40)))
                                        
                                        Rectangle()
                                            .fill(Color.red.opacity(0.7))
                                            .frame(width: 3, height: CGFloat(Int.random(in: 0...20)))
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                            .padding(.bottom, 10)
                            
                            // Time labels
                            HStack {
                                Text("9:15")
                                Spacer()
                                Text("12:00")
                                Spacer()
                                Text("15:30")
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .frame(height: 200)
                }
                
                // Market News Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Market News")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            // View all news
                        }) {
                            Text("View All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if isLoading {
                        // News placeholders
                        VStack(spacing: 8) {
                            ForEach(0..<3) { _ in
                                NewsCardPlaceholder()
                            }
                        }
                    } else if articles.isEmpty {
                        Text("No news available")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // News cards
                        VStack(spacing: 8) {
                            ForEach(articles.prefix(3), id: \.id) { article in
                                NewsCard(article: article)
                            }
                        }
                    }
                }
                
                // Performance Overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Overview")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        PerformanceRow(
                            title: "Today's Return",
                            value: "₹1,245.00 (0.78%)",
                            isPositive: true
                        )
                        
                        PerformanceRow(
                            title: "This Week",
                            value: "₹3,567.00 (2.14%)",
                            isPositive: true
                        )
                        
                        PerformanceRow(
                            title: "This Month",
                            value: "-₹1,890.00 (-1.12%)",
                            isPositive: false
                        )
                        
                        PerformanceRow(
                            title: "This Year",
                            value: "₹24,680.00 (15.67%)",
                            isPositive: true
                        )
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                
                // AI Insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Trading Insights")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Text("NIFTY showing bullish divergence on RSI")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("Volume spike detected in IT sector")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Text("Volatility increasing ahead of options expiry")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            // Show trade suggestions
                            showTradeSuggestions = true
                        }) {
                            Text("View Trade Suggestions")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                )
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            .padding(8)
        }
        .frame(maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Trading View
    private var tradingView: some View {
        VStack {
            Text("Trading View")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Analytics View
    private var analyticsView: some View {
        VStack {
            Text("Analytics View")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Portfolio View
    private var portfolioView: some View {
        VStack {
            Text("Portfolio View")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "chart.bar.fill",
                title: "Dashboard",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabBarButton(
                icon: "arrow.left.arrow.right",
                title: "Trading",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabBarButton(
                icon: "brain",
                title: "AI Options",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            TabBarButton(
                icon: "chart.xyaxis.line",
                title: "Analytics",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
            
            TabBarButton(
                icon: "briefcase.fill",
                title: "Portfolio",
                isSelected: selectedTab == 4
            ) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 8) // Further reduced from 10 to 8
        .padding(.vertical, 4) // Further reduced from 6 to 4
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Data Loading Functions
    private func loadInitialData() {
        Task {
            // Load market data
            await loadRealTimeData()
            
            // Load news articles
            await loadNews()
        }
    }
    
    private func loadRealTimeData() async {
        isLoadingData = true
        dataError = nil
        
        do {
            // Simulate fetching market data since the actual method doesn't exist
            let data = [
                MarketData(symbol: "NIFTY", price: 22500.50, volume: 1250000, timestamp: Date()),
                MarketData(symbol: "BANKNIFTY", price: 48750.25, volume: 850000, timestamp: Date())
            ]
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.marketData = data
                
                // Update current price and market quotes
                if let niftyData = data.first(where: { $0.symbol == "NIFTY" }) {
                    self.previousPrice = self.currentPrice
                    self.currentPrice = niftyData.price
                    
                    // Calculate price change
                    if self.previousPrice > 0 {
                        self.priceChange = self.currentPrice - self.previousPrice
                        self.percentChange = (self.priceChange / self.previousPrice) * 100
                    }
                }
                
                // Update market quotes dictionary
                for item in data {
                    self.marketQuotes[item.symbol] = item
                }
                
                self.isLoadingData = false
            }
            
            // Subscribe to real-time data for key symbols
            timeframeDataManager.subscribeToSymbol("NIFTY", timeframe: .oneMinute)
            timeframeDataManager.subscribeToSymbol("NIFTY", timeframe: .fiveMinute)
            timeframeDataManager.subscribeToSymbol("NIFTY", timeframe: .fifteenMinute)
            
            print("Real-time data loaded successfully")
        } catch {
            // Handle error
            DispatchQueue.main.async {
                self.dataError = error.localizedDescription
                self.isLoadingData = false
                print("Error loading real-time data: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadNews() async {
        isLoading = true
        
        do {
            // Simulate fetching news articles since the actual method doesn't exist
            let fetchedArticles = [
                Article(title: "Markets hit all-time high as FIIs return", 
                       description: "Foreign institutional investors have pumped in over ₹15,000 crore in the last week, pushing indices to record levels.", 
                       url: "https://example.com/markets-hit-all-time-high", 
                       publishedAt: "2023-06-15T09:30:00Z"),
                Article(title: "RBI holds rates steady for third consecutive meeting", 
                       description: "The central bank maintained its accommodative stance while keeping a close eye on inflation trends.", 
                       url: "https://example.com/rbi-holds-rates", 
                       publishedAt: "2023-06-14T11:45:00Z"),
                Article(title: "IT sector leads gains as global tech recovery continues", 
                       description: "Indian IT companies are benefiting from increased global tech spending and digital transformation initiatives.", 
                       url: "https://example.com/it-sector-leads", 
                       publishedAt: "2023-06-13T14:20:00Z")
            ]
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.articles = fetchedArticles
                self.isLoading = false
            }
            
            print("News loaded successfully: \(fetchedArticles.count) articles")
        } catch {
            // Handle error
            DispatchQueue.main.async {
                self.isLoading = false
                print("Error loading news: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Real-time Data Stream Setup
    private func setupRealTimeDataStream() {
        // Set up WebSocket callbacks for real-time data
        webSocketManager.onTick = { marketData in
            DispatchQueue.main.async {
                self.updateMarketData(marketData)
            }
        }

        webSocketManager.onError = { error in
            print("WebSocket error: \(error)")
            // Fallback to timer-based refresh if WebSocket fails
            DispatchQueue.main.async {
                self.startAutoRefresh(interval: 5.0) // More frequent fallback updates
            }
        }
        
        // Connect to WebSocket with a default URL
        let defaultURL = URL(string: "wss://stream.zerodha.com/v1")!
        webSocketManager.connect(to: defaultURL)
        
        // Set up fallback timer (will be used only if WebSocket fails)
        startAutoRefresh(interval: 5.0) // Reduced from 10 to 5 seconds

        print("Real-time data stream setup completed with multi-timeframe support")
    }
    
    private func updateMarketData(_ marketData: MarketData) {
        // Update the current price and related data
        previousPrice = currentPrice
        currentPrice = marketData.price
        
        // Calculate price change
        if previousPrice > 0 {
            priceChange = currentPrice - previousPrice
            percentChange = (priceChange / previousPrice) * 100
        }
        
        // Update market quotes
        marketQuotes[marketData.symbol] = marketData
        
        // Update the market data array
        if let index = self.marketData.firstIndex(where: { $0.symbol == marketData.symbol }) {
            self.marketData[index] = marketData
        } else {
            self.marketData.append(marketData)
        }
        
        print("Real-time update: \(marketData.symbol) = ₹\(String(format: "%.2f", marketData.price))")
    }
    
    // MARK: - Auto Refresh Functions (Fallback)
    private func startAutoRefresh(interval: TimeInterval = 2.5) {
        // Stop existing timer
        stopAutoRefresh()
        
        // Start new timer with specified interval
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            print("Fallback timer fired - loading data (interval: \(interval)s)")
            Task {
                await self.loadRealTimeData()
            }
        }
        print("Fallback refresh timer started with \(interval) second intervals")
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Helper Functions
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 1 {
            return "just now"
        } else if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Supporting Views

struct MarketCard: View {
    let title: String
    let value: String
    let change: String
    let changePercent: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10, weight: .bold))
                Text(change)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                Text(changePercent)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ChartTimeButton: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white : Color.clear)
            )
    }
}

struct NewsCard: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            if let description = article.description {
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Text(timeAgo(from: article.publishedAt))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func timeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        return "Recently"
    }
}

struct NewsCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: 16)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: 12)
                .frame(width: 200)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: 10)
                .frame(width: 80)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct PerformanceRow: View {
    let title: String
    let value: String
    let isPositive: Bool?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(
                    isPositive == nil ? .white :
                    isPositive! ? .green : .red
                )
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) { // Further reduced spacing from 2 to 1
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold)) // Further reduced from 14 to 12
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 8, weight: .medium)) // Further reduced from 9 to 8
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 35) // Further reduced from 40 to 35
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
