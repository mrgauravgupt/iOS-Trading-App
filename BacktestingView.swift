import SwiftUI

struct BacktestingView: View {
    @State private var symbol = "NIFTY"
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var result: BacktestResult?
    @State private var isLoading = false
    
    private let backtestingEngine = BacktestingEngine()
    
    var body: some View {
        VStack {
            Text("Backtesting Interface")
                .font(.largeTitle)
                .padding()
            
            // Configuration
            VStack {
                TextField("Symbol", text: $symbol)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .padding()
                
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    .padding()
                
                Button(action: runBacktest) {
                    Text("Run Backtest")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(isLoading)
            }
            
            // Results
            if let result = result {
                VStack {
                    Text("Total Return: \(result.totalReturn, specifier: "%.2f")%")
                    Text("Win Rate: \(result.winRate, specifier: "%.2f")%")
                    Text("Total Trades: \(result.totalTrades)")
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private func runBacktest() {
        isLoading = true
        DispatchQueue.global(qos: .background).async {
            let result = backtestingEngine.runBacktest(symbol: symbol, startDate: startDate, endDate: endDate)
            DispatchQueue.main.async {
                self.result = result
                isLoading = false
            }
        }
    }
}
