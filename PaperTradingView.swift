import SwiftUI

struct PaperTradingView: View {
    @State private var selectedSymbol = "NIFTY"
    @State private var quantity = ""
    @State private var orderType = "Buy"
    @State private var portfolioValue = 100000.0
    @State private var holdings: [String: Int] = [:]
    @State private var trades: [Trade] = []
    
    private let orderExecutor = OrderExecutor()
    private let plCalculator = PLCalculator()
    
    var body: some View {
        VStack {
            Text("Paper Trading Dashboard")
                .font(.largeTitle)
                .padding()
            
            // Portfolio Overview
            Text("Portfolio Value: ₹\(portfolioValue, specifier: "%.2f")")
                .font(.title)
                .padding()
            
            // Order Placement
            VStack {
                TextField("Symbol", text: $selectedSymbol)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Quantity", text: $quantity)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.numberPad)
                
                Picker("Order Type", selection: $orderType) {
                    Text("Buy").tag("Buy")
                    Text("Sell").tag("Sell")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button(action: placeOrder) {
                    Text("Place Order")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            
            // Holdings
            List {
                ForEach(holdings.keys.sorted(), id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                        Spacer()
                        Text("\(holdings[symbol] ?? 0) shares")
                    }
                }
            }
            .frame(height: 150)
            
            Spacer()
        }
        .onAppear {
            loadPortfolioData()
        }
    }
    
    private func placeOrder() {
        guard let qty = Int(quantity), qty > 0 else { return }
        let price = 18000.0 // Placeholder price for NIFTY
        let type: Trade.TradeType = orderType == "Buy" ? .buy : .sell
        
        if orderExecutor.executeOrder(symbol: selectedSymbol, quantity: qty, price: price, type: type) {
            loadPortfolioData()
            quantity = ""
        }
    }
    
    private func loadPortfolioData() {
        portfolioValue = orderExecutor.getPortfolioValue(currentPrices: ["NIFTY": 18000.0])
        holdings = orderExecutor.getPortfolioHoldings()
        trades = orderExecutor.getTradeHistory()
    }
}
