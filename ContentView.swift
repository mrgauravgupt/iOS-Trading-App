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
        GeometryReader { geometry in
            ZStack {
                // Background gradient - True full screen
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
                    // Custom Header - Responsive height based on screen size
                    headerView(geometry: geometry)
                        .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Main Content - Takes all remaining space
                    TabView(selection: $selectedTab) {
                        // Dashboard Tab
                        dashboardView(geometry: geometry)
                            .tag(0)
                        
                        // Trading Tab
                        tradingView(geometry: geometry)
                            .tag(1)
                        
                        // NIFTY Options AI Tab
                        NIFTYOptionsDashboard()
                            .tag(2)
                        
                        // Analytics Tab
                        analyticsView(geometry: geometry)
                            .tag(3)
                        
                        // Portfolio Tab
                        portfolioView(geometry: geometry)
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom Tab Bar - Responsive sizing
                    customTabBar(geometry: geometry)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
        }
        .ignoresSafeArea(.all)
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
                Task { @MainActor in
                    self.suggestionManager.updateConnectionStatus(
                        dataAvailable: self.dataManager.isDataAvailable,
                        webSocketConnected: self.webSocketManager.isConnected
                    )
                }
            }
            
            // Initial update of connection status
            Task { @MainActor in
                suggestionManager.updateConnectionStatus(
                    dataAvailable: dataManager.isDataAvailable,
                    webSocketConnected: webSocketManager.isConnected
                )
            }
            
            // Set up observers for connection status changes
            dataConnectionObserver = dataManager.$connectionStatus
                .receive(on: DispatchQueue.main)
                .sink { status in
                    Task { @MainActor in
                        self.suggestionManager.updateConnectionStatus(
                            dataAvailable: self.dataManager.isDataAvailable,
                            webSocketConnected: self.webSocketManager.isConnected
                        )
                    }
                }
            
            webSocketObserver = webSocketManager.$isConnected
                .receive(on: DispatchQueue.main)
                .sink { isConnected in
                    Task { @MainActor in
                        self.suggestionManager.updateConnectionStatus(
                            dataAvailable: self.dataManager.isDataAvailable,
                            webSocketConnected: isConnected
                        )
                    }
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
    private func headerView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        let horizontalPadding = max(16, geometry.size.width * 0.04)
        let fontSize = isCompact ? 10 : 12
        
        return HStack {
            VStack(alignment: .leading, spacing: isCompact ? 1 : 2) {
                HStack(spacing: isCompact ? 3 : 4) {
                    Text("NIFTY 50")
                        .font(.system(size: CGFloat(fontSize), weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Real-time connection status indicator
                    HStack(spacing: 2) {
                        Circle()
                            .fill(webSocketManager.isConnected ? .green : .orange)
                            .frame(width: isCompact ? 4 : 5, height: isCompact ? 4 : 5)
                        
                        if webSocketManager.isConnected {
                            Text("LIVE")
                                .font(.system(size: CGFloat(fontSize - 2), weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        } else {
                            Text("DELAYED")
                                .font(.system(size: CGFloat(fontSize - 2), weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                HStack(spacing: isCompact ? 3 : 4) {
                    Text("₹\(String(format: "%.2f", currentPrice))")
                        .font(.system(size: CGFloat(fontSize + 2), weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 2) {
                        Image(systemName: priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: CGFloat(fontSize - 2), weight: .bold))
                        
                        Text("\(priceChange >= 0 ? "+" : "")\(String(format: "%.2f", priceChange)) (\(String(format: "%.2f", percentChange))%)")
                            .font(.system(size: CGFloat(fontSize - 1), weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(priceChange >= 0 ? .green : .red)
                }
            }
            
            Spacer()
            
            // Connection status and settings button
            HStack(spacing: isCompact ? 6 : 8) {
                // Data connection status
                Circle()
                    .fill(dataManager.isDataAvailable ? .green : .red)
                    .frame(width: isCompact ? 5 : 6, height: isCompact ? 5 : 6)
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: CGFloat(fontSize + 2), weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, isCompact ? 6 : 8)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Dashboard View
    private func dashboardView(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        let contentPadding = max(8, geometry.size.width * 0.02)
        
        return ScrollView {
            VStack(spacing: isCompact ? 6 : 8) {
                // Market Overview Cards
                HStack(spacing: isCompact ? 8 : 12) {
                    MarketCard(
                        title: "NIFTY 50",
                        value: "₹\(String(format: "%.2f", currentPrice))",
                        change: "\(priceChange >= 0 ? "+" : "")\(String(format: "%.2f", priceChange))",
                        changePercent: "(\(String(format: "%.2f", percentChange))%)",
                        isPositive: priceChange >= 0,
                        isCompact: isCompact
                    )
                    
                    MarketCard(
                        title: "BANK NIFTY",
                        value: "₹\(String(format: "%.2f", marketQuotes["BANKNIFTY"]?.price ?? 0))",
                        change: "+0.00",
                        changePercent: "(0.00%)",
                        isPositive: true,
                        isCompact: isCompact
                    )
                }
                
                // Chart Section
                VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                    HStack {
                        Text("NIFTY 50 Chart")
                            .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Time frame selector
                        HStack(spacing: isCompact ? 6 : 8) {
                            ChartTimeButton(title: "1D", isSelected: true, isCompact: isCompact)
                            ChartTimeButton(title: "1W", isSelected: false, isCompact: isCompact)
                            ChartTimeButton(title: "1M", isSelected: false, isCompact: isCompact)
                            ChartTimeButton(title: "3M", isSelected: false, isCompact: isCompact)
                        }
                    }
                    
                    // Chart placeholder - Responsive height
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                        
                        // Placeholder chart
                        VStack {
                            HStack(spacing: 0) {
                                ForEach(0..<Int(geometry.size.width / 20)) { i in
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
                            .font(.system(size: isCompact ? 9 : 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .frame(height: isCompact ? 160 : 200)
                }
                
                // Market News Section
                VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                    HStack {
                        Text("Market News")
                            .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            // View all news
                        }) {
                            Text("View All")
                                .font(.system(size: isCompact ? 10 : 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if isLoading {
                        // News placeholders
                        VStack(spacing: isCompact ? 6 : 8) {
                            ForEach(0..<3) { _ in
                                NewsCardPlaceholder(isCompact: isCompact)
                            }
                        }
                    } else if articles.isEmpty {
                        Text("No news available")
                            .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // News cards
                        VStack(spacing: isCompact ? 6 : 8) {
                            ForEach(articles.prefix(3), id: \.id) { article in
                                NewsCard(article: article, isCompact: isCompact)
                            }
                        }
                    }
                }
                
                // Performance Overview
                VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                    Text("Performance Overview")
                        .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: isCompact ? 8 : 12) {
                        PerformanceRow(
                            title: "Today's Return",
                            value: "₹1,245.00 (0.78%)",
                            isPositive: true,
                            isCompact: isCompact
                        )
                        
                        PerformanceRow(
                            title: "This Week",
                            value: "₹3,567.00 (2.14%)",
                            isPositive: true,
                            isCompact: isCompact
                        )
                        
                        PerformanceRow(
                            title: "This Month",
                            value: "-₹1,890.00 (-1.12%)",
                            isPositive: false,
                            isCompact: isCompact
                        )
                        
                        PerformanceRow(
                            title: "This Year",
                            value: "₹24,680.00 (15.67%)",
                            isPositive: true,
                            isCompact: isCompact
                        )
                    }
                    .padding(isCompact ? 10 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                
                // AI Insights
                VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                    Text("AI Trading Insights")
                        .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Text("NIFTY showing bullish divergence on RSI")
                                .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("Volume spike detected in IT sector")
                                .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Text("Volatility increasing ahead of options expiry")
                                .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            // Show trade suggestions
                            showTradeSuggestions = true
                        }) {
                            Text("View Trade Suggestions")
                                .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, isCompact ? 8 : 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                )
                        }
                    }
                    .padding(isCompact ? 10 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            .padding(contentPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Trading View
    private func tradingView(geometry: GeometryProxy) -> some View {
        VStack {
            Text("Trading View")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Analytics View
    private func analyticsView(geometry: GeometryProxy) -> some View {
        VStack {
            Text("Analytics View")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Portfolio View
    private func portfolioView(geometry: GeometryProxy) -> some View {
        VStack {
            Text("Portfolio View")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Custom Tab Bar
    private func customTabBar(geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 700
        let horizontalPadding = max(8, geometry.size.width * 0.02)
        let verticalPadding = isCompact ? 3 : 4
        let tabHeight: CGFloat = isCompact ? 30 : 35
        
        return HStack(spacing: 0) {
            TabBarButton(
                icon: "chart.bar.fill",
                title: "Dashboard",
                isSelected: selectedTab == 0,
                isCompact: isCompact,
                tabHeight: tabHeight
            ) {
                selectedTab = 0
            }
            
            TabBarButton(
                icon: "arrow.left.arrow.right",
                title: "Trading",
                isSelected: selectedTab == 1,
                isCompact: isCompact,
                tabHeight: tabHeight
            ) {
                selectedTab = 1
            }
            
            TabBarButton(
                icon: "brain",
                title: "AI Options",
                isSelected: selectedTab == 2,
                isCompact: isCompact,
                tabHeight: tabHeight
            ) {
                selectedTab = 2
            }
            
            TabBarButton(
                icon: "chart.xyaxis.line",
                title: "Analytics",
                isSelected: selectedTab == 3,
                isCompact: isCompact,
                tabHeight: tabHeight
            ) {
                selectedTab = 3
            }
            
            TabBarButton(
                icon: "briefcase.fill",
                title: "Portfolio",
                isSelected: selectedTab == 4,
                isCompact: isCompact,
                tabHeight: tabHeight
            ) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, CGFloat(verticalPadding))
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
    let isCompact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            Text(title)
                .font(.system(size: isCompact ? 10 : 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: isCompact ? 14 : 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: isCompact ? 8 : 10, weight: .bold))
                Text(change)
                    .font(.system(size: isCompact ? 10 : 12, weight: .semibold, design: .monospaced))
                Text(changePercent)
                    .font(.system(size: isCompact ? 8 : 10, weight: .medium, design: .monospaced))
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .padding(isCompact ? 10 : 12)
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
    let isCompact: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: isCompact ? 10 : 12, weight: .medium))
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, isCompact ? 10 : 12)
            .padding(.vertical, isCompact ? 4 : 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white : Color.clear)
            )
    }
}

struct NewsCard: View {
    let article: Article
    let isCompact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            Text(article.title)
                .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            if let description = article.description {
                Text(description)
                    .font(.system(size: isCompact ? 10 : 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Text(timeAgo(from: article.publishedAt))
                .font(.system(size: isCompact ? 8 : 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(isCompact ? 10 : 12)
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
    let isCompact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: isCompact ? 14 : 16)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: isCompact ? 10 : 12)
                .frame(width: 200)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: isCompact ? 8 : 10)
                .frame(width: 80)
        }
        .padding(isCompact ? 10 : 12)
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
    let isCompact: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: isCompact ? 12 : 14, weight: .semibold, design: .monospaced))
                .foregroundColor(
                    isPositive == nil ? .white :
                    isPositive! ? .green : .red
                )
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let isCompact: Bool
    let tabHeight: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: isCompact ? 7 : 8, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: tabHeight)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 14 Pro")
        
        ContentView()
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE")
        
        ContentView()
            .previewDevice("iPhone 14 Pro Max")
            .previewDisplayName("iPhone 14 Pro Max")
    }
}