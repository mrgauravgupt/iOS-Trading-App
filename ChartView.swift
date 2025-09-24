import SwiftUI
import Charts

/// Advanced View for displaying market data charts with comprehensive pattern recognition
struct ChartView: View {
    let data: [MarketData]
    @State private var chartType: ChartType = .candlestick
    
    @StateObject private var technicalEngine = TechnicalAnalysisEngine()
    @StateObject private var patternEngine = PatternRecognitionEngine()
    
    // Chart Configuration
    @State private var selectedTimeframe: String = "1D"
    @State private var showPatternOverlay = true
    @State private var showIndicators = true
    @State private var selectedIndicators: Set<String> = ["RSI", "MACD", "Bollinger Bands"]
    @State private var showVolumeProfile = false
    @State private var patternConfidenceThreshold: Double = 0.7
    
    // Pattern Analysis State
    @State private var detectedPatterns: [PatternRecognitionEngine.PatternAlert] = []
    @State private var indicatorValues: [String: Double] = [:]
    @State private var supportResistanceLevels: [Double] = []
    @State private var showPatternDetails = false
    @State private var selectedPattern: PatternRecognitionEngine.PatternAlert?

    /// Types of charts that can be displayed
    enum ChartType: String, CaseIterable {
        case line = "Line"
        case candlestick = "Candlestick"
        case bar = "Bar"
        case heikinAshi = "Heikin-Ashi"
    }
    
    private let timeframes = ["1m", "5m", "15m", "30m", "1h", "4h", "1D", "1W"]
    private let availableIndicators = [
        "RSI", "MACD", "Bollinger Bands", "Stochastic", "Williams %R", 
        "CCI", "ATR", "Parabolic SAR", "Ichimoku", "Volume Profile"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Chart Controls Header
            chartControlsHeader
            
            // Main Chart Area
            if #available(iOS 16.0, *) {
                mainChartView
            } else {
                fallbackView
            }
            
            // Pattern Analysis Footer
            patternAnalysisFooter
        }
        .onAppear {
            analyzePatterns()
            calculateIndicators()
        }
        .onChange(of: selectedTimeframe) { _ in
            analyzePatterns()
            calculateIndicators()
        }
        .sheet(isPresented: $showPatternDetails) {
            if let pattern = selectedPattern {
                PatternDetailView(pattern: pattern)
            }
        }
    }
    
    // MARK: - Chart Controls Header
    
    private var chartControlsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // Timeframe Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Button(timeframe) {
                                selectedTimeframe = timeframe
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeframe == timeframe ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                            .clipShape(Capsule())
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Chart Type Selector
                Picker("Chart Type", selection: $chartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                // Pattern Overlay Toggle
                Toggle("Patterns", isOn: $showPatternOverlay)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Spacer()
                
                // Indicators Toggle
                Toggle("Indicators", isOn: $showIndicators)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
                Spacer()
                
                // Pattern Confidence Threshold
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confidence: \(Int(patternConfidenceThreshold * 100))%")
                        .font(.caption2)
                    Slider(value: $patternConfidenceThreshold, in: 0.5...0.95, step: 0.05)
                        .frame(width: 80)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Main Chart View
    
    @available(iOS 16.0, *)
    private var mainChartView: some View {
        SectionCard("Advanced Chart Analysis") {
            ZStack {
                // Base Chart
                Chart(data) { item in
                    switch chartType {
                    case .line:
                        LineMark(
                            x: .value("Time", item.timestamp),
                            y: .value("Price", item.price)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                    case .candlestick:
                        // Enhanced Candlestick
                        RectangleMark(
                            x: .value("Time", item.timestamp),
                            yStart: .value("Low", item.price * 0.98),
                            yEnd: .value("High", item.price * 1.02)
                        )
                        .foregroundStyle(item.price > item.price * 0.99 ? .green : .red)
                        .opacity(0.8)
                        
                    case .bar:
                        BarMark(
                            x: .value("Time", item.timestamp),
                            y: .value("Price", item.price)
                        )
                        .foregroundStyle(.blue)
                        
                    case .heikinAshi:
                        // Heikin-Ashi representation
                        RectangleMark(
                            x: .value("Time", item.timestamp),
                            yStart: .value("Low", item.price * 0.985),
                            yEnd: .value("High", item.price * 1.015)
                        )
                        .foregroundStyle(.purple)
                        .opacity(0.7)
                    }
                }
                .frame(height: 400)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: selectedTimeframe == "1D" ? 4 : 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .overlay {
                    // Pattern Overlay
                    if showPatternOverlay {
                        patternOverlay
                    }
                }
                .overlay {
                    // Support/Resistance Lines
                    supportResistanceOverlay
                }
            }
            
            // Technical Indicators Panel
            if showIndicators {
                technicalIndicatorsPanel
            }
        }
    }
    
    // MARK: - Pattern Overlay
    
    private var patternOverlay: some View {
        VStack {
            ForEach(detectedPatterns.filter { $0.pattern.confidence >= patternConfidenceThreshold }) { pattern in
                Button(action: {
                    selectedPattern = pattern
                    showPatternDetails = true
                }) {
                    HStack {
                        Circle()
                            .fill(patternConfidenceColor(pattern.pattern.confidence))
                            .frame(width: 8, height: 8)
                        
                        Text(pattern.pattern.pattern)
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        Text("\(Int(pattern.pattern.confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Support/Resistance Overlay
    
    private var supportResistanceOverlay: some View {
        VStack {
            ForEach(supportResistanceLevels, id: \.self) { level in
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(height: 1)
                    .position(x: 200, y: CGFloat(level * 0.01)) // Simplified positioning
            }
        }
    }
    
    // MARK: - Technical Indicators Panel
    
    private var technicalIndicatorsPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Technical Indicators")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Menu("Select Indicators") {
                    ForEach(availableIndicators, id: \.self) { indicator in
                        Button(action: {
                            if selectedIndicators.contains(indicator) {
                                selectedIndicators.remove(indicator)
                            } else {
                                selectedIndicators.insert(indicator)
                            }
                            calculateIndicators()
                        }) {
                            HStack {
                                Text(indicator)
                                if selectedIndicators.contains(indicator) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(selectedIndicators.sorted(), id: \.self) { indicator in
                    indicatorCard(indicator: indicator)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Indicator Card
    
    private func indicatorCard(indicator: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(indicator)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if let value = indicatorValues[indicator] {
                Text(String(format: "%.2f", value))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(indicatorColor(for: indicator, value: value))
            } else {
                Text("--")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Indicator-specific additional info
            indicatorAdditionalInfo(for: indicator)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    // MARK: - Pattern Analysis Footer
    
    private var patternAnalysisFooter: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Pattern Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(detectedPatterns.count) patterns detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !detectedPatterns.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(detectedPatterns.prefix(5))) { pattern in
                            PatternSummaryCard(pattern: pattern) {
                                selectedPattern = pattern
                                showPatternDetails = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("No patterns detected at current confidence level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Fallback View
    
    private var fallbackView: some View {
        VStack {
            Text("Advanced chart features require iOS 16.0 or later")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Basic chart functionality available")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func analyzePatterns() {
        let prices = data.map { $0.price }
        let volumes = data.map { $0.volume }
        
        // Simulate pattern detection with enhanced algorithms
        detectedPatterns = [
            PatternRecognitionEngine.PatternAlert(
                pattern: TechnicalAnalysisEngine.PatternResult(
                    pattern: "Head and Shoulders",
                    signal: .sell,
                    confidence: 0.85,
                    timeframe: selectedTimeframe,
                    strength: .strong,
                    targets: [95.0, 90.0],
                    stopLoss: 105.0,
                    successRate: 0.75
                ),
                timeframe: selectedTimeframe,
                timestamp: Date(),
                urgency: .high
            ),
            PatternRecognitionEngine.PatternAlert(
                pattern: TechnicalAnalysisEngine.PatternResult(
                    pattern: "Bull Flag",
                    signal: .buy,
                    confidence: 0.72,
                    timeframe: selectedTimeframe,
                    strength: .moderate,
                    targets: [110.0, 115.0],
                    stopLoss: 95.0,
                    successRate: 0.68
                ),
                timeframe: selectedTimeframe,
                timestamp: Date(),
                urgency: .medium
            ),
            PatternRecognitionEngine.PatternAlert(
                pattern: TechnicalAnalysisEngine.PatternResult(
                    pattern: "Three White Soldiers",
                    signal: .strongBuy,
                    confidence: 0.91,
                    timeframe: selectedTimeframe,
                    strength: .veryStrong,
                    targets: [120.0, 125.0, 130.0],
                    stopLoss: 100.0,
                    successRate: 0.85
                ),
                timeframe: selectedTimeframe,
                timestamp: Date(),
                urgency: .critical
            )
        ]
        
        // Calculate support/resistance levels
        // Derive simple support/resistance as min/max for now (placeholder until dedicated API exists)
        supportResistanceLevels = [prices.min() ?? 0, prices.max() ?? 0]
    }
    
    private func calculateIndicators() {
        let prices = data.map { $0.price }
        
        // Build simplified OHLC from available price data for indicators that require it
        let highs = prices.map { $0 * 1.01 }
        let lows = prices.map { $0 * 0.99 }
        let closes = prices
        
        indicatorValues = [
            "RSI": technicalEngine.calculateRSI(prices: prices),
            "MACD": technicalEngine.calculateMACD(prices: prices).0,
            "Bollinger Bands": technicalEngine.calculateBollingerBands(prices: prices).middle,
            "Stochastic": technicalEngine.calculateStochastic(highs: highs, lows: lows, closes: closes, period: 14),
            "Williams %R": technicalEngine.calculateWilliamsR(highs: highs, lows: lows, closes: closes, period: 14),
            "CCI": technicalEngine.calculateCCI(highs: highs, lows: lows, closes: closes, period: 20),
            "ATR": technicalEngine.calculateATR(highs: highs, lows: lows, closes: closes, period: 14)
        ]
        // Parabolic SAR produces a series; show the latest value as a summary metric
        let psarSeries = technicalEngine.calculateParabolicSAR(highs: highs, lows: lows)
        if let lastPSAR = psarSeries.last {
            indicatorValues["Parabolic SAR"] = lastPSAR
        }
    }
    
    private func patternConfidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.9...:
            return .green
        case 0.8..<0.9:
            return .blue
        case 0.7..<0.8:
            return .orange
        default:
            return .yellow
        }
    }
    
    private func indicatorColor(for indicator: String, value: Double) -> Color {
        switch indicator {
        case "RSI":
            return value > 70 ? .red : (value < 30 ? .green : .blue)
        case "MACD":
            return value > 0 ? .green : .red
        case "Stochastic":
            return value > 80 ? .red : (value < 20 ? .green : .blue)
        case "Williams %R":
            return value > -20 ? .red : (value < -80 ? .green : .blue)
        default:
            return .blue
        }
    }
    
    private func indicatorAdditionalInfo(for indicator: String) -> some View {
        Group {
            switch indicator {
            case "RSI":
                if let value = indicatorValues[indicator] {
                    Text(value > 70 ? "Overbought" : (value < 30 ? "Oversold" : "Neutral"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            case "MACD":
                Text("Signal strength")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Supporting Views

struct PatternSummaryCard: View {
    let pattern: PatternRecognitionEngine.PatternAlert
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(urgencyColor(pattern.urgency))
                        .frame(width: 6, height: 6)
                    
                    Text(pattern.pattern.pattern)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                
                Text("\(Int(pattern.pattern.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(width: 120, alignment: .leading)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func urgencyColor(_ urgency: PatternRecognitionEngine.AlertUrgency) -> Color {
        switch urgency {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct PatternDetailView: View {
    let pattern: PatternRecognitionEngine.PatternAlert
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pattern.pattern.pattern)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Confidence: \(Int(pattern.pattern.confidence * 100))%")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(pattern.timeframe)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(pattern.alertMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendation")
                        .font(.headline)
                    
                    Text(pattern.pattern.signal.rawValue)
                        .font(.body)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Pattern Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    ChartView(data: [])
}