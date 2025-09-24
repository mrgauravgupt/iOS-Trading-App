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
    private let sentimentAnalyzer = SentimentAnalyzer()
    private let marketDataProvider = ZerodhaMarketDataProvider()
    private let historicalProvider = ZerodhaHistoricalDataProvider()
    private let virtualPortfolio = VirtualPortfolio()

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

                    // Market snapshot
                    SectionCard("Market Overview") {
                        VStack(alignment: .leading, spacing: 12) {
                            MarketDataWidget(marketData: marketData)
                            HStack(spacing: 12) {
                                StatChip(label: "Portfolio", value: "₹" + String(format: "%.2f", portfolioValue))
                                StatChip(label: "P&L", value: "₹" + String(format: "%.2f", pnl), color: pnl >= 0 ? .green : .red)
                                StatChip(label: "Cash", value: "₹" + String(format: "%.2f", virtualPortfolio.getBalance()))
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
                marketDataProvider.onTick = { tick in
                    DispatchQueue.main.async {
                        self.marketData = "\(tick.symbol) ₹\(String(format: "%.2f", tick.price))"
                        let currentPrices = [tick.symbol: tick.price]
                        self.portfolioValue = self.virtualPortfolio.getPortfolioValue(currentPrices: currentPrices)
                        self.pnl = self.portfolioValue - 100000.0
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
            
            // Paper Trading Tab
            PaperTradingView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Paper Trading")
                }
                .tag(1)
            
            // Backtesting Tab
            BacktestingView()
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Backtesting")
                }
                .tag(2)
            
            // Chart Tab
            ChartView(data: chartData)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Chart")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
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
