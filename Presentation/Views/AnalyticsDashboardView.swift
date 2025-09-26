import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @State private var selectedAnalyticsTab: AnalyticsTab = .portfolio

    enum AnalyticsTab: String, CaseIterable {
        case portfolio = "Portfolio"
        case trading = "Trading"
        case risk = "Risk"
        case ai = "AI Insights"

        var icon: String {
            switch self {
            case .portfolio: return "chart.pie.fill"
            case .trading: return "chart.bar.fill"
            case .risk: return "shield.fill"
            case .ai: return "brain.head.profile"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Analytics Tab Bar
            HStack(spacing: 0) {
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    AnalyticsTabButton(
                        tab: tab,
                        isSelected: selectedAnalyticsTab == tab,
                        action: { selectedAnalyticsTab = tab }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            // Content Area
            TabView(selection: $selectedAnalyticsTab) {
                PortfolioAnalyticsView()
                    .tag(AnalyticsTab.portfolio)

                TradingAnalyticsView()
                    .tag(AnalyticsTab.trading)

                RiskAnalyticsView()
                    .tag(AnalyticsTab.risk)

                AIInsightsView()
                    .tag(AnalyticsTab.ai)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Supporting Views

struct AnalyticsTabButton: View {
    let tab: AnalyticsDashboardView.AnalyticsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Risk Analytics View

struct RiskAnalyticsView: View {
    @StateObject private var riskAnalytics = RiskAnalyticsManager()
    @State private var selectedTimeframe: AnalyticsTimeframe = .threeMonths

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Risk Analytics")
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

                // VaR Metrics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Value at Risk (VaR)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        VaRMetricCard(
                            confidence: "95%",
                            value: String(format: "₹%.0f", riskAnalytics.var95),
                            subtitle: "1-day loss threshold",
                            color: .orange
                        )

                        VaRMetricCard(
                            confidence: "99%",
                            value: String(format: "₹%.0f", riskAnalytics.var99),
                            subtitle: "Extreme loss threshold",
                            color: .red
                        )

                        VaRMetricCard(
                            confidence: "99.9%",
                            value: String(format: "₹%.0f", riskAnalytics.var999),
                            subtitle: "Tail risk threshold",
                            color: .purple
                        )

                        VaRMetricCard(
                            confidence: "Expected Shortfall",
                            value: String(format: "₹%.0f", riskAnalytics.expectedShortfall),
                            subtitle: "Average loss beyond VaR",
                            color: .gray
                        )
                    }
                }
                .padding(.horizontal)

                // Stress Testing Results
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stress Testing Scenarios")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        StressTestCard(
                            scenario: "2008 Crisis",
                            loss: riskAnalytics.crisis2008Loss,
                            probability: riskAnalytics.crisis2008Probability,
                            color: .red
                        )

                        StressTestCard(
                            scenario: "COVID-19 Crash",
                            loss: riskAnalytics.covidCrashLoss,
                            probability: riskAnalytics.covidCrashProbability,
                            color: .orange
                        )

                        StressTestCard(
                            scenario: "Tech Bubble Burst",
                            loss: riskAnalytics.techBubbleLoss,
                            probability: riskAnalytics.techBubbleProbability,
                            color: .purple
                        )

                        StressTestCard(
                            scenario: "Interest Rate Shock",
                            loss: riskAnalytics.rateShockLoss,
                            probability: riskAnalytics.rateShockProbability,
                            color: .blue
                        )
                    }
                }
                .padding(.horizontal)

                // Correlation Analysis
                VStack(alignment: .leading, spacing: 12) {
                    Text("Asset Correlations")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(spacing: 16) {
                            if riskAnalytics.correlationMatrix.isEmpty {
                                Text("Loading correlation data...")
                                    .foregroundColor(.secondary)
                                    .frame(height: 150)
                            } else {
                                CorrelationMatrixView(correlations: riskAnalytics.correlationMatrix)
                                    .frame(height: 200)
                                    .padding()

                                // Correlation Insights
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Key Insights")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 8, height: 8)

                                        Text("Low correlation pairs offer diversification")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.red)
                                            .frame(width: 8, height: 8)

                                        Text("High correlation increases portfolio risk")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Drawdown Analysis
                VStack(alignment: .leading, spacing: 12) {
                    Text("Drawdown Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(spacing: 16) {
                            if riskAnalytics.drawdownHistory.isEmpty {
                                Text("Loading drawdown data...")
                                    .foregroundColor(.secondary)
                                    .frame(height: 150)
                            } else {
                                DrawdownChartView(drawdowns: riskAnalytics.drawdownHistory)
                                    .frame(height: 150)
                                    .padding()

                                // Drawdown Statistics
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                    DrawdownStatView(
                                        title: "Max Drawdown",
                                        value: String(format: "%.1f%%", riskAnalytics.maxDrawdown * 100),
                                        subtitle: "Peak to trough"
                                    )

                                    DrawdownStatView(
                                        title: "Avg Drawdown",
                                        value: String(format: "%.1f%%", riskAnalytics.averageDrawdown * 100),
                                        subtitle: "Mean decline"
                                    )

                                    DrawdownStatView(
                                        title: "Recovery Time",
                                        value: "\(riskAnalytics.averageRecoveryDays)",
                                        subtitle: "Days to recover"
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Risk Limits & Alerts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Risk Limits & Alerts")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        RiskLimitCard(
                            title: "Daily Loss Limit",
                            current: riskAnalytics.dailyLoss,
                            limit: riskAnalytics.dailyLossLimit,
                            unit: "₹",
                            color: riskAnalytics.dailyLoss > riskAnalytics.dailyLossLimit * 0.8 ? .red : .green
                        )

                        RiskLimitCard(
                            title: "Portfolio VaR Limit",
                            current: riskAnalytics.portfolioVar,
                            limit: riskAnalytics.portfolioVarLimit,
                            unit: "₹",
                            color: riskAnalytics.portfolioVar > riskAnalytics.portfolioVarLimit * 0.8 ? .orange : .green
                        )

                        RiskLimitCard(
                            title: "Concentration Limit",
                            current: riskAnalytics.maxPositionSize,
                            limit: riskAnalytics.maxPositionLimit,
                            unit: "%",
                            color: riskAnalytics.maxPositionSize > riskAnalytics.maxPositionLimit * 0.8 ? .orange : .green
                        )

                        RiskLimitCard(
                            title: "Sector Exposure",
                            current: riskAnalytics.maxSectorExposure,
                            limit: riskAnalytics.maxSectorLimit,
                            unit: "%",
                            color: riskAnalytics.maxSectorExposure > riskAnalytics.maxSectorLimit * 0.8 ? .orange : .green
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            riskAnalytics.loadRiskData(for: selectedTimeframe)
        }
        .onChange(of: selectedTimeframe) { _, newTimeframe in
            riskAnalytics.loadRiskData(for: newTimeframe)
        }
    }
}

// MARK: - AI Insights View

struct AIInsightsView: View {
    @StateObject private var aiInsights = AIInsightsManager()
    @State private var selectedTimeframe: AnalyticsTimeframe = .oneMonth

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("AI Insights & Predictions")
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

                // Pattern Performance Analytics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pattern Recognition Performance")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        PatternPerformanceCard(
                            pattern: "Bullish Engulfing",
                            accuracy: aiInsights.bullishEngulfingAccuracy,
                            totalSignals: aiInsights.bullishEngulfingSignals,
                            profitableTrades: aiInsights.bullishEngulfingProfitable
                        )

                        PatternPerformanceCard(
                            pattern: "Bearish Engulfing",
                            accuracy: aiInsights.bearishEngulfingAccuracy,
                            totalSignals: aiInsights.bearishEngulfingSignals,
                            profitableTrades: aiInsights.bearishEngulfingProfitable
                        )

                        PatternPerformanceCard(
                            pattern: "Double Bottom",
                            accuracy: aiInsights.doubleBottomAccuracy,
                            totalSignals: aiInsights.doubleBottomSignals,
                            profitableTrades: aiInsights.doubleBottomProfitable
                        )

                        PatternPerformanceCard(
                            pattern: "Head & Shoulders",
                            accuracy: aiInsights.headShouldersAccuracy,
                            totalSignals: aiInsights.headShouldersSignals,
                            profitableTrades: aiInsights.headShouldersProfitable
                        )
                    }
                }
                .padding(.horizontal)

                // Prediction Accuracy Tracking
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prediction Accuracy Over Time")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(spacing: 16) {
                            if aiInsights.predictionAccuracyHistory.isEmpty {
                                Text("Loading prediction data...")
                                    .foregroundColor(.secondary)
                                    .frame(height: 150)
                            } else {
                                PredictionAccuracyChart(accuracies: aiInsights.predictionAccuracyHistory)
                                    .frame(height: 150)
                                    .padding()

                                // Accuracy Statistics
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                    AccuracyStatView(
                                        title: "Overall Accuracy",
                                        value: String(format: "%.1f%%", aiInsights.overallAccuracy * 100),
                                        trend: aiInsights.accuracyTrend
                                    )

                                    AccuracyStatView(
                                        title: "Bull Predictions",
                                        value: String(format: "%.1f%%", aiInsights.bullPredictionAccuracy * 100),
                                        trend: aiInsights.bullAccuracyTrend
                                    )

                                    AccuracyStatView(
                                        title: "Bear Predictions",
                                        value: String(format: "%.1f%%", aiInsights.bearPredictionAccuracy * 100),
                                        trend: aiInsights.bearAccuracyTrend
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Model Performance Metrics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Model Performance Metrics")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ModelMetricCard(
                            title: "Precision",
                            value: String(format: "%.1f%%", aiInsights.modelPrecision * 100),
                            subtitle: "True positives / predicted positives",
                            color: .blue
                        )

                        ModelMetricCard(
                            title: "Recall",
                            value: String(format: "%.1f%%", aiInsights.modelRecall * 100),
                            subtitle: "True positives / actual positives",
                            color: .green
                        )

                        ModelMetricCard(
                            title: "F1-Score",
                            value: String(format: "%.1f%%", aiInsights.modelF1Score * 100),
                            subtitle: "Harmonic mean of precision/recall",
                            color: .orange
                        )

                        ModelMetricCard(
                            title: "AUC-ROC",
                            value: String(format: "%.3f", aiInsights.modelAUC),
                            subtitle: "Area under ROC curve",
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal)

                // Learning Progress Dashboard
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Learning Progress")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(spacing: 16) {
                            if aiInsights.learningProgress.isEmpty {
                                Text("Loading learning data...")
                                    .foregroundColor(.secondary)
                                    .frame(height: 150)
                            } else {
                                LearningProgressChart(progress: aiInsights.learningProgress)
                                    .frame(height: 150)
                                    .padding()

                                // Learning Insights
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recent Improvements")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    ForEach(aiInsights.recentImprovements, id: \.self) { improvement in
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)

                                            Text(improvement)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // AI Recommendations
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Recommendations")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                        AIRecommendationCard(
                            title: "Portfolio Optimization",
                            recommendation: aiInsights.portfolioRecommendation,
                            confidence: aiInsights.portfolioConfidence,
                            action: "Rebalance Portfolio"
                        )

                        AIRecommendationCard(
                            title: "Risk Management",
                            recommendation: aiInsights.riskRecommendation,
                            confidence: aiInsights.riskConfidence,
                            action: "Adjust Risk Limits"
                        )

                        AIRecommendationCard(
                            title: "Strategy Enhancement",
                            recommendation: aiInsights.strategyRecommendation,
                            confidence: aiInsights.strategyConfidence,
                            action: "Update Trading Rules"
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            aiInsights.loadInsightsData(for: selectedTimeframe)
        }
        .onChange(of: selectedTimeframe) { _, newTimeframe in
            aiInsights.loadInsightsData(for: newTimeframe)
        }
    }
}

// MARK: - Supporting Views for Risk Analytics

struct VaRMetricCard: View {
    let confidence: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(confidence)
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

struct StressTestCard: View {
    let scenario: String
    let loss: Double
    let probability: Double
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(scenario)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(String(format: "-₹%.0f", abs(loss)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)

                Text(String(format: "%.1f%% probability", probability * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CorrelationMatrixView: View {
    let correlations: [CorrelationData]

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Assets")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .leading)

                ForEach(correlations.prefix(4)) { correlation in
                    Text(correlation.asset2.prefix(3))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 40)
                }
            }

            // Matrix rows
            ForEach(correlations.prefix(4)) { correlation in
                HStack {
                    Text(correlation.asset1.prefix(3))
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)

                    ForEach(correlations.filter { $0.asset1 == correlation.asset1 }.prefix(4)) { corr in
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForCorrelation(corr.value))
                                .frame(width: 32, height: 24)

                            Text(String(format: "%.1f", corr.value))
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40)
                    }
                }
            }
        }
    }

    private func colorForCorrelation(_ value: Double) -> Color {
        if value >= 0.7 { return .red }
        else if value >= 0.3 { return .orange }
        else if value <= -0.7 { return .blue }
        else if value <= -0.3 { return .purple }
        else { return .green }
    }
}

struct DrawdownChartView: View {
    let drawdowns: [DrawdownData]

    var body: some View {
        Chart(drawdowns) { drawdown in
            AreaMark(
                x: .value("Date", drawdown.date),
                y: .value("Drawdown", drawdown.percentage)
            )
            .foregroundStyle(.red.opacity(0.3))

            LineMark(
                x: .value("Date", drawdown.date),
                y: .value("Drawdown", drawdown.percentage)
            )
            .foregroundStyle(.red)
        }
    }
}

struct DrawdownStatView: View {
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

struct RiskLimitCard: View {
    let title: String
    let current: Double
    let limit: Double
    let unit: String
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
                    .foregroundColor(.primary)

                HStack {
                    Text("\(unit)\(String(format: "%.0f", current))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)

                    Text("/ \(unit)\(String(format: "%.0f", limit))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: min(geometry.size.width * (current / limit), geometry.size.width), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Supporting Views for AI Insights

struct PatternPerformanceCard: View {
    let pattern: String
    let accuracy: Double
    let totalSignals: Int
    let profitableTrades: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(pattern)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(String(format: "%.1f%%", accuracy * 100))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(accuracy >= 0.6 ? .green : .orange)

                HStack {
                    Text("\(profitableTrades)/\(totalSignals)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("trades")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PredictionAccuracyChart: View {
    let accuracies: [PredictionAccuracyData]

    var body: some View {
        Chart(accuracies) { accuracy in
            LineMark(
                x: .value("Date", accuracy.date),
                y: .value("Accuracy", accuracy.accuracy)
            )
            .foregroundStyle(.blue)

            PointMark(
                x: .value("Date", accuracy.date),
                y: .value("Accuracy", accuracy.accuracy)
            )
            .foregroundStyle(.blue)
        }
    }
}

struct AccuracyStatView: View {
    let title: String
    let value: String
    let trend: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(trend >= 0 ? .green : .red)
            }

            Text(String(format: "%.1f%%", abs(trend)))
                .font(.caption2)
                .foregroundColor(trend >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModelMetricCard: View {
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
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct LearningProgressChart: View {
    let progress: [LearningProgressData]

    var body: some View {
        Chart(progress) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Accuracy", dataPoint.accuracy)
            )
            .foregroundStyle(.green)

            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("F1Score", dataPoint.f1Score)
            )
            .foregroundStyle(.blue)
        }
    }
}

struct AIRecommendationCard: View {
    let title: String
    let recommendation: String
    let confidence: Double
    let action: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.caption)
                        Text(String(format: "%.0f%%", confidence * 100))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(confidence >= 0.8 ? .green : confidence >= 0.6 ? .orange : .red)
                    }
                }

                Text(recommendation)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                Button(action: {
                    // Handle recommendation action
                }) {
                    Text(action)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Data Models

struct CorrelationData: Identifiable {
    let id = UUID()
    let asset1: String
    let asset2: String
    let value: Double
}

struct DrawdownData: Identifiable {
    let id = UUID()
    let date: Date
    let percentage: Double
}

struct PredictionAccuracyData: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
}

struct LearningProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
    let f1Score: Double
}

// MARK: - Analytics Managers

class RiskAnalyticsManager: ObservableObject {
    @Published var var95: Double = 0.0
    @Published var var99: Double = 0.0
    @Published var var999: Double = 0.0
    @Published var expectedShortfall: Double = 0.0

    @Published var crisis2008Loss: Double = 0.0
    @Published var crisis2008Probability: Double = 0.0
    @Published var covidCrashLoss: Double = 0.0
    @Published var covidCrashProbability: Double = 0.0
    @Published var techBubbleLoss: Double = 0.0
    @Published var techBubbleProbability: Double = 0.0
    @Published var rateShockLoss: Double = 0.0
    @Published var rateShockProbability: Double = 0.0

    @Published var correlationMatrix: [CorrelationData] = []
    @Published var drawdownHistory: [DrawdownData] = []
    @Published var maxDrawdown: Double = 0.0
    @Published var averageDrawdown: Double = 0.0
    @Published var averageRecoveryDays: Int = 0

    @Published var dailyLoss: Double = 0.0
    @Published var dailyLossLimit: Double = 0.0
    @Published var portfolioVar: Double = 0.0
    @Published var portfolioVarLimit: Double = 0.0
    @Published var maxPositionSize: Double = 0.0
    @Published var maxPositionLimit: Double = 0.0
    @Published var maxSectorExposure: Double = 0.0
    @Published var maxSectorLimit: Double = 0.0

    func loadRiskData(for timeframe: AnalyticsTimeframe) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.generateMockRiskData()
        }
    }

    private func generateMockRiskData() {
        self.var95 = 25000
        self.var99 = 45000
        self.var999 = 75000
        self.expectedShortfall = 55000

        self.crisis2008Loss = 85000
        self.crisis2008Probability = 0.05
        self.covidCrashLoss = 65000
        self.covidCrashProbability = 0.08
        self.techBubbleLoss = 55000
        self.techBubbleProbability = 0.03
        self.rateShockLoss = 35000
        self.rateShockProbability = 0.12

        self.correlationMatrix = [
            CorrelationData(asset1: "NIFTY", asset2: "NIFTY", value: 1.0),
            CorrelationData(asset1: "NIFTY", asset2: "BANKNIFTY", value: 0.75),
            CorrelationData(asset1: "NIFTY", asset2: "TECH", value: 0.82),
            CorrelationData(asset1: "NIFTY", asset2: "FINANCE", value: 0.68),
            CorrelationData(asset1: "BANKNIFTY", asset2: "NIFTY", value: 0.75),
            CorrelationData(asset1: "BANKNIFTY", asset2: "BANKNIFTY", value: 1.0),
            CorrelationData(asset1: "BANKNIFTY", asset2: "TECH", value: 0.45),
            CorrelationData(asset1: "BANKNIFTY", asset2: "FINANCE", value: 0.89),
            CorrelationData(asset1: "TECH", asset2: "NIFTY", value: 0.82),
            CorrelationData(asset1: "TECH", asset2: "BANKNIFTY", value: 0.45),
            CorrelationData(asset1: "TECH", asset2: "TECH", value: 1.0),
            CorrelationData(asset1: "TECH", asset2: "FINANCE", value: 0.52),
            CorrelationData(asset1: "FINANCE", asset2: "NIFTY", value: 0.68),
            CorrelationData(asset1: "FINANCE", asset2: "BANKNIFTY", value: 0.89),
            CorrelationData(asset1: "FINANCE", asset2: "TECH", value: 0.52),
            CorrelationData(asset1: "FINANCE", asset2: "FINANCE", value: 1.0)
        ]

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!

        var drawdowns: [DrawdownData] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let drawdown = Double.random(in: -0.15...0.0)
            drawdowns.append(DrawdownData(date: currentDate, percentage: drawdown))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        self.drawdownHistory = drawdowns
        self.maxDrawdown = 0.12
        self.averageDrawdown = 0.045
        self.averageRecoveryDays = 18

        self.dailyLoss = 8500
        self.dailyLossLimit = 15000
        self.portfolioVar = 28000
        self.portfolioVarLimit = 35000
        self.maxPositionSize = 12.5
        self.maxPositionLimit = 15.0
        self.maxSectorExposure = 28.3
        self.maxSectorLimit = 30.0
    }
}

class AIInsightsManager: ObservableObject {
    @Published var bullishEngulfingAccuracy: Double = 0.0
    @Published var bullishEngulfingSignals: Int = 0
    @Published var bullishEngulfingProfitable: Int = 0
    @Published var bearishEngulfingAccuracy: Double = 0.0
    @Published var bearishEngulfingSignals: Int = 0
    @Published var bearishEngulfingProfitable: Int = 0
    @Published var doubleBottomAccuracy: Double = 0.0
    @Published var doubleBottomSignals: Int = 0
    @Published var doubleBottomProfitable: Int = 0
    @Published var headShouldersAccuracy: Double = 0.0
    @Published var headShouldersSignals: Int = 0
    @Published var headShouldersProfitable: Int = 0

    @Published var predictionAccuracyHistory: [PredictionAccuracyData] = []
    @Published var overallAccuracy: Double = 0.0
    @Published var accuracyTrend: Double = 0.0
    @Published var bullPredictionAccuracy: Double = 0.0
    @Published var bullAccuracyTrend: Double = 0.0
    @Published var bearPredictionAccuracy: Double = 0.0
    @Published var bearAccuracyTrend: Double = 0.0

    @Published var modelPrecision: Double = 0.0
    @Published var modelRecall: Double = 0.0
    @Published var modelF1Score: Double = 0.0
    @Published var modelAUC: Double = 0.0

    @Published var learningProgress: [LearningProgressData] = []
    @Published var recentImprovements: [String] = []

    @Published var portfolioRecommendation: String = ""
    @Published var portfolioConfidence: Double = 0.0
    @Published var riskRecommendation: String = ""
    @Published var riskConfidence: Double = 0.0
    @Published var strategyRecommendation: String = ""
    @Published var strategyConfidence: Double = 0.0

    func loadInsightsData(for timeframe: AnalyticsTimeframe) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.generateMockInsightsData()
        }
    }

    private func generateMockInsightsData() {
        self.bullishEngulfingAccuracy = 0.68
        self.bullishEngulfingSignals = 45
        self.bullishEngulfingProfitable = 31
        self.bearishEngulfingAccuracy = 0.72
        self.bearishEngulfingSignals = 38
        self.bearishEngulfingProfitable = 27
        self.doubleBottomAccuracy = 0.61
        self.doubleBottomSignals = 23
        self.doubleBottomProfitable = 14
        self.headShouldersAccuracy = 0.75
        self.headShouldersSignals = 16
        self.headShouldersProfitable = 12

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!

        var accuracies: [PredictionAccuracyData] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let accuracy = Double.random(in: 0.55...0.75)
            accuracies.append(PredictionAccuracyData(date: currentDate, accuracy: accuracy))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        self.predictionAccuracyHistory = accuracies
        self.overallAccuracy = 0.67
        self.accuracyTrend = 2.3
        self.bullPredictionAccuracy = 0.71
        self.bullAccuracyTrend = 1.8
        self.bearPredictionAccuracy = 0.63
        self.bearAccuracyTrend = -0.5

        self.modelPrecision = 0.69
        self.modelRecall = 0.65
        self.modelF1Score = 0.67
        self.modelAUC = 0.734

        var progress: [LearningProgressData] = []
        currentDate = startDate

        while currentDate <= endDate {
            let accuracy = Double.random(in: 0.60...0.75)
            let f1Score = Double.random(in: 0.62...0.72)
            progress.append(LearningProgressData(date: currentDate, accuracy: accuracy, f1Score: f1Score))
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
        }

        self.learningProgress = progress
        self.recentImprovements = [
            "Improved pattern recognition accuracy by 3.2%",
            "Enhanced feature engineering for better signal quality",
            "Optimized model hyperparameters for reduced overfitting",
            "Added sentiment analysis integration for market context"
        ]

        self.portfolioRecommendation = "Consider increasing allocation to Technology sector based on momentum analysis and reduce exposure to cyclical sectors."
        self.portfolioConfidence = 0.82
        self.riskRecommendation = "Current portfolio volatility is within acceptable limits. Consider implementing trailing stop losses for large positions."
        self.riskConfidence = 0.78
        self.strategyRecommendation = "Switch to momentum-based strategies during high volatility periods. Current mean-reversion approach showing reduced effectiveness."
        self.strategyConfidence = 0.71
    }
}
