import SwiftUI

/// View for paper trading functionality
struct PaperTradingView: View {
    @State private var selectedSymbol = "NIFTY"
    @State private var quantity = ""
    @State private var orderType = "Buy"
    @State private var portfolioValue = 100000.0
    @State private var holdings: [String: Int] = [:]
    @State private var trades: [VirtualPortfolio.PortfolioTrade] = []
    @State private var momentumAlerts: [String] = []
    @State private var showAlerts = true
    @State private var showOrderConfirmation = false
    @State private var orderConfirmationMessage = ""

    private let orderExecutor = OrderExecutor()
    private let plCalculator = PLCalculator()
    private let technicalAnalysisEngine = TechnicalAnalysisEngine()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Paper Trading")
                            .font(.largeTitle).bold()
                        Text("Simulate orders and track holdings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Portfolio Overview
                    SectionCard("Portfolio Overview") { portfolioOverviewSection }

                    // Momentum Alerts
                    momentumAlertsSection

                    // Order Placement
                    SectionCard("Place Order") { orderPlacementSection }

                    // Holdings
                    SectionCard("Current Holdings") { holdingsSection }

                    // Trade History
                    SectionCard("Recent Trades") { tradeHistorySection }

                    Spacer(minLength: 16)
                }
                .padding()
            }
            .background(Color.kiteBackground.ignoresSafeArea())
            .navigationTitle("Paper Trading")
            .onAppear {
                loadPortfolioData()
                generateMomentumAlerts()
            }
            .alert("Order Confirmation", isPresented: $showOrderConfirmation) {
                Button("OK") { }
            } message: {
                Text(orderConfirmationMessage)
            }
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
    
    /// Check if quantity is valid
    private var isQuantityValid: Bool {
        guard let qty = Int(quantity) else { return false }
        return qty > 0
    }
    
    /// Place an order
    private func placeOrder() {
        guard let qty = Int(quantity), qty > 0 else {
            orderConfirmationMessage = "Please enter a valid quantity"
            showOrderConfirmation = true
            return
        }
        
        // Using a placeholder price for NIFTY
        let price = 18000.0
        let type: VirtualPortfolio.PortfolioTrade.TradeType = orderType == "Buy" ? .buy : .sell
        
        let success = orderExecutor.executeOrder(symbol: selectedSymbol, quantity: qty, price: price, type: type)
        
        if success {
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
    
    /// Load portfolio data
    private func loadPortfolioData() {
        portfolioValue = orderExecutor.getPortfolioValue(currentPrices: ["NIFTY": 18000.0])
        holdings = orderExecutor.getPortfolioHoldings()
        trades = orderExecutor.getTradeHistory()
    }

    /// Generate momentum alerts
    private func generateMomentumAlerts() {
        // Simplified momentum alert generation
        let currentPrice = 18000.0 // Placeholder
        let rsi = technicalAnalysisEngine.calculateRSI(prices: [currentPrice])
        let (macd, signal, _) = technicalAnalysisEngine.calculateMACD(prices: [currentPrice])

        var alerts: [String] = []

        if rsi < 30 {
            alerts.append("RSI indicates oversold condition - Consider buying")
        } else if rsi > 70 {
            alerts.append("RSI indicates overbought condition - Consider selling")
        }

        if macd > signal {
            alerts.append("MACD bullish crossover - Potential buy signal")
        } else if macd < signal {
            alerts.append("MACD bearish crossover - Potential sell signal")
        }

        momentumAlerts = alerts
    }
}