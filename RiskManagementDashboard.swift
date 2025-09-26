import SwiftUI

struct RiskManagementDashboard: View {
    @StateObject private var riskManager = AdvancedRiskManager()
    @State private var selectedTimeframe: RiskTimeframe = .daily
    @State private var showStressTest = false
    @State private var portfolioValue: Double = 0.0
    @State private var maxDrawdown: Double = 0.0
    
    enum RiskTimeframe: String, CaseIterable {
        case realtime = "Real-time"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Risk Overview Cards
                    riskOverviewSection
                    
                    // Portfolio Heat Map
                    portfolioHeatMapSection
                    
                    // VaR and Risk Metrics
                    riskMetricsSection
                    
                    // Correlation Matrix
                    correlationMatrixSection
                    
                    // Stress Testing
                    stressTestingSection
                    
                    // Risk Alerts
                    riskAlertsSection
                    
                    // Position Limits
                    positionLimitsSection
                }
                .padding()
            }
            .navigationTitle("Risk Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stress Test") {
                        showStressTest = true
                    }
                }
            }
            .sheet(isPresented: $showStressTest) {
                StressTestView(riskManager: riskManager)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Risk Management")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Portfolio Protection & Analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                riskStatusIndicator
            }
            
            // Timeframe Selector
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(RiskTimeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Divider()
        }
    }
    
    private var riskStatusIndicator: some View {
        VStack {
            Circle()
                .fill(overallRiskLevel.color)
                .frame(width: 16, height: 16)
            
            Text(overallRiskLevel.text)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(overallRiskLevel.color)
        }
    }
    
    private var overallRiskLevel: (color: Color, text: String) {
        let currentRisk = currentRiskScore
        if currentRisk < 0.3 {
            return (.green, "LOW")
        } else if currentRisk < 0.6 {
            return (.yellow, "MEDIUM")
        } else if currentRisk < 0.8 {
            return (.orange, "HIGH")
        } else {
            return (.red, "CRITICAL")
        }
    }
    
    private var currentRiskScore: Double {
        // Calculate based on multiple factors
        return 0.0 // No real data available
    }
    
    // MARK: - Risk Overview Section
    
    private var riskOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.purple)
                Text("Risk Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                RiskMetricCard(
                    title: "Portfolio VaR",
                    value: "N/A",
                    subtitle: "1-Day 95% VaR",
                    trend: .neutral,
                    trendValue: "0%"
                )
                
                RiskMetricCard(
                    title: "Max Drawdown",
                    value: "N/A",
                    subtitle: "Current Period",
                    trend: .neutral,
                    trendValue: "0%"
                )
                
                RiskMetricCard(
                    title: "Sharpe Ratio",
                    value: "N/A",
                    subtitle: "Risk-Adjusted Return",
                    trend: .neutral,
                    trendValue: "0"
                )
                
                RiskMetricCard(
                    title: "Beta",
                    value: "N/A",
                    subtitle: "Market Correlation",
                    trend: .neutral,
                    trendValue: "0"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Portfolio Heat Map Section
    
    private var portfolioHeatMapSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.red)
                Text("Portfolio Heat Map")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("Risk by Position")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if samplePositions.isEmpty {
                Text("No positions available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 80)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                    ForEach(samplePositions, id: \.symbol) { position in
                        PositionHeatCell(position: position)
                    }
                }
            }
            
            // Legend
            HStack {
                ForEach(riskLevels, id: \.level) { riskLevel in
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(riskLevel.color)
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text(riskLevel.level)
                            .font(.caption2)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Risk Metrics Section
    
    private var riskMetricsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gauge")
                    .foregroundColor(.orange)
                Text("Advanced Risk Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                RiskGauge(
                    title: "Value at Risk (VaR)",
                    current: 0.0,
                    threshold: 0.05,
                    format: .percentage
                )
                
                RiskGauge(
                    title: "Expected Shortfall",
                    current: 0.0,
                    threshold: 0.08,
                    format: .percentage
                )
                
                RiskGauge(
                    title: "Portfolio Volatility",
                    current: 0.0,
                    threshold: 0.25,
                    format: .percentage
                )
                
                RiskGauge(
                    title: "Concentration Risk",
                    current: 0.0,
                    threshold: 0.40,
                    format: .percentage
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Correlation Matrix Section
    
    private var correlationMatrixSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "grid.circle.fill")
                    .foregroundColor(.green)
                Text("Correlation Matrix")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button("View Full Matrix") {
                    // Show full correlation matrix
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if sampleCorrelations.isEmpty {
                Text("No correlation data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                CorrelationMatrixView(correlations: sampleCorrelations)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Stress Testing Section
    
    private var stressTestingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Stress Testing")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button("Run Test") {
                    showStressTest = true
                }
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("No stress test data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Risk Alerts Section
    
    private var riskAlertsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("Active Risk Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("\(activeAlerts.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text("No active risk alerts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Position Limits Section
    
    private var positionLimitsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                Text("Position Limits")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Text("No position limits data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Real Data (Empty until integrated with API)
    
    private var samplePositions: [PositionData] {
        [] // No real data available
    }
    
    private var riskLevels: [RiskLevel] {
        [
            RiskLevel(level: "Low", color: .green),
            RiskLevel(level: "Med", color: .yellow),
            RiskLevel(level: "High", color: .orange),
            RiskLevel(level: "Critical", color: .red)
        ]
    }
    
    private var sampleCorrelations: [[Double]] {
        [] // No real data available
    }
    
    private var activeAlerts: [RiskAlert] {
        [] // No real alerts available
    }
}

// MARK: - Supporting Data Structures

struct PositionData {
    let symbol: String
    let risk: Double
}

struct RiskLevel {
    let level: String
    let color: Color
}

struct RiskAlert: Identifiable {
    let id: Int
    let type: AlertType
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
    
    enum AlertType {
        case concentrationRisk, volatilitySpike, drawdownLimit, correlationRisk
    }
    
    enum AlertSeverity {
        case low, medium, high, critical
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - Supporting Views

struct RiskMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let trend: TrendDirection
    let trendValue: String
    
    enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                    Text(trendValue)
                        .font(.caption2)
                }
                .foregroundColor(trend.color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct PositionHeatCell: View {
    let position: PositionData
    
    var body: some View {
        VStack {
            Text(position.symbol)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(riskColor)
        .cornerRadius(6)
    }
    
    private var riskColor: Color {
        if position.risk < 0.2 {
            return .green
        } else if position.risk < 0.4 {
            return .yellow
        } else if position.risk < 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct RiskGauge: View {
    let title: String
    let current: Double
    let threshold: Double
    let format: GaugeFormat
    
    enum GaugeFormat {
        case percentage, decimal, currency
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formattedValue)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(current > threshold ? .red : .green)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(current > threshold ? Color.red : Color.green)
                        .frame(width: geometry.size.width * min(current / threshold, 1.0), height: 8)
                        .cornerRadius(4)
                    
                    // Threshold marker
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * min(threshold / (threshold * 1.2), 1.0))
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var formattedValue: String {
        switch format {
        case .percentage:
            return String(format: "%.1f%%", current * 100)
        case .decimal:
            return String(format: "%.3f", current)
        case .currency:
            return String(format: "$%.0f", current)
        }
    }
}

struct CorrelationMatrixView: View {
    let correlations: [[Double]]
    private let symbols = ["NIFTY", "BANK", "IT", "PHARMA"]
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<correlations.count, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<correlations[row].count, id: \.self) { col in
                        CorrelationCell(
                            value: correlations[row][col],
                            rowSymbol: symbols[row],
                            colSymbol: symbols[col]
                        )
                    }
                }
            }
        }
    }
}

struct CorrelationCell: View {
    let value: Double
    let rowSymbol: String
    let colSymbol: String
    
    var body: some View {
        Text(String(format: "%.2f", value))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(correlationColor)
            .cornerRadius(4)
    }
    
    private var correlationColor: Color {
        let absValue = abs(value)
        if absValue > 0.8 {
            return value > 0 ? .red : .blue
        } else if absValue > 0.6 {
            return value > 0 ? .orange : .cyan
        } else if absValue > 0.4 {
            return value > 0 ? .yellow : .mint
        } else {
            return .gray
        }
    }
}

struct StressTestCard: View {
    let scenario: String
    let portfolioImpact: String
    let worstPosition: String
    let status: TestStatus
    
    enum TestStatus {
        case safe, caution, warning, critical
        
        var color: Color {
            switch self {
            case .safe: return .green
            case .caution: return .yellow
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Portfolio:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(portfolioImpact)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Worst:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(worstPosition)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct RiskAlertCard: View {
    let alert: RiskAlert
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                    .lineLimit(2)
                
                Text(timeFormatter.string(from: alert.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(alert.severity.color)
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct PositionLimitBar: View {
    let title: String
    let current: Double
    let limit: Double
    let symbol: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(utilizationColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(utilizationColor)
                        .frame(width: geometry.size.width * min(current / limit, 1.0), height: 8)
                        .cornerRadius(4)
                    
                    // Warning zone (80%)
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: geometry.size.width * max(0, min(1.0, (current - limit * 0.8) / (limit * 0.2))), height: 8)
                        .offset(x: geometry.size.width * 0.8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(String(format: "%.1f%%", current * 100))")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Limit: \(String(format: "%.1f%%", limit * 100))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var utilizationColor: Color {
        let utilization = current / limit
        if utilization > 0.9 {
            return .red
        } else if utilization > 0.8 {
            return .orange
        } else if utilization > 0.6 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Stress Test View

struct StressTestView: View {
    @ObservedObject var riskManager: AdvancedRiskManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Comprehensive Stress Testing Interface")
                .navigationTitle("Stress Testing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
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
    RiskManagementDashboard()
}