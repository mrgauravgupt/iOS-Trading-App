import SwiftUI
import Charts

struct PortfolioAnalyticsView: View {
    @StateObject private var analyticsManager = PortfolioAnalyticsManager()
    @State private var selectedTimeframe: AnalyticsTimeframe = .oneMonth
    @State private var selectedBenchmark: String = "NIFTY 50"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                performanceOverviewGrid
                performanceChart
                sectorAllocationChart
                riskMetricsGrid
                attributionAnalysisChart
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            analyticsManager.loadAnalyticsData(for: selectedTimeframe)
        }
        .onChange(of: selectedTimeframe) { newTimeframe in
            analyticsManager.loadAnalyticsData(for: newTimeframe)
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Portfolio Analytics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()

            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName)
                        .tag(timeframe)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(.caption)
        }
        .padding(.horizontal)
    }

    private var performanceOverviewGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            PerformanceMetricCard(
                title: "Total Return",
                value: String(format: "+₹%.2f", analyticsManager.totalReturn),
                percentage: String(format: "+%.2f%%", analyticsManager.totalReturnPercentage),
                isPositive: analyticsManager.totalReturn >= 0,
                color: analyticsManager.totalReturn >= 0 ? .green : .red
            )

            PerformanceMetricCard(
                title: "Benchmark Return",
                value: String(format: "+₹%.2f", analyticsManager.benchmarkReturn),
                percentage: String(format: "+%.2f%%", analyticsManager.benchmarkReturnPercentage),
                isPositive: analyticsManager.benchmarkReturn >= 0,
                color: .blue
            )

            PerformanceMetricCard(
                title: "Alpha",
                value: String(format: "%.2f%%", analyticsManager.alpha),
                percentage: nil,
                isPositive: analyticsManager.alpha >= 0,
                color: analyticsManager.alpha >= 0 ? .green : .red
            )

            PerformanceMetricCard(
                title: "Beta",
                value: String(format: "%.3f", analyticsManager.beta),
                percentage: nil,
                isPositive: analyticsManager.beta <= 1.0,
                color: analyticsManager.beta <= 1.0 ? .green : .orange
            )
        }
        .padding(.horizontal)
    }

    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Comparison")
                .font(.headline)
                .foregroundColor(.primary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack {
                    if analyticsManager.portfolioPerformance.isEmpty {
                        Text("Loading performance data...")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    } else {
                        Chart {
                            ForEach(analyticsManager.portfolioPerformance) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Portfolio", dataPoint.portfolioValue)
                                )
                                .foregroundStyle(.blue)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                            }

                            ForEach(analyticsManager.benchmarkPerformance) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Benchmark", dataPoint.benchmarkValue)
                                )
                                .foregroundStyle(.gray.opacity(0.7))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            }
                        }
                        .frame(height: 200)
                        .padding()
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var sectorAllocationChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sector Allocation")
                .font(.headline)
                .foregroundColor(.primary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(spacing: 16) {
                    if analyticsManager.sectorAllocation.isEmpty {
                        Text("Loading sector data...")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                    } else {
                        Chart(analyticsManager.sectorAllocation) { sector in
                            if #available(iOS 17.0, *) {
                                SectorMark(
                                    angle: .value("Allocation", sector.percentage),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1
                                )
                                .foregroundStyle(by: .value("Sector", sector.name))
                            } else {
                                // Fallback on earlier versions
                            }
                        }
                        .frame(height: 150)
                        .padding()

                        // Sector Legend
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(analyticsManager.sectorAllocation) { sector in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(sector.color)
                                        .frame(width: 12, height: 12)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sector.name)
                                            .font(.caption)
                                            .fontWeight(.medium)

                                        Text(String(format: "%.1f%%", sector.percentage))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var riskMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Metrics")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                RiskMetricCard(
                    title: "Volatility",
                    value: String(format: "%.2f%%", analyticsManager.volatility * 100),
                    subtitle: "Annualized",
                    color: .orange
                )

                RiskMetricCard(
                    title: "Max Drawdown",
                    value: String(format: "%.2f%%", analyticsManager.maxDrawdown * 100),
                    subtitle: "Peak to trough",
                    color: .red
                )

                RiskMetricCard(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", analyticsManager.sharpeRatio),
                    subtitle: "Risk-adjusted return",
                    color: analyticsManager.sharpeRatio >= 1.0 ? .green : .orange
                )

                RiskMetricCard(
                    title: "Sortino Ratio",
                    value: String(format: "%.2f", analyticsManager.sortinoRatio),
                    subtitle: "Downside risk",
                    color: analyticsManager.sortinoRatio >= 1.0 ? .green : .orange
                )
            }
        }
        .padding(.horizontal)
    }

    private var attributionAnalysisChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Attribution")
                .font(.headline)
                .foregroundColor(.primary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(spacing: 16) {
                    if analyticsManager.attributionData.isEmpty {
                        Text("Loading attribution data...")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                    } else {
                        Chart(analyticsManager.attributionData) { attribution in
                            BarMark(
                                x: .value("Factor", attribution.factor),
                                y: .value("Contribution", attribution.contribution)
                            )
                            .foregroundStyle(attribution.contribution >= 0 ? .green : .red)
                        }
                        .frame(height: 150)
                        .padding()

                        // Attribution Details
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(analyticsManager.attributionData) { attribution in
                                AttributionRowView(attribution: attribution)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let percentage: String?
    let isPositive: Bool
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                if let percentage = percentage {
                    Text(percentage)
                        .font(.caption)
                        .foregroundColor(isPositive ? .green : .red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RiskMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AttributionRowView: View {
    let attribution: AttributionData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(attribution.factor)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(String(format: "%.2f%%", attribution.contribution))
                    .font(.caption2)
                    .foregroundColor(attribution.contribution >= 0 ? .green : .red)
            }

            Spacer()

            Text(String(format: "%.1f%%", attribution.weight))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models



struct PerformanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let portfolioValue: Double
    let benchmarkValue: Double
}

struct SectorAllocation: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}

struct AttributionData: Identifiable {
    let id = UUID()
    let factor: String
    let contribution: Double
    let weight: Double
}

// MARK: - Analytics Manager

class PortfolioAnalyticsManager: ObservableObject {
    @Published var totalReturn: Double = 0.0
    @Published var totalReturnPercentage: Double = 0.0
    @Published var benchmarkReturn: Double = 0.0
    @Published var benchmarkReturnPercentage: Double = 0.0
    @Published var alpha: Double = 0.0
    @Published var beta: Double = 0.0
    @Published var volatility: Double = 0.0
    @Published var maxDrawdown: Double = 0.0
    @Published var sharpeRatio: Double = 0.0
    @Published var sortinoRatio: Double = 0.0

    @Published var portfolioPerformance: [PerformanceDataPoint] = []
    @Published var benchmarkPerformance: [PerformanceDataPoint] = []
    @Published var sectorAllocation: [SectorAllocation] = []
    @Published var attributionData: [AttributionData] = []

    func loadAnalyticsData(for timeframe: AnalyticsTimeframe) {
        // Simulate loading data - in production, this would fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.generateMockData(for: timeframe)
        }
    }

    private func generateMockData(for timeframe: AnalyticsTimeframe) {
        // Mock performance data
        self.totalReturn = 24567.89
        self.totalReturnPercentage = 15.67
        self.benchmarkReturn = 18234.56
        self.benchmarkReturnPercentage = 12.34
        self.alpha = 3.33
        self.beta = 0.87
        self.volatility = 0.18
        self.maxDrawdown = 0.12
        self.sharpeRatio = 1.23
        self.sortinoRatio = 1.45

        // Generate performance chart data
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!

        var portfolioData: [PerformanceDataPoint] = []
        var benchmarkData: [PerformanceDataPoint] = []

        var currentDate = startDate
        var portfolioValue = 100000.0
        var benchmarkValue = 100000.0

        while currentDate <= endDate {
            // Simulate daily returns
            let portfolioReturn = Double.random(in: -0.02...0.03)
            let benchmarkReturn = Double.random(in: -0.015...0.025)

            portfolioValue *= (1 + portfolioReturn)
            benchmarkValue *= (1 + benchmarkReturn)

            portfolioData.append(PerformanceDataPoint(
                date: currentDate,
                portfolioValue: portfolioValue,
                benchmarkValue: benchmarkValue
            ))

            benchmarkData.append(PerformanceDataPoint(
                date: currentDate,
                portfolioValue: portfolioValue,
                benchmarkValue: benchmarkValue
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        self.portfolioPerformance = portfolioData
        self.benchmarkPerformance = benchmarkData

        // Mock sector allocation
        self.sectorAllocation = [
            SectorAllocation(name: "Technology", percentage: 35.2, color: .blue),
            SectorAllocation(name: "Financials", percentage: 25.8, color: .green),
            SectorAllocation(name: "Healthcare", percentage: 15.3, color: .orange),
            SectorAllocation(name: "Consumer", percentage: 12.1, color: .purple),
            SectorAllocation(name: "Energy", percentage: 8.9, color: .red),
            SectorAllocation(name: "Others", percentage: 2.7, color: .gray)
        ]

        // Mock attribution data
        self.attributionData = [
            AttributionData(factor: "Stock Selection", contribution: 4.2, weight: 45.0),
            AttributionData(factor: "Sector Allocation", contribution: 2.8, weight: 30.0),
            AttributionData(factor: "Market Timing", contribution: -1.5, weight: 15.0),
            AttributionData(factor: "Currency", contribution: 0.8, weight: 10.0)
        ]
    }
}
