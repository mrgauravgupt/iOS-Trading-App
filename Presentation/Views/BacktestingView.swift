import SwiftUI
import Charts

/// Advanced View for backtesting trading strategies with comprehensive pattern testing
struct BacktestingView: View {
    @StateObject private var backtestingEngine = BacktestingEngine()
    @StateObject private var technicalEngine = TechnicalAnalysisEngine()
    
    // Basic Configuration
    @State private var symbol = "NIFTY"
    @State private var startDate = Date().addingTimeInterval(-90*24*60*60) // 90 days ago
    @State private var endDate = Date()
    @State private var initialCapital: Double = 100000
    @State private var positionSize: Double = 0.02 // 2% per trade
    
    // Advanced Configuration
    @State private var selectedTestType: TestType = .comprehensive
    @State private var selectedPatterns: Set<String> = []
    @State private var enableMLOptimization = true
    @State private var enableMonteCarloSimulation = false
    @State private var monteCarloRuns = 1000
    @State private var enableMultiTimeframe = true
    @State private var selectedTimeframes: Set<String> = ["1D", "4h", "1h"]
    
    // Results and UI State
    @State private var backtestResults: AdvancedBacktestResult?
    @State private var isLoading = false
    @State private var loadingProgress: Double = 0.0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDetailedResults = false
    @State private var selectedTab: ResultTab = .overview
    
    enum TestType: String, CaseIterable {
        case basic = "Basic Patterns"
        case comprehensive = "Comprehensive (100+ Patterns)"
        case combinations = "Pattern Combinations"
        case multiTimeframe = "Multi-Timeframe"
        case monteCarlo = "Monte Carlo"
        case mlOptimized = "ML Optimized"
    }
    
    enum ResultTab: String, CaseIterable {
        case overview = "Overview"
        case patterns = "Patterns"
        case metrics = "Metrics"
        case monteCarlo = "Monte Carlo"
        case ml = "ML Insights"
    }
    
    // Comprehensive pattern library
    private let comprehensivePatterns = [
        // Chart Patterns
        "Head and Shoulders", "Inverse Head and Shoulders", "Double Top", "Double Bottom",
        "Triple Top", "Triple Bottom", "Ascending Triangle", "Descending Triangle",
        "Symmetrical Triangle", "Rising Wedge", "Falling Wedge", "Bull Flag", "Bear Flag",
        "Bull Pennant", "Bear Pennant", "Cup and Handle", "Rounding Bottom", "Rounding Top",
        
        // Candlestick Patterns
        "Doji", "Hammer", "Hanging Man", "Shooting Star", "Inverted Hammer",
        "Bullish Engulfing", "Bearish Engulfing", "Morning Star", "Evening Star",
        "Three White Soldiers", "Three Black Crows", "Piercing Pattern", "Dark Cloud Cover",
        "Harami", "Harami Cross", "Tweezer Tops", "Tweezer Bottoms",
        
        // Harmonic Patterns
        "Gartley Pattern", "Butterfly Pattern", "Bat Pattern", "Crab Pattern",
        "ABCD Pattern", "Shark Pattern", "Cypher Pattern",
        
        // Technical Indicators
        "RSI Divergence", "MACD Divergence", "Bollinger Squeeze", "Volume Breakout",
        "Moving Average Crossover", "Stochastic Overbought/Oversold", "Williams %R Signal",
        "CCI Extremes", "Parabolic SAR Reversal", "ATR Volatility Signal"
    ]
    
    private let timeframeOptions = ["1m", "5m", "15m", "30m", "1h", "4h", "1D", "1W"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Configuration Section
                    configurationSection
                    
                    // Advanced Options
                    advancedOptionsSection
                    
                    // Pattern Selection
                    patternSelectionSection
                    
                    // Run Backtest Button
                    runBacktestSection
                    
                    // Loading Progress
                    if isLoading {
                        loadingSection
                    }
                    
                    // Results Section
                    if let results = backtestResults {
                        resultsSection(results: results)
                    }
                }
                .padding()
            }
            .navigationTitle("Advanced Backtesting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Advanced Backtesting")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showDetailedResults) {
                if let results = backtestResults {
                    DetailedBacktestResultsView(results: results)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title3)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Advanced Backtesting")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Text("Comprehensive Pattern Testing Suite")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()
        }
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.orange)
                Text("Basic Configuration")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Symbol:")
                        .frame(width: 100, alignment: .leading)
                    TextField("NIFTY", text: $symbol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }

                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                HStack {
                    Text("Initial Capital:")
                        .frame(width: 100, alignment: .leading)
                    TextField("100000", value: $initialCapital, format: .currency(code: "USD"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }

                HStack {
                    Text("Position Size:")
                        .frame(width: 100, alignment: .leading)
                    Slider(value: $positionSize, in: 0.01...0.10, step: 0.01)
                    Text("\(String(format: "%.1f%%", positionSize * 100))")
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Advanced Options Section
    
    private var advancedOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.purple)
                Text("Advanced Options")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                // Test Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Type:")
                        .font(.caption)
                        .fontWeight(.medium)

                    Picker("Test Type", selection: $selectedTestType) {
                        ForEach(TestType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // Multi-Timeframe Toggle
                Toggle("Multi-Timeframe Analysis", isOn: $enableMultiTimeframe)

                if enableMultiTimeframe {
                    TimeframeSelectionView(selectedTimeframes: $selectedTimeframes, timeframes: timeframeOptions)
                }

                // ML Optimization Toggle
                Toggle("ML Pattern Optimization", isOn: $enableMLOptimization)

                // Monte Carlo Toggle
                Toggle("Monte Carlo Simulation", isOn: $enableMonteCarloSimulation)

                if enableMonteCarloSimulation {
                    HStack {
                        Text("Simulation Runs:")
                        Slider(value: .init(
                            get: { Double(monteCarloRuns) },
                            set: { monteCarloRuns = Int($0) }
                        ), in: 100...10000, step: 100)
                        Text("\(monteCarloRuns)")
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Pattern Selection Section
    
    private var patternSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
                Text("Pattern Selection")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()

                Button(selectedTestType == .comprehensive ? "Select All" : "Clear All") {
                    if selectedTestType == .comprehensive {
                        selectedPatterns = Set(comprehensivePatterns)
                    } else {
                        selectedPatterns.removeAll()
                    }
                }
                .foregroundColor(.blue)
            }

            if selectedTestType == .comprehensive {
                ComprehensivePatternSelector(
                    patterns: comprehensivePatterns,
                    selectedPatterns: $selectedPatterns
                )
            } else {
                BasicPatternSelector(
                    patterns: basicPatterns,
                    selectedPatterns: $selectedPatterns
                )
            }

            Text("\(selectedPatterns.count) patterns selected")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Run Backtest Section
    
    private var runBacktestSection: some View {
        Button(action: runAdvancedBacktest) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "play.circle.fill")
                }
                Text(isLoading ? "Running Backtest..." : "Run Advanced Backtest")
            }
            .frame(maxWidth: .infinity)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(8)
            .background(isLoading ? Color.gray : Color.blue)
            .cornerRadius(10)
        }
        .disabled(isLoading || selectedPatterns.isEmpty)
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 12) {
            Text("Processing \(selectedPatterns.count) patterns...")
                .font(.subheadline)

            ProgressView(value: loadingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)

            Text("\(String(format: "%.0f%%", loadingProgress * 100)) complete")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Results Section
    
    private func resultsSection(results: AdvancedBacktestResult) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Backtest Results")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()

                Button("Detailed View") {
                    showDetailedResults = true
                }
                .foregroundColor(.blue)
            }

            // Results Tab Selection
            Picker("Results", selection: $selectedTab) {
                ForEach(ResultTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // Tab Content
            switch selectedTab {
            case .overview:
                OverviewResultsView(results: results)
            case .patterns:
                PatternResultsView(results: results)
            case .metrics:
                MetricsResultsView(results: results)
            case .monteCarlo:
                if enableMonteCarloSimulation {
                    MonteCarloResultsView(results: results)
                } else {
                    Text("Monte Carlo simulation not enabled")
                        .foregroundColor(.secondary)
                }
            case .ml:
                if enableMLOptimization {
                    MLInsightsView(results: results)
                } else {
                    Text("ML optimization not enabled")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    private var basicPatterns: [String] {
        ["RSI", "MACD", "Bollinger Bands", "Stochastic", "Moving Average Crossover"]
    }
    
    // MARK: - Core Functions
    
    /// Run the advanced backtesting process
    private func runAdvancedBacktest() {
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
        loadingProgress = 0.0
        errorMessage = ""
        
        Task {
            do {
                // Simulate progress updates
                let totalSteps = selectedPatterns.count * (enableMultiTimeframe ? selectedTimeframes.count : 1)
                var currentStep = 0
                
                // Run comprehensive backtest
                let result = try await backtestingEngine.runAdvancedBacktest(
                    symbol: symbol,
                    startDate: startDate,
                    endDate: endDate,
                    patterns: Array(selectedPatterns),
                    timeframes: enableMultiTimeframe ? Array(selectedTimeframes) : ["1D"],
                    enableML: enableMLOptimization,
                    enableMonteCarlo: enableMonteCarloSimulation,
                    monteCarloRuns: monteCarloRuns,
                    initialCapital: initialCapital,
                    positionSize: positionSize,
                    progressCallback: { step in
                        currentStep = step
                        Task { @MainActor in
                            self.loadingProgress = Double(currentStep) / Double(totalSteps)
                        }
                    }
                )
                
                await MainActor.run {
                    self.backtestResults = result
                    self.isLoading = false
                    self.loadingProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    self.showError(message: "Backtesting failed: \(error.localizedDescription)")
                }
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

// MARK: - Supporting Data Structures

struct AdvancedBacktestResult {
    // Basic Metrics
    let totalReturn: Double
    let annualizedReturn: Double
    let winRate: Double
    let totalTrades: Int
    let profitableTrades: Int
    
    // Advanced Metrics
    let sharpeRatio: Double
    let sortinoRatio: Double
    let calmarRatio: Double
    let maxDrawdown: Double
    let averageDrawdown: Double
    let volatility: Double
    let beta: Double
    let alpha: Double
    
    // Pattern Performance
    let patternResults: [PatternBacktestResult]
    let bestPerformingPattern: String
    let worstPerformingPattern: String
    
    // Monte Carlo Results (optional)
    let monteCarloResults: MonteCarloResults?
    
    // ML Insights (optional)
    let mlInsights: MLBacktestInsights?
    
    // Risk Metrics
    let valueAtRisk: Double
    let expectedShortfall: Double
    let profitFactor: Double
    let recoveryFactor: Double
    
    // Performance Timeline
    let equityCurve: [EquityPoint]
    let drawdownCurve: [DrawdownPoint]
    

}

struct PatternBacktestResult {
    let patternName: String
    let trades: Int
    let winRate: Double
    let avgReturn: Double
    let profitFactor: Double
    let sharpeRatio: Double
}

struct MonteCarloResults {
    let runs: Int
    let meanReturn: Double
    let standardDeviation: Double
    let valueAtRisk95: Double
    let valueAtRisk99: Double
    let probabilityOfLoss: Double
    let worstCaseScenario: Double
    let bestCaseScenario: Double
}

struct MLBacktestInsights {
    let optimalPatternWeights: [String: Double]
    let predictedSuccessRates: [String: Double]
    let featureImportance: [String: Double]
    let marketRegimePerformance: [String: Double]
}

struct EquityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct DrawdownPoint: Identifiable {
    let id = UUID()
    let date: Date
    let drawdown: Double
}

// MARK: - Supporting Views

struct TimeframeSelectionView: View {
    @Binding var selectedTimeframes: Set<String>
    let timeframes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Timeframes:")
                .font(.caption2)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(timeframes, id: \.self) { timeframe in
                    Button(timeframe) {
                        if selectedTimeframes.contains(timeframe) {
                            selectedTimeframes.remove(timeframe)
                        } else {
                            selectedTimeframes.insert(timeframe)
                        }
                    }
                    .font(.caption2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedTimeframes.contains(timeframe) ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(selectedTimeframes.contains(timeframe) ? .white : .primary)
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct ComprehensivePatternSelector: View {
    let patterns: [String]
    @Binding var selectedPatterns: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select from 50+ comprehensive patterns:")
                .font(.caption2)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(patterns, id: \.self) { pattern in
                    PatternSelectionRow(
                        pattern: pattern,
                        isSelected: selectedPatterns.contains(pattern)
                    ) {
                        if selectedPatterns.contains(pattern) {
                            selectedPatterns.remove(pattern)
                        } else {
                            selectedPatterns.insert(pattern)
                        }
                    }
                }
            }
        }
    }
}

struct BasicPatternSelector: View {
    let patterns: [String]
    @Binding var selectedPatterns: Set<String>

    var body: some View {
        VStack(spacing: 8) {
            ForEach(patterns, id: \.self) { pattern in
                PatternSelectionRow(
                    pattern: pattern,
                    isSelected: selectedPatterns.contains(pattern)
                ) {
                    if selectedPatterns.contains(pattern) {
                        selectedPatterns.remove(pattern)
                    } else {
                        selectedPatterns.insert(pattern)
                    }
                }
            }
        }
    }
}

struct PatternSelectionRow: View {
    let pattern: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(pattern)
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.green.opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Result Views

struct OverviewResultsView: View {
    let results: AdvancedBacktestResult

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(title: "Total Return", value: "\(String(format: "%.1f%%", results.totalReturn * 100))", change: "", color: results.totalReturn > 0 ? .green : .red)
                MetricCard(title: "Win Rate", value: "\(String(format: "%.1f%%", results.winRate * 100))", change: "", color: .blue)
                MetricCard(title: "Sharpe Ratio", value: String(format: "%.2f", results.sharpeRatio), change: "", color: .purple)
                MetricCard(title: "Max Drawdown", value: "\(String(format: "%.1f%%", results.maxDrawdown * 100))", change: "", color: .orange)
            }

            Text("Best Pattern: \(results.bestPerformingPattern)")
                .font(.caption2)
                .foregroundColor(.green)
        }
    }
}

struct PatternResultsView: View {
    let results: AdvancedBacktestResult

    var body: some View {
        VStack(spacing: 8) {
            ForEach(results.patternResults.prefix(5), id: \.patternName) { pattern in
                HStack {
                    VStack(alignment: .leading) {
                        Text(pattern.patternName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(pattern.trades) trades")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(String(format: "%.1f%%", pattern.winRate * 100))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(pattern.winRate > 0.6 ? .green : .red)
                        Text("Win Rate")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
        }
    }
}

struct MetricsResultsView: View {
    let results: AdvancedBacktestResult

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(title: "Sortino Ratio", value: String(format: "%.2f", results.sortinoRatio), change: "", color: .green)
            MetricCard(title: "Calmar Ratio", value: String(format: "%.2f", results.calmarRatio), change: "", color: .blue)
            MetricCard(title: "Volatility", value: "\(String(format: "%.1f%%", results.volatility * 100))", change: "", color: .orange)
            MetricCard(title: "Beta", value: String(format: "%.2f", results.beta), change: "", color: .purple)
            MetricCard(title: "Alpha", value: "\(String(format: "%.1f%%", results.alpha * 100))", change: "", color: .green)
            MetricCard(title: "Profit Factor", value: String(format: "%.2f", results.profitFactor), change: "", color: .blue)
        }
    }
}

struct MonteCarloResultsView: View {
    let results: AdvancedBacktestResult

    var body: some View {
        if let mcResults = results.monteCarloResults {
            VStack(spacing: 12) {
                Text("Monte Carlo Simulation Results")
                    .font(.subheadline)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    MetricCard(title: "Mean Return", value: "\(String(format: "%.1f%%", mcResults.meanReturn * 100))", change: "", color: .blue)
                    MetricCard(title: "VaR 95%", value: "\(String(format: "%.1f%%", mcResults.valueAtRisk95 * 100))", change: "", color: .red)
                    MetricCard(title: "Prob. of Loss", value: "\(String(format: "%.1f%%", mcResults.probabilityOfLoss * 100))", change: "", color: .orange)
                    MetricCard(title: "Worst Case", value: "\(String(format: "%.1f%%", mcResults.worstCaseScenario * 100))", change: "", color: .red)
                }
            }
        } else {
            Text("No Monte Carlo results available")
                .foregroundColor(.secondary)
        }
    }
}

struct MLInsightsView: View {
    let results: AdvancedBacktestResult

    var body: some View {
        if let mlResults = results.mlInsights {
            VStack(alignment: .leading, spacing: 12) {
                Text("ML Optimization Insights")
                    .font(.subheadline)

                Text("Top optimized patterns:")
                    .font(.caption)
                    .fontWeight(.medium)

                ForEach(Array(mlResults.optimalPatternWeights.prefix(3)), id: \.key) { pattern, weight in
                    HStack {
                        Text(pattern)
                        Spacer()
                        Text("\(String(format: "%.1f%%", weight * 100))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
        } else {
            Text("No ML insights available")
                .foregroundColor(.secondary)
        }
    }
}

// MetricCard is defined in PerformanceAnalyticsView.swift

struct DetailedBacktestResultsView: View {
    let results: AdvancedBacktestResult
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                Text("Detailed backtest analysis and charts would go here")
                    .padding()
            }
            .navigationTitle("Detailed Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Detailed Results")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BacktestingView()
}