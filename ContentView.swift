import SwiftUI
import Foundation

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var articles: [Article] = []
    @State private var marketData: [MarketData] = []
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var currentPrice: Double = 18250.50
    @State private var priceChange: Double = 125.30
    @State private var percentChange: Double = 0.69
    
    private let newsClient = NewsAPIClient()
    
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
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NIFTY 50")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                MarketCard(title: "NIFTY 50", value: "18,250.50", change: "+125.30", changePercent: "+0.69%", isPositive: true)
                MarketCard(title: "SENSEX", value: "61,872.99", change: "+423.12", changePercent: "+0.69%", isPositive: true)
                MarketCard(title: "BANK NIFTY", value: "43,156.25", change: "-89.75", changePercent: "-0.21%", isPositive: false)
                MarketCard(title: "NIFTY IT", value: "28,945.80", change: "+234.60", changePercent: "+0.82%", isPositive: true)
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
                
                QuickActionButton(title: "Analytics", icon: "chart.bar.xaxis", color: .purple) {
                    selectedTab = 3
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
                ForEach(0..<3, id: \.self) { _ in
                    NewsCardPlaceholder()
                }
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
                PerformanceRow(title: "Today's P&L", value: "+₹2,450.00", isPositive: true)
                PerformanceRow(title: "Total P&L", value: "+₹15,230.50", isPositive: true)
                PerformanceRow(title: "Win Rate", value: "68.5%", isPositive: true)
                PerformanceRow(title: "Active Positions", value: "12", isPositive: nil)
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
        isLoading = true
        
        // Simulate loading market data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Load sample articles
            self.articles = [
                Article(title: "NIFTY 50 Reaches New High Amid Strong Market Sentiment", description: "The benchmark index continues its upward trajectory...", url: "https://example.com", publishedAt: "2024-01-15T10:30:00Z"),
                Article(title: "Banking Sector Shows Mixed Performance", description: "While some banks outperformed, others lagged...", url: "https://example.com", publishedAt: "2024-01-15T09:45:00Z"),
                Article(title: "IT Stocks Rally on Strong Q3 Results", description: "Technology companies report better than expected earnings...", url: "https://example.com", publishedAt: "2024-01-15T08:20:00Z")
            ]
            
            self.isLoading = false
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