import SwiftUI
import Foundation

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
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    // Ultra-compact floating header
                    floatingHeaderSection(geometry: geometry)
                    
                    // Enhanced market overview with live indicators
                    enhancedMarketOverviewSection
                    
                    // AI & Pattern Analysis with real-time updates
                    enhancedAIPatternSection
                    
                    // Quick Access with haptic feedback
                    enhancedQuickAccessSection
                    
                    // Advanced analysis with visual indicators
                    enhancedAnalysisSection
                    
                    // Live news feed with sentiment visualization
                    enhancedNewsFeedSection
                    
                    // Performance metrics row
                    performanceMetricsSection
                    
                    // Bottom safe area padding
                    Color.clear.frame(height: 10)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }
            .background(
                ZStack {
                    // Dynamic gradient background
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.98),
                            Color.blue.opacity(0.05),
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle animated particles
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.blue.opacity(0.03))
                            .frame(width: 100, height: 100)
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .animation(
                                Animation.easeInOut(duration: 8)
                                    .repeatForever(autoreverses: true),
                                value: UUID()
                            )
                    }
                }
                .ignoresSafeArea()
            )
        }
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
    
    // MARK: - Enhanced Dashboard Sections
    private func floatingHeaderSection(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left side - App title with live indicator
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("NIFTY Pro")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Live Trading")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Right side - Market regime with enhanced styling
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(marketRegime.description.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("MARKET")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(regimeColor(marketRegime).opacity(0.2))
                        .frame(width: 40, height: 28)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(regimeColor(marketRegime))
                        .frame(width: 24, height: 16)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var enhancedMarketOverviewSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
            EnhancedMarketCard(
                title: "NIFTY",
                value: marketData,
                change: "+0.85%",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue,
                isPositive: true
            )
            
            EnhancedMarketCard(
                title: "Portfolio",
                value: "₹\(String(format: "%.0f", portfolioValue))",
                change: String(format: "%.2f%%", (pnl / portfolioValue) * 100),
                icon: "briefcase.fill",
                color: .purple,
                isPositive: pnl >= 0
            )
            
            EnhancedMarketCard(
                title: "P&L Today",
                value: "₹\(String(format: "%.0f", pnl))",
                change: "Live",
                icon: pnl >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                color: pnl >= 0 ? .green : .red,
                isPositive: pnl >= 0
            )
            
            EnhancedMarketCard(
                title: "Buying Power",
                value: "₹\(String(format: "%.0f", virtualPortfolio.getBalance()))",
                change: "Available",
                icon: "dollarsign.circle.fill",
                color: .orange,
                isPositive: true
            )
        }
    }
    
    private var enhancedAIPatternSection: some View {
        ModernCard {
            VStack(spacing: 10) {
                // AI Status with enhanced visuals
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(aiTradingEnabled ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(aiTradingEnabled ? .green : .gray)
                                .font(.title3)
                                .scaleEffect(aiTradingEnabled ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: aiTradingEnabled)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Trading Engine")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(aiTradingEnabled ? .green : .red)
                                    .frame(width: 6, height: 6)
                                Text(aiTradingEnabled ? "ACTIVE" : "STANDBY")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(aiTradingEnabled ? .green : .red)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $aiTradingEnabled)
                        .scaleEffect(0.9)
                        .onChange(of: aiTradingEnabled) { enabled in
                            if enabled {
                                startAITrading()
                            }
                        }
                }
                
                // Pattern alerts with enhanced display
                if !patternAlerts.isEmpty {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Pattern Alerts")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Text("\(patternAlerts.count) active signals")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Scanner") {
                                showPatternScanner = true
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(6)
                        }
                        
                        // Enhanced pattern alert rows
                        ForEach(Array(patternAlerts.prefix(2).enumerated()), id: \.offset) { index, alert in
                            EnhancedPatternAlertRow(alert: alert)
                        }
                    }
                }
            }
        }
    }
    
    private var enhancedQuickAccessSection: some View {
        ModernCard {
            VStack(spacing: 10) {
                HStack {
                    Text("Quick Actions")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Tap to navigate")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                    EnhancedQuickAccessButton(
                        title: "Scanner",
                        icon: "waveform.path.ecg",
                        color: .purple,
                        gradient: [.purple, .pink]
                    ) {
                        showPatternScanner = true
                    }
                    
                    EnhancedQuickAccessButton(
                        title: "AI Control",
                        icon: "brain.head.profile",
                        color: .blue,
                        gradient: [.blue, .cyan]
                    ) {
                        selectedTab = 1
                    }
                    
                    EnhancedQuickAccessButton(
                        title: "Analytics",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        gradient: [.green, .mint]
                    ) {
                        selectedTab = 2
                    }
                    
                    EnhancedQuickAccessButton(
                        title: "Risk",
                        icon: "shield.fill",
                        color: .red,
                        gradient: [.red, .orange]
                    ) {
                        selectedTab = 6
                    }
                }
            }
        }
    }
    
    private var enhancedAnalysisSection: some View {
        ModernCard {
            VStack(spacing: 12) {
                // Header with live update indicator
                HStack {
                    HStack(spacing: 6) {
                        Text("Market Analysis")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                            .scaleEffect(1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: UUID()
                            )
                    }
                    
                    Spacer()
                    
                    Text("\(totalActivePatterns()) patterns detected")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Enhanced timeframe grid
                if !multiTimeframeAnalysis.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2), spacing: 6) {
                        ForEach(["1D", "4h", "1h", "15m"], id: \.self) { timeframe in
                            if let patterns = multiTimeframeAnalysis[timeframe], !patterns.isEmpty {
                                EnhancedTimeframeCard(timeframe: timeframe, patterns: patterns)
                            }
                        }
                    }
                } else {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.blue)
                        Text("Analyzing market patterns...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Enhanced confluence section
                if !confluencePatterns.isEmpty {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Strong Confluence")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(averageConfidence() * 100))% confidence")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        ForEach(Array(confluencePatterns.prefix(2).enumerated()), id: \.offset) { index, pattern in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(signalColor(pattern.signal))
                                    .frame(width: 3, height: 12)
                                
                                Text(pattern.pattern)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(Int(pattern.confidence * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(signalColor(pattern.signal))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var enhancedNewsFeedSection: some View {
        ModernCard {
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "newspaper.fill")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        
                        Text("Market News")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Live Feed")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(3)
                }
                
                if articles.isEmpty {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.blue)
                        Text("Loading latest news...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(articles.prefix(3).enumerated()), id: \.offset) { index, article in
                            EnhancedNewsRow(article: article, sentimentAnalyzer: sentimentAnalyzer)
                            
                            if index < 2 {
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var performanceMetricsSection: some View {
        HStack(spacing: 8) {
            PerformanceMetricCard(
                title: "Win Rate",
                value: "68%",
                icon: "target",
                color: .green
            )
            
            PerformanceMetricCard(
                title: "Avg Return",
                value: "2.4%",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )
            
            PerformanceMetricCard(
                title: "Max DD",
                value: "1.2%",
                icon: "arrow.down.circle",
                color: .orange
            )
        }
    }
    
    private var aiPatternCombinedSection: some View {
        ModernCard {
            VStack(spacing: 12) {
                // AI Trading Status Row
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(aiTradingEnabled ? .green : .gray)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("AI Trading")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(aiTradingEnabled ? "Active" : "Inactive")
                                .font(.caption)
                                .foregroundColor(aiTradingEnabled ? .green : .gray)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $aiTradingEnabled)
                        .scaleEffect(0.8)
                        .onChange(of: aiTradingEnabled) { enabled in
                            if enabled {
                                startAITrading()
                            }
                        }
                }
                
                // Pattern Alerts Row
                if !patternAlerts.isEmpty {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.orange)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Pattern Alerts")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text("\(patternAlerts.count) active")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Button("View All") {
                            showPatternScanner = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    }
                    
                    // Show top 2 alerts
                    ForEach(Array(patternAlerts.prefix(2).enumerated()), id: \.offset) { index, alert in
                        CompactPatternAlertRow(alert: alert)
                    }
                }
            }
        }
    }
    
    private var quickAccessGridSection: some View {
        ModernCard {
            VStack(spacing: 8) {
                HStack {
                    Text("Quick Access")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    CompactQuickAccessButton(
                        title: "Scanner",
                        icon: "waveform.path.ecg",
                        color: .purple
                    ) {
                        showPatternScanner = true
                    }
                    
                    CompactQuickAccessButton(
                        title: "AI Control",
                        icon: "brain.head.profile",
                        color: .blue
                    ) {
                        selectedTab = 1
                    }
                    
                    CompactQuickAccessButton(
                        title: "Analytics",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    ) {
                        selectedTab = 2
                    }
                    
                    CompactQuickAccessButton(
                        title: "Risk",
                        icon: "shield.fill",
                        color: .red
                    ) {
                        selectedTab = 6
                    }
                }
            }
        }
    }
    
    private var analysisIntelligenceSection: some View {
        ModernCard {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Market Analysis")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(totalActivePatterns()) patterns")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Timeframe Analysis Grid
                if !multiTimeframeAnalysis.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(["1D", "4h", "1h", "15m"], id: \.self) { timeframe in
                            if let patterns = multiTimeframeAnalysis[timeframe], !patterns.isEmpty {
                                CompactTimeframeCard(timeframe: timeframe, patterns: patterns)
                            }
                        }
                    }
                } else {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing patterns...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Confluence Patterns
                if !confluencePatterns.isEmpty {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Strong Confluence")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(averageConfidence() * 100))% avg")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        ForEach(Array(confluencePatterns.prefix(2).enumerated()), id: \.offset) { index, pattern in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(signalColor(pattern.signal))
                                    .frame(width: 6, height: 6)
                                Text(pattern.pattern)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(pattern.confidence * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(signalColor(pattern.signal))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var compactNewsFeedSection: some View {
        ModernCard {
            VStack(spacing: 8) {
                HStack {
                    Text("Market News")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                
                if !isLoading && !articles.isEmpty {
                    ForEach(Array(articles.prefix(3).enumerated()), id: \.offset) { index, article in
                        CompactNewsRow(article: article, sentimentAnalyzer: sentimentAnalyzer)
                        if index < 2 {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                } else if !isLoading {
                    Text("No news available")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Dashboard")
                }
                .tag(0)
            
            // AI Control Center Tab
            modernComingSoonView(title: "AI Control Center", icon: "brain.head.profile")
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "brain.head.profile.fill" : "brain.head.profile")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("AI Control")
                }
                .tag(1)
            
            // Analytics Tab
            modernComingSoonView(title: "Performance Analytics", icon: "chart.line.uptrend.xyaxis")
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("Analytics")
                }
                .tag(2)
            
            // Paper Trading Tab
            PaperTradingView()
                .tabItem {
                    Image(systemName: "chart.bar")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("Trading")
                }
                .tag(3)
            
            // Backtesting Tab
            BacktestingView()
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                        .environment(\.symbolVariants, selectedTab == 4 ? .circle.fill : .none)
                    Text("Backtest")
                }
                .tag(4)
            
            // Chart Tab
            ChartView(data: chartData)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                        .environment(\.symbolVariants, selectedTab == 5 ? .fill : .none)
                    Text("Chart")
                }
                .tag(5)
            
            // Risk Management Tab
            modernComingSoonView(title: "Risk Management", icon: "shield.fill")
                .tabItem {
                    Image(systemName: "shield")
                        .environment(\.symbolVariants, selectedTab == 6 ? .fill : .none)
                    Text("Risk")
                }
                .tag(6)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                        .environment(\.symbolVariants, selectedTab == 7 ? .circle.fill : .none)
                    Text("Settings")
                }
                .tag(7)
        }
        .accentColor(.blue)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.9)
            appearance.selectionIndicatorTintColor = UIColor.systemBlue
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.gray,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .sheet(isPresented: $showPatternScanner) {
            PatternScannerView(
                multiTimeframeAnalysis: multiTimeframeAnalysis,
                patternAlerts: patternAlerts,
                confluencePatterns: []
            )
        }
    }
    
    // Enhanced modern coming soon view
    private func modernComingSoonView(title: String, icon: String) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.98),
                        Color.blue.opacity(0.08),
                        Color.purple.opacity(0.05),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Animated icon with glow effect
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                value: UUID()
                            )
                        
                        Circle()
                            .fill(Color.blue.opacity(0.05))
                            .frame(width: 160, height: 160)
                            .scaleEffect(1.2)
                            .animation(
                                Animation.easeInOut(duration: 3.0)
                                    .repeatForever(autoreverses: true),
                                value: UUID()
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.blue)
                            .scaleEffect(1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.5)
                                    .repeatForever(autoreverses: true),
                                value: UUID()
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                                .scaleEffect(1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true),
                                    value: UUID()
                                )
                            
                            Text("Coming Soon")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("This feature is under active development")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Text("Stay tuned for exciting updates!")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Progress indicator
                    VStack(spacing: 8) {
                        HStack {
                            Text("Development Progress")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("75%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: 0.75)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 2)
                    }
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.95), Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
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

// MARK: - New Modern UI Components

struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct CompactMarketCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CompactQuickAccessButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct CompactPatternAlertRow: View {
    let alert: PatternRecognitionEngine.PatternAlert
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(urgencyColor(alert.urgency))
                .frame(width: 6, height: 6)
            
            Text(alert.pattern.pattern)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(Int(alert.pattern.confidence * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(signalColor(alert.pattern.signal))
        }
        .padding(.vertical, 2)
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

struct CompactTimeframeCard: View {
    let timeframe: String
    let patterns: [TechnicalAnalysisEngine.PatternResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(timeframe)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Text("\(patterns.count)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if let topPattern = patterns.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text(topPattern.pattern)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    HStack {
                        Circle()
                            .fill(signalColor(topPattern.signal))
                            .frame(width: 4, height: 4)
                        Text("\(Int(topPattern.confidence * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(signalColor(topPattern.signal))
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func signalColor(_ signal: TechnicalAnalysisEngine.TradingSignal) -> Color {
        switch signal {
        case .buy, .strongBuy: return .green
        case .sell, .strongSell: return .red
        case .hold: return .gray
        }
    }
}

struct CompactNewsRow: View {
    let article: Article
    let sentimentAnalyzer: SentimentAnalyzer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            HStack {
                if let description = article.description {
                    let sentiment = sentimentAnalyzer.analyzeSentiment(for: description)
                    Text(sentiment)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(sentimentColor(sentiment).opacity(0.2))
                        .foregroundColor(sentimentColor(sentiment))
                        .cornerRadius(3)
                }
                
                Spacer()
                
                Text(timeAgo(from: article.publishedAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment {
        case "Positive": return .green
        case "Negative": return .red
        default: return .blue
        }
    }
    
    private func timeAgo(from dateString: String) -> String {
        // Simple time ago implementation
        return "2h ago" // Placeholder
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

// MARK: - Enhanced UI Components

struct EnhancedMarketCard: View {
    let title: String
    let value: String
    let change: String
    let icon: String
    let color: Color
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(change)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isPositive ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((isPositive ? Color.green : Color.red).opacity(0.2))
                    .cornerRadius(3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct EnhancedPatternAlertRow: View {
    let alert: PatternRecognitionEngine.PatternAlert
    
    var body: some View {
        HStack(spacing: 10) {
            // Urgency indicator
            ZStack {
                Circle()
                    .fill(urgencyColor(alert.urgency).opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Circle()
                    .fill(urgencyColor(alert.urgency))
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.pattern.pattern)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(alert.timeframe)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(alert.pattern.signal.rawValue)
                        .font(.caption2)
                        .foregroundColor(signalColor(alert.pattern.signal))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(alert.pattern.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(signalColor(alert.pattern.signal))
                
                Text(alert.urgency.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(urgencyColor(alert.urgency))
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

struct EnhancedQuickAccessButton: View {
    let title: String
    let icon: String
    let color: Color
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedTimeframeCard: View {
    let timeframe: String
    let patterns: [TechnicalAnalysisEngine.PatternResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(timeframe)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                
                Spacer()
                
                Text("\(patterns.count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            if let topPattern = patterns.first {
                VStack(alignment: .leading, spacing: 3) {
                    Text(topPattern.pattern)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(signalColor(topPattern.signal))
                            .frame(width: 2, height: 10)
                        
                        Text("\(Int(topPattern.confidence * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(signalColor(topPattern.signal))
                        
                        Spacer()
                        
                        Text(topPattern.signal.rawValue)
                            .font(.caption2)
                            .foregroundColor(signalColor(topPattern.signal))
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func signalColor(_ signal: TechnicalAnalysisEngine.TradingSignal) -> Color {
        switch signal {
        case .buy, .strongBuy: return .green
        case .sell, .strongSell: return .red
        case .hold: return .gray
        }
    }
}

struct EnhancedNewsRow: View {
    let article: Article
    let sentimentAnalyzer: SentimentAnalyzer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            HStack {
                if let description = article.description {
                    let sentiment = sentimentAnalyzer.analyzeSentiment(for: description)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(sentimentColor(sentiment))
                            .frame(width: 6, height: 6)
                        
                        Text(sentiment)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(sentimentColor(sentiment))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(sentimentColor(sentiment).opacity(0.15))
                    .cornerRadius(4)
                }
                
                Spacer()
                
                Text("2h ago")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment {
        case "Positive": return .green
        case "Negative": return .red
        default: return .blue
        }
    }
}

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}