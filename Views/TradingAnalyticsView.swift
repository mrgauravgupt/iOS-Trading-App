import SwiftUI
import Charts

struct TradingAnalyticsView: View {
    @StateObject private var tradingAnalytics = TradingAnalyticsManager()
    @State private var selectedTimeframe: AnalyticsTimeframe = .oneMonth
    @State private var selectedStrategy: String = "All Strategies"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with filters
                HStack {
                    Text("Trading Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.displayName)
                                    .tag(timeframe)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .font(.caption)

                        Picker("Strategy", selection: $selectedStrategy) {
                            Text("All Strategies").tag("All Strategies")
                            ForEach(tradingAnalytics.availableStrategies, id: \.self) { strategy in
                                Text(strategy).tag(strategy)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .font(.caption)
                    }
                }
                .padding(.horizontal)

                // Key Performance Metrics
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    TradingMetricCard(
                        title: "Total Trades",
                        value: "\(tradingAnalytics.totalTrades)",
                        subtitle: "Executed",
                        color: .blue,
                        icon: "chart.bar.fill"
                    )

                    TradingMetricCard(
                        title: "Win Rate",
                        value: String(format: "%.1f%%", tradingAnalytics.winRate * 100),
                        subtitle: "Success rate",
                        color: tradingAnalytics.winRate >= 0.6 ? .green : .orange,
                        icon: "checkmark.circle.fill"
                    )

                    TradingMetricCard(
                        title: "Profit Factor",
                        value: String(format: "%.2f", tradingAnalytics.profitFactor),
                        subtitle: "Gross profit / loss",
                        color: tradingAnalytics.profitFactor >= 1.5 ? .green : tradingAnalytics.profitFactor >= 1.0 ? .orange : .red,
                        icon: "chart.line.uptrend.xyaxis"
                    )

                    TradingMetricCard(
                        title: "Avg Win/Loss",
                        value: String(format: "%.1f", tradingAnalytics.averageWinLossRatio),
                        subtitle: "Winner to loser ratio",
                        color: tradingAnalytics.averageWinLossRatio >= 1.5 ? .green : .orange,
                        icon: "arrow.up.arrow.down"
                    )
                }
                .padding(.horizontal)

                // Trade Timing Analysis
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trade Timing Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(spacing: 16) {
                            if tradingAnalytics.timingAnalysis.isEmpty {
                                Text("Loading timing data...")
                                    .foregroundColor(.secondary)
                                    .frame(height: 150)
                            } else {
                                Chart(tradingAnalytics.timingAnalysis) { timing in
                                    BarMark(
                                        x: .value("Hour", timing.hour),
                                        y: .value("Trades", timing.tradeCount)
                                    )
                                    .foregroundStyle(.blue)

                                    BarMark(
                                        x: .value("Hour", timing.hour),
                                        y: .value("Wins", timing.winCount)
                                    )
                                    .foregroundStyle(.green)
                                }
                                .frame(height: 150)
                                .padding()

                                // Timing Statistics
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                    TimingStatView(
                                        title: "Best Hour",
                                        value: "\(tradingAnalytics.bestTradingHour):00",
                                        subtitle: String(format: "%.1f%% win rate", tradingAnalytics.bestHourWinRate * 100)
                                    )

                                    TimingStatView(
                                        title: "Worst Hour",
                                        value: "\(tradingAnalytics.worstTradingHour):00",
                                        subtitle: String(format: "%.1f%% win rate", tradingAnalytics.worstHourWinRate * 100)
                                    )

                                    TimingStatView(
                                        title: "Peak Volume",
                                        value: "\(tradingAnalytics.peakVolumeHour):00",
                                        subtitle: "\(tradingAnalytics.peakVolumeTrades) trades"
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Entry/Exit Performance
                VStack(alignment: .leading, spacing: 12) {
                    Text("Entry & Exit Performance")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        // Entry Performance
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Entry Accuracy")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text(String(format: "%.1f%%", tradingAnalytics.entryAccuracy * 100))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(tradingAnalytics.entryAccuracy >= 0.7 ? .green : .orange)

                                Text("Within 0.5% of target")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Exit Performance
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Exit Timing")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text(String(format: "%.1f%%", tradingAnalytics.exitTimingAccuracy * 100))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(tradingAnalytics.exitTimingAccuracy >= 0.7 ? .green : .orange)

                                Text("Optimal exit captured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal)

                // Strategy Performance Comparison
                VStack(alignment: .leading, spacing: 12) {
                    Text("Strategy Performance")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(spacing: 16) {
                            if tradingAnalytics.strategyPerformance.isEmpty {
                                Text("Loading strategy data...")
                                    .foregroundColor(.secondary)
                                    .frame(height: 150)
                            } else {
                                Chart(tradingAnalytics.strategyPerformance) { strategy in
                                    BarMark(
                                        x: .value("Strategy", strategy.name),
                                        y: .value("Return", strategy.returnPercentage)
                                    )
                                    .foregroundStyle(by: .value("Strategy", strategy.name))
                                }
                                .frame(height: 150)
                                .padding()

                                // Strategy Details
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(tradingAnalytics.strategyPerformance) { strategy in
                                        StrategyPerformanceRow(strategy: strategy)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Market Condition Performance
                VStack(alignment: .leading, spacing: 12) {
                    Text("Market Condition Performance")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        MarketConditionCard(
                            condition: "Bull Market",
                            winRate: tradingAnalytics.bullMarketWinRate,
                            totalReturn: tradingAnalytics.bullMarketReturn,
                            tradeCount: tradingAnalytics.bullMarketTrades
                        )

                        MarketConditionCard(
                            condition: "Bear Market",
                            winRate: tradingAnalytics.bearMarketWinRate,
                            totalReturn: tradingAnalytics.bearMarketReturn,
                            tradeCount: tradingAnalytics.bearMarketTrades
                        )

                        MarketConditionCard(
                            condition: "Sideways",
                            winRate: tradingAnalytics.sidewaysMarketWinRate,
                            totalReturn: tradingAnalytics.sidewaysMarketReturn,
                            tradeCount: tradingAnalytics.sidewaysMarketTrades
                        )

                        MarketConditionCard(
                            condition: "High Volatility",
                            winRate: tradingAnalytics.highVolatilityWinRate,
                            totalReturn: tradingAnalytics.highVolatilityReturn,
                            tradeCount: tradingAnalytics.highVolatilityTrades
                        )
                    }
                }
                .padding(.horizontal)

                // Risk-Adjusted Metrics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Risk-Adjusted Performance")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        RiskAdjustedMetricCard(
                            title: "Sharpe Ratio",
                            value: String(format: "%.2f", tradingAnalytics.sharpeRatio),
                            subtitle: "Return per unit risk",
                            color: tradingAnalytics.sharpeRatio >= 1.0 ? .green : .orange
                        )

                        RiskAdjustedMetricCard(
                            title: "Sortino Ratio",
                            value: String(format: "%.2f", tradingAnalytics.sortinoRatio),
                            subtitle: "Downside risk only",
                            color: tradingAnalytics.sortinoRatio >= 1.0 ? .green : .orange
                        )

                        RiskAdjustedMetricCard(
                            title: "Calmar Ratio",
                            value: String(format: "%.2f", tradingAnalytics.calmarRatio),
                            subtitle: "Return per max drawdown",
                            color: tradingAnalytics.calmarRatio >= 2.0 ? .green : .orange
                        )

                        RiskAdjustedMetricCard(
                            title: "Information Ratio",
                            value: String(format: "%.2f", tradingAnalytics.informationRatio),
                            subtitle: "Active return efficiency",
                            color: tradingAnalytics.informationRatio >= 0.5 ? .green : .orange
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            tradingAnalytics.loadAnalyticsData(for: selectedTimeframe, strategy: selectedStrategy)
        }
        .onChange(of: selectedTimeframe) { _, newTimeframe in
            tradingAnalytics.loadAnalyticsData(for: newTimeframe, strategy: selectedStrategy)
        }
        .onChange(of: selectedStrategy) { _, newStrategy in
            tradingAnalytics.loadAnalyticsData(for: selectedTimeframe, strategy: newStrategy)
        }
    }
}

// MARK: - Supporting Views

struct TradingMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)

                    Spacer()
                }

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TimingStatView: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StrategyPerformanceRow: View {
    let strategy: StrategyPerformance

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(strategy.name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(String(format: "%.1f%%", strategy.returnPercentage))
                    .font(.caption2)
                    .foregroundColor(strategy.returnPercentage >= 0 ? .green : .red)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(strategy.tradeCount) trades")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(String(format: "%.1f%%", strategy.winRate * 100))
                    .font(.caption2)
                    .foregroundColor(strategy.winRate >= 0.6 ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MarketConditionCard: View {
    let condition: String
    let winRate: Double
    let totalReturn: Double
    let tradeCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(condition)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f%%", winRate * 100))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(winRate >= 0.6 ? .green : .orange)

                        Text("Win Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f%%", totalReturn))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(totalReturn >= 0 ? .green : .red)

                        Text("Return")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("\(tradeCount) trades")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RiskAdjustedMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                Text(value)
                    .font(.title2)
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

// MARK: - Data Models

struct TradeTimingData: Identifiable {
    let id = UUID()
    let hour: Int
    let tradeCount: Int
    let winCount: Int
}

struct StrategyPerformance: Identifiable {
    let id = UUID()
    let name: String
    let returnPercentage: Double
    let winRate: Double
    let tradeCount: Int
}

// MARK: - Analytics Manager

class TradingAnalyticsManager: ObservableObject {
    @Published var totalTrades: Int = 0
    @Published var winRate: Double = 0.0
    @Published var profitFactor: Double = 0.0
    @Published var averageWinLossRatio: Double = 0.0

    @Published var timingAnalysis: [TradeTimingData] = []
    @Published var bestTradingHour: Int = 0
    @Published var bestHourWinRate: Double = 0.0
    @Published var worstTradingHour: Int = 0
    @Published var worstHourWinRate: Double = 0.0
    @Published var peakVolumeHour: Int = 0
    @Published var peakVolumeTrades: Int = 0

    @Published var entryAccuracy: Double = 0.0
    @Published var exitTimingAccuracy: Double = 0.0

    @Published var strategyPerformance: [StrategyPerformance] = []
    @Published var availableStrategies: [String] = []

    @Published var bullMarketWinRate: Double = 0.0
    @Published var bullMarketReturn: Double = 0.0
    @Published var bullMarketTrades: Int = 0

    @Published var bearMarketWinRate: Double = 0.0
    @Published var bearMarketReturn: Double = 0.0
    @Published var bearMarketTrades: Int = 0

    @Published var sidewaysMarketWinRate: Double = 0.0
    @Published var sidewaysMarketReturn: Double = 0.0
    @Published var sidewaysMarketTrades: Int = 0

    @Published var highVolatilityWinRate: Double = 0.0
    @Published var highVolatilityReturn: Double = 0.0
    @Published var highVolatilityTrades: Int = 0

    @Published var sharpeRatio: Double = 0.0
    @Published var sortinoRatio: Double = 0.0
    @Published var calmarRatio: Double = 0.0
    @Published var informationRatio: Double = 0.0

    func loadAnalyticsData(for timeframe: AnalyticsTimeframe, strategy: String) {
        // Simulate loading data - in production, this would fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.generateMockData(for: timeframe, strategy: strategy)
        }
    }

    private func generateMockData(for timeframe: AnalyticsTimeframe, strategy: String) {
        // Mock trading metrics
        self.totalTrades = 247
        self.winRate = 0.68
        self.profitFactor = 1.87
        self.averageWinLossRatio = 1.45

        // Mock timing analysis
        self.timingAnalysis = (9...15).map { hour in
            let tradeCount = Int.random(in: 5...25)
            let winCount = Int.random(in: 3...tradeCount)
            return TradeTimingData(hour: hour, tradeCount: tradeCount, winCount: winCount)
        }

        // Calculate timing statistics
        if let bestHour = timingAnalysis.max(by: { $0.winCount / max($0.tradeCount, 1) < $1.winCount / max($1.tradeCount, 1) }) {
            self.bestTradingHour = bestHour.hour
            self.bestHourWinRate = Double(bestHour.winCount) / Double(bestHour.tradeCount)
        }

        if let worstHour = timingAnalysis.min(by: { $0.winCount / max($0.tradeCount, 1) < $1.winCount / max($1.tradeCount, 1) }) {
            self.worstTradingHour = worstHour.hour
            self.worstHourWinRate = Double(worstHour.winCount) / Double(worstHour.tradeCount)
        }

        if let peakHour = timingAnalysis.max(by: { $0.tradeCount < $1.tradeCount }) {
            self.peakVolumeHour = peakHour.hour
            self.peakVolumeTrades = peakHour.tradeCount
        }

        // Mock entry/exit performance
        self.entryAccuracy = 0.73
        self.exitTimingAccuracy = 0.69

        // Mock strategy performance
        self.availableStrategies = ["Momentum", "Mean Reversion", "Breakout", "Scalping", "Swing"]
        self.strategyPerformance = [
            StrategyPerformance(name: "Momentum", returnPercentage: 24.5, winRate: 0.71, tradeCount: 89),
            StrategyPerformance(name: "Mean Reversion", returnPercentage: 18.2, winRate: 0.65, tradeCount: 76),
            StrategyPerformance(name: "Breakout", returnPercentage: 31.8, winRate: 0.69, tradeCount: 52),
            StrategyPerformance(name: "Scalping", returnPercentage: 12.9, winRate: 0.72, tradeCount: 134),
            StrategyPerformance(name: "Swing", returnPercentage: 27.3, winRate: 0.67, tradeCount: 43)
        ]

        // Mock market condition performance
        self.bullMarketWinRate = 0.71
        self.bullMarketReturn = 28.4
        self.bullMarketTrades = 142

        self.bearMarketWinRate = 0.58
        self.bearMarketReturn = -8.7
        self.bearMarketTrades = 45

        self.sidewaysMarketWinRate = 0.63
        self.sidewaysMarketReturn = 12.1
        self.sidewaysMarketTrades = 38

        self.highVolatilityWinRate = 0.69
        self.highVolatilityReturn = 22.8
        self.highVolatilityTrades = 67

        // Mock risk-adjusted metrics
        self.sharpeRatio = 1.23
        self.sortinoRatio = 1.45
        self.calmarRatio = 2.18
        self.informationRatio = 0.67
    }
}
