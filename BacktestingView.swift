import SwiftUI

/// View for backtesting trading strategies
struct BacktestingView: View {
    @State private var symbol = "NIFTY"
    @State private var startDate = Date().addingTimeInterval(-30*24*60*60) // 30 days ago
    @State private var endDate = Date()
    @State private var selectedPatterns: Set<String> = ["RSI", "MACD"]
    @State private var result: BacktestResult?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let backtestingEngine = BacktestingEngine()
    private let availablePatterns = ["RSI", "MACD", "Bollinger Bands", "Candlestick", "Stochastic"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Backtesting Interface")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
                    // Configuration
                    GroupBox("Configuration") {
                        VStack(alignment: .leading, spacing: 15) {
                            TextField("Symbol", text: $symbol)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disableAutocorrection(true)
                                .autocapitalization(.allCharacters)
                            
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            
                            // Pattern Selection
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Select Patterns to Test:")
                                    .font(.headline)
                                
                                ForEach(availablePatterns, id: \.self) { pattern in
                                    HStack {
                                        Text(pattern)
                                        Spacer()
                                        Button(action: {
                                            if selectedPatterns.contains(pattern) {
                                                selectedPatterns.remove(pattern)
                                            } else {
                                                selectedPatterns.insert(pattern)
                                            }
                                        }) {
                                            Image(systemName: selectedPatterns.contains(pattern) ? "checkmark.square" : "square")
                                                .foregroundColor(selectedPatterns.contains(pattern) ? .green : .gray)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            Button(action: runBacktest) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text("Run Backtest")
                                }
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(isLoading ? Color.gray : Color.green)
                                .cornerRadius(10)
                            }
                            .disabled(isLoading || selectedPatterns.isEmpty)
                        }
                        .padding()
                    }
                    
                    // Results
                    if let result = result {
                        GroupBox("Results") {
                            VStack(alignment: .leading, spacing: 15) {
                                ResultRow(title: "Total Return", value: String(format: "%.2f", result.totalReturn) + "%")
                                ResultRow(title: "Win Rate", value: String(format: "%.2f", result.winRate) + "%")
                                ResultRow(title: "Total Trades", value: "\(result.totalTrades)")
                                
                                if result.totalReturn > 0 {
                                    Text("Strategy is profitable")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                } else {
                                    Text("Strategy is not profitable")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Backtesting")
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    /// Run the backtesting process
    private func runBacktest() {
        // Validate inputs
        guard !symbol.isEmpty else {
            showError(message: "Please enter a symbol")
            return
        }
        
        guard endDate > startDate else {
            showError(message: "End date must be after start date")
            return
        }
        
        guard !selectedPatterns.isEmpty else {
            showError(message: "Please select at least one pattern")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = backtestingEngine.runBacktest(
                symbol: symbol,
                startDate: startDate,
                endDate: endDate,
                patterns: Array(selectedPatterns)
            )
            
            DispatchQueue.main.async {
                self.result = result
                self.isLoading = false
            }
        }
    }
    
    /// Show error message
    private func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
}

/// View for displaying a result row
struct ResultRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    BacktestingView()
}