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
    
    // Simulated market data for other indices
    @State private var sensexPrice: Double = 81500.0
    @State private var sensexChange: Double = 0.0
    @State private var bankNiftyPrice: Double = 52000.0
    @State private var bankNiftyChange: Double = 0.0
    @State private var niftyITPrice: Double = 42000.0
    @State private var niftyITChange: Double = 0.0
    
    @StateObject private var dataManager = DataConnectionManager()
    @StateObject private var suggestionManager = TradeSuggestionManager.shared
    @StateObject private var webSocketManager = WebSocketManager()
    private let newsClient = NewsAPIClient()
    
    // Timer for auto-refresh (fallback only)
    @State private var refreshTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
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
                    // Custom Header
                    headerView
                        .frame(height: 100)
                    
                    // Main Content - Use available space efficiently
                    TabView(selection: $selectedTab) {
                        // Dashboard Tab
                        dashboardView
                            .frame(maxHeight: geometry.size.height - 180) // Account for header and tab bar
                            .tag(0)
                        
                        // Trading Tab
                        tradingView
                            .frame(maxHeight: geometry.size.height - 180)
                            .tag(1)
                        
                        // AI Control Tab
                        aiControlView
                            .frame(maxHeight: geometry.size.height - 180)
                            .tag(2)
                        
                        // Analytics Tab
                        analyticsView
                            .frame(maxHeight: geometry.size.height - 180)
                            .tag(3)
                        
                        // Portfolio Tab
                        portfolioView
                            .frame(maxHeight: geometry.size.height - 180)
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Custom Tab Bar
                    customTabBar
                        .frame(height: 80)
                }
            }
        }
        .onAppear {
            loadInitialData()
            setupRealTimeDataStream()
            
            // Register for notification to show trade suggestions
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowTradeSuggestions"), object: nil, queue: .main) { _ in
                showTradeSuggestions = true
            }
        }
        .onDisappear {
            stopAutoRefresh()
            webSocketManager.disconnect()
            NotificationCenter.default.removeObserver(self)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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
                Text("\(suggestion.action.rawValue.capitalized) \(suggestion.quantity) shares of \(suggestion.symbol) at ₹\(suggestion.price, specifier: "%.2f")")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("NIFTY 50")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Real-time connection status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(webSocketManager.isConnected ? .green : .orange)
                            .frame(width: 8, height: 8)
                        
                        if webSocketManager.isConnected {
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("FALLBACK")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if dataManager.isDataAvailable && currentPrice > 0 {
                    HStack(spacing: 8) {
                        Text("₹\(String(format: "%.2f", currentPrice))")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Image(systemName: priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(priceChange >= 0 ? "+" : "")\(String(format: "%.2f", priceChange))")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            Text("(\(priceChange >= 0 ? "+" : "")\(String(format: "%.2f", percentChange))%)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(priceChange >= 0 ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((priceChange >= 0 ? Color.green : Color.red).opacity(0.2))
                        )
                    }
                    
                    // Last update time for real-time data
                    if let lastUpdate = webSocketManager.lastUpdateTime {
                        Text("Updated \(timeAgoString(from: lastUpdate))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else if isLoadingData {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                        Text("Loading...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Unavailable")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                        Text(dataManager.errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Dashboard View
    private var dashboardView: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    // Market Overview Cards - Compact
                    marketOverviewSection
                    
                    // Quick Actions - Compact
                    quickActionsSection
                    
                    // Live Chart - Reduced height
                    liveChartSection
                    
                    // Recent News - Compact
                    newsSection
                    
                    // Performance Metrics - Compact
                    performanceSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20) // Reduced bottom padding
            }
        }
    }
    
    // MARK: - Market Overview Section
    private var marketOverviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Market Overview")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("Live")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                    )
            }
            
            if dataManager.isDataAvailable {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    // NIFTY 50 with real/mock data
                    MarketCard(
                        title: "NIFTY 50", 
                        value: currentPrice > 0 ? String(format: "%.2f", currentPrice) : "Loading...",
                        change: currentPrice > 0 ? String(format: "%+.2f", priceChange) : "---",
                        changePercent: currentPrice > 0 ? String(format: "%+.2f%%", percentChange) : "---",
                        isPositive: priceChange >= 0
                    )
                    
                    // Other indices - show simulated data for demo
                    MarketCard(
                        title: "SENSEX", 
                        value: String(format: "%.2f", sensexPrice),
                        change: String(format: "%+.2f", sensexChange),
                        changePercent: String(format: "%+.2f%%", (sensexChange / sensexPrice) * 100),
                        isPositive: sensexChange >= 0
                    )
                    
                    MarketCard(
                        title: "BANK NIFTY", 
                        value: String(format: "%.2f", bankNiftyPrice),
                        change: String(format: "%+.2f", bankNiftyChange),
                        changePercent: String(format: "%+.2f%%", (bankNiftyChange / bankNiftyPrice) * 100),
                        isPositive: bankNiftyChange >= 0
                    )
                    
                    MarketCard(
                        title: "NIFTY IT", 
                        value: String(format: "%.2f", niftyITPrice),
                        change: String(format: "%+.2f", niftyITChange),
                        changePercent: String(format: "%+.2f%%", (niftyITChange / niftyITPrice) * 100),
                        isPositive: niftyITChange >= 0
                    )
                }
            } else {
                DataErrorView(message: dataManager.errorMessage) {
                    Task {
                        await loadRealTimeData()
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickActionButton(title: "Buy", icon: "chart.line.uptrend.xyaxis", color: .green) {
                    selectedTab = 1
                }
                
                QuickActionButton(title: "Sell", icon: "chart.line.downtrend.xyaxis", color: .red) {
                    selectedTab = 1
                }
                
                QuickActionButton(title: "AI Trade", icon: "brain.head.profile", color: .blue) {
                    selectedTab = 2
                }
                
                QuickActionButton(title: "Suggestions", icon: "lightbulb.fill", color: .orange) {
                    // showTradeSuggestions = true
                }
            }
        }
    }
    
    // MARK: - Live Chart Section
    private var liveChartSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Live Chart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 8) {
                    ChartTimeButton(title: "1D", isSelected: true)
                    ChartTimeButton(title: "1W", isSelected: false)
                    ChartTimeButton(title: "1M", isSelected: false)
                    ChartTimeButton(title: "1Y", isSelected: false)
                }
            }
            
            // Placeholder for chart - Reduced height
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(height: 150) // Reduced from 200 to 150
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 30)) // Reduced icon size
                            .foregroundColor(.white.opacity(0.3))
                        Text("Live Chart")
                            .font(.system(size: 14, weight: .medium)) // Reduced font size
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
        }
    }
    
    // MARK: - News Section
    private var newsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Market News")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button("View All") {
                    // Navigate to news view
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            
            if articles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No news available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Check your internet connection or try again later")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            } else {
                ForEach(articles.prefix(2), id: \.id) { article in // Reduced from 3 to 2 articles
                    NewsCard(article: article)
                }
            }
        }
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Performance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 8) {
                if dataManager.isDataAvailable {
                    PerformanceRow(title: "Today's P&L", value: "₹0.00", isPositive: nil)
                    PerformanceRow(title: "Total P&L", value: "₹0.00", isPositive: nil)
                    PerformanceRow(title: "Win Rate", value: "0.0%", isPositive: nil)
                    PerformanceRow(title: "Active Positions", value: "0", isPositive: nil)
                } else {
                    VStack(spacing: 8) {
                        Text("Performance data unavailable")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Connect to Zerodha to view your portfolio performance")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Trading View
    private var tradingView: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Text("Trading Terminal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                // Trading interface placeholder - Use available space
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(maxHeight: geometry.size.height - 100) // Use available height
                    .overlay(
                        VStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Trading Terminal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    )
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - AI Control View
    private var aiControlView: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Text("AI Trading Control")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                // AI control interface placeholder - Use available space
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(maxHeight: geometry.size.height - 100)
                    .overlay(
                        VStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.blue.opacity(0.7))
                            Text("AI Control Center")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    )
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Analytics View
    private var analyticsView: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Text("Analytics & Insights")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                // Analytics interface placeholder - Use available space
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(maxHeight: geometry.size.height - 100)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.purple.opacity(0.7))
                            Text("Analytics Dashboard")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    )
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Portfolio View
    private var portfolioView: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Text("Portfolio")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                // Portfolio interface placeholder - Use available space
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(maxHeight: geometry.size.height - 100)
                    .overlay(
                        VStack {
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange.opacity(0.7))
                            Text("Portfolio Overview")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    )
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house.fill", title: "Dashboard", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabBarButton(icon: "chart.line.uptrend.xyaxis", title: "Trading", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabBarButton(icon: "brain.head.profile", title: "AI", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            
            TabBarButton(icon: "chart.bar.xaxis", title: "Analytics", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            
            TabBarButton(icon: "briefcase.fill", title: "Portfolio", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .blur(radius: 10)
        )
    }
    
    // MARK: - Helper Functions
    private func updateSimulatedMarketData() {
        // Update SENSEX
        let sensexVariation = Double.random(in: -50...50)
        sensexPrice = 81500 + sensexVariation
        sensexChange = sensexVariation
        
        // Update BANK NIFTY
        let bankNiftyVariation = Double.random(in: -100...100)
        bankNiftyPrice = 52000 + bankNiftyVariation
        bankNiftyChange = bankNiftyVariation
        
        // Update NIFTY IT
        let niftyITVariation = Double.random(in: -30...30)
        niftyITPrice = 42000 + niftyITVariation
        niftyITChange = niftyITVariation
    }
    
    private func loadInitialData() {
        Task {
            await loadRealTimeData()
            await loadRealNews()
            
            // Initialize simulated market data
            updateSimulatedMarketData()
            
            // Generate an initial trade suggestion for demonstration
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                suggestionManager.generateTestSuggestion()
            }
        }
    }
    
    private func loadRealTimeData() async {
        isLoadingData = true
        dataError = nil
        
        do {
            // Test connection first
            await dataManager.testConnection()
            
            if dataManager.isDataAvailable {
                // Fetch NIFTY 50 real-time data
                let niftyData = try await dataManager.fetchLTPAsync(symbol: "NIFTY")
                
                await MainActor.run {
                    marketQuotes["NIFTY"] = niftyData
                    
                    // Calculate price change if we have a previous price
                    if previousPrice > 0 {
                        priceChange = niftyData.price - previousPrice
                        percentChange = (priceChange / previousPrice) * 100
                    } else {
                        // For first load, set default values
                        priceChange = 0.0
                        percentChange = 0.0
                    }
                    
                    previousPrice = currentPrice
                    currentPrice = niftyData.price
                    isLoadingData = false
                    
                    print("NIFTY data updated: Price = \(currentPrice), Change = \(priceChange)")
                }
            } else {
                // Fallback to mock data when API is not available
                await MainActor.run {
                    // Generate mock NIFTY data for demonstration
                    let mockPrice = 24500.0 + Double.random(in: -200...200)
                    let mockChange = Double.random(in: -100...100)
                    let mockPercentChange = (mockChange / mockPrice) * 100
                    
                    if previousPrice == 0 {
                        previousPrice = mockPrice - mockChange
                    }
                    
                    currentPrice = mockPrice
                    priceChange = mockChange
                    percentChange = mockPercentChange
                    
                    dataError = "Using demo data - " + dataManager.errorMessage
                    isLoadingData = false
                    
                    print("Using mock NIFTY data: Price = \(currentPrice), Change = \(priceChange)")
                }
            }
        } catch {
            await MainActor.run {
                // Fallback to mock data when there's an error
                let mockPrice = 24500.0 + Double.random(in: -200...200)
                let mockChange = Double.random(in: -100...100)
                let mockPercentChange = (mockChange / mockPrice) * 100
                
                if previousPrice == 0 {
                    previousPrice = mockPrice - mockChange
                }
                
                currentPrice = mockPrice
                priceChange = mockChange
                percentChange = mockPercentChange
                
                dataError = "Using demo data - " + error.localizedDescription
                isLoadingData = false
                
                print("Error occurred, using mock NIFTY data: Price = \(currentPrice), Change = \(priceChange)")
            }
        }
    }
    
    private func loadRealNews() async {
        await withCheckedContinuation { continuation in
            newsClient.fetchIndianMarketNews { result in
                switch result {
                case .success(let newsArticles):
                    Task { @MainActor in
                        self.articles = newsArticles
                    }
                case .failure(let error):
                    print("Failed to load news: \(error.localizedDescription)")
                    // Don't show error for news - just leave articles empty
                    Task { @MainActor in
                        self.articles = []
                    }
                }
                continuation.resume()
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
        
        // Try to start WebSocket connection
        webSocketManager.startDataStreaming()
        
        // Start fallback timer with shorter interval for better real-time feel
        startAutoRefresh(interval: 5.0) // Reduced from 10 to 5 seconds
        
        print("Real-time data stream setup completed")
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
                await loadRealTimeData()
                // Also update simulated market data
                await MainActor.run {
                    updateSimulatedMarketData()
                }
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}