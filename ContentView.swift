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
    private let newsClient = NewsAPIClient()
    
    // Timer for auto-refresh
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
                    
                    // Main Content
                    TabView(selection: $selectedTab) {
                        // Dashboard Tab
                        dashboardView
                            .tag(0)
                        
                        // Trading Tab
                        tradingView
                            .tag(1)
                        
                        // AI Control Tab
                        aiControlView
                            .tag(2)
                        
                        // Analytics Tab
                        analyticsView
                            .tag(3)
                        
                        // Portfolio Tab
                        portfolioView
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
            startAutoRefresh()
            
            // Register for notification to show trade suggestions
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowTradeSuggestions"), object: nil, queue: .main) { _ in
                showTradeSuggestions = true
            }
        }
        .onDisappear {
            stopAutoRefresh()
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
                    
                    // Connection status indicator
                    Circle()
                        .fill(dataManager.connectionStatus.color)
                        .frame(width: 8, height: 8)
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
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                // Market Overview Cards
                marketOverviewSection
                
                // Quick Actions
                quickActionsSection
                
                // Live Chart
                liveChartSection
                
                // Recent News
                newsSection
                
                // Performance Metrics
                performanceSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
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
                    // Only show NIFTY 50 with real data, others show "Data Unavailable"
                    if let niftyData = marketQuotes["NIFTY"] {
                        MarketCard(
                            title: "NIFTY 50", 
                            value: String(format: "%.2f", niftyData.price),
                            change: String(format: "%+.2f", priceChange),
                            changePercent: String(format: "%+.2f%%", percentChange),
                            isPositive: priceChange >= 0
                        )
                    } else {
                        MarketCard(title: "NIFTY 50", value: "---", change: "---", changePercent: "---", isPositive: true)
                    }
                    
                    // Other indices - show unavailable until implemented
                    MarketCard(title: "SENSEX", value: "Not Available", change: "---", changePercent: "---", isPositive: true)
                    MarketCard(title: "BANK NIFTY", value: "Not Available", change: "---", changePercent: "---", isPositive: true)
                    MarketCard(title: "NIFTY IT", value: "Not Available", change: "---", changePercent: "---", isPositive: true)
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
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Live Chart")
                            .font(.system(size: 16, weight: .medium))
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
                ForEach(articles.prefix(3), id: \.id) { article in
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Trading Terminal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Trading interface placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 400)
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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - AI Control View
    private var aiControlView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("AI Trading Control")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // AI control interface placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 400)
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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Analytics View
    private var analyticsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Analytics & Insights")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Analytics interface placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 400)
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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Portfolio View
    private var portfolioView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Portfolio")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Portfolio interface placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 400)
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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
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
    private func loadInitialData() {
        Task {
            await loadRealTimeData()
            await loadRealNews()
            
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
    
    // MARK: - Auto Refresh Functions
    private func startAutoRefresh() {
        // Refresh data every 30 seconds during market hours
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            print("Auto-refresh timer fired - loading real-time data")
            Task {
                await loadRealTimeData()
            }
        }
        print("Auto-refresh timer started")
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
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