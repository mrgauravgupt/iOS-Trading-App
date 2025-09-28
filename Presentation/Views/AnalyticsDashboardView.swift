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
                            value: String(format: "₹%.0f", AnalyticsConfig.risk.var95),
                            subtitle: "1-day loss threshold",
                            color: .orange
                        )

                        VaRMetricCard(
                            confidence: "99%",
                            value: String(format: "₹%.0f", AnalyticsConfig.risk.var99),
                            subtitle: "Extreme loss threshold",
                            color: .red
                        )

                        VaRMetricCard(
                            confidence: "99.9%",
                            value: String(format: "₹%.0f", AnalyticsConfig.risk.var999),
                            subtitle: "Tail risk threshold",
                            color: .purple
                        )

                        VaRMetricCard(
                            confidence: "Expected Shortfall",
                            value: String(format: "₹%.0f", AnalyticsConfig.risk.expectedShortfall),
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
                            loss: AnalyticsConfig.risk.crisis2008Loss,
                            probability: AnalyticsConfig.risk.crisis2008Probability,
                            color: .red
                        )

                        StressTestCard(
                            scenario: "COVID-19 Crash",
                            loss: AnalyticsConfig.risk.covidCrashLoss,
                            probability: AnalyticsConfig.risk.covidCrashProbability,
                            color: .orange
                        )

                        StressTestCard(
                            scenario: "Tech Bubble Burst",
                            loss: AnalyticsConfig.risk.techBubbleLoss,
                            probability: AnalyticsConfig.risk.techBubbleProbability,
                            color: .purple
                        )

                        StressTestCard(
                            scenario: "Interest Rate Shock",
                            loss: AnalyticsConfig.risk.rateShockLoss,
                            probability: AnalyticsConfig.risk.rateShockProbability,
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
                                CorrelationMatrixView(correlations: AnalyticsConfig.risk.correlationMatrix)
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
                                DrawdownChartView(drawdowns: AnalyticsConfig.risk.generateDrawdownHistory(startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, endDate: Date()))
                                    .frame(height: 150)
                                    .padding()

                                // Drawdown Statistics
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                    DrawdownStatView(
                                        title: "Max Drawdown",
                                        value: String(format: "%.1f%%", AnalyticsConfig.risk.maxDrawdown * 100),
                                        subtitle: "Peak to trough"
                                    )

                                    DrawdownStatView(
                                        title: "Avg Drawdown",
                                        value: String(format: "%.1f%%", AnalyticsConfig.risk.averageDrawdown * 100),
                                        subtitle: "Mean decline"
                                    )

                                    DrawdownStatView(
                                        title: "Recovery Time",
                                        value: "\(AnalyticsConfig.risk.averageRecoveryDays)",
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
                            limit: AnalyticsConfig.risk.dailyLossLimit,
                            unit: "₹",
                            color: riskAnalytics.dailyLoss > AnalyticsConfig.risk.dailyLossLimit * 0.8 ? .red : .green
                        )

                        RiskLimitCard(
                            title: "Portfolio VaR Limit",
                            current: riskAnalytics.portfolioVar,
                            limit: AnalyticsConfig.risk.portfolioVarLimit,
                            unit: "₹",
                            color: riskAnalytics.portfolioVar > AnalyticsConfig.risk.portfolioVarLimit * 0.8 ? .orange : .green
                        )

                        RiskLimitCard(
                            title: "Concentration Limit",
                            current: riskAnalytics.maxPositionSize,
                            limit: AnalyticsConfig.risk.maxPositionLimit,
                            unit: "%",
                            color: riskAnalytics.maxPositionSize > AnalyticsConfig.risk.maxPositionLimit * 0.8 ? .orange : .green
                        )

                        RiskLimitCard(
                            title: "Sector Exposure",
                            current: riskAnalytics.maxSectorExposure,
                            limit: AnalyticsConfig.risk.maxSectorLimit,
                            unit: "%",
                            color: riskAnalytics.maxSectorExposure > AnalyticsConfig.risk.maxSectorLimit * 0.8 ? .orange : .green
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
                            accuracy: AnalyticsConfig.ai.bullishEngulfingAccuracy,
                            totalSignals: AnalyticsConfig.ai.bullishEngulfingSignals,
                            profitableTrades: Int(Double(AnalyticsConfig.ai.bullishEngulfingSignals) * AnalyticsConfig.ai.bullishEngulfingAccuracy)
                        )

                        PatternPerformanceCard(
                            pattern: "Bearish Engulfing",
                            accuracy: AnalyticsConfig.ai.bearishEngulfingAccuracy,
                            totalSignals: AnalyticsConfig.ai.bearishEngulfingSignals,
                            profitableTrades: Int(Double(AnalyticsConfig.ai.bearishEngulfingSignals) * AnalyticsConfig.ai.bearishEngulfingAccuracy)
                        )

                        PatternPerformanceCard(
                            pattern: "Double Bottom",
                            accuracy: AnalyticsConfig.ai.doubleBottomAccuracy,
                            totalSignals: AnalyticsConfig.ai.doubleBottomSignals,
                            profitableTrades: Int(Double(AnalyticsConfig.ai.doubleBottomSignals) * AnalyticsConfig.ai.doubleBottomAccuracy)
                        )

                        PatternPerformanceCard(
                            pattern: "Head & Shoulders",
                            accuracy: AnalyticsConfig.ai.headShouldersAccuracy,
                            totalSignals: AnalyticsConfig.ai.headShouldersSignals,
                            profitableTrades: Int(Double(AnalyticsConfig.ai.headShouldersSignals) * AnalyticsConfig.ai.headShouldersAccuracy)
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
                                PredictionAccuracyChart(accuracies: AnalyticsConfig.ai.generatePredictionAccuracyHistory(startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, endDate: Date()))
                                    .frame(height: 150)
                                    .padding()

                                // Accuracy Statistics
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                    AccuracyStatView(
                                        title: "Overall Accuracy",
                                        value: String(format: "%.1f%%", AnalyticsConfig.ai.overallAccuracy * 100),
                                        trend: AnalyticsConfig.ai.accuracyTrend
                                    )

                                    AccuracyStatView(
                                        title: "Bull Predictions",
                                        value: String(format: "%.1f%%", AnalyticsConfig.ai.bullPredictionAccuracy * 100),
                                        trend: AnalyticsConfig.ai.bullAccuracyTrend
                                    )

                                    AccuracyStatView(
                                        title: "Bear Predictions",
                                        value: String(format: "%.1f%%", AnalyticsConfig.ai.bearPredictionAccuracy * 100),
                                        trend: AnalyticsConfig.ai.bearAccuracyTrend
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
                            value: String(format: "%.1f%%", AnalyticsConfig.ai.modelPrecision * 100),
                            subtitle: "True positives / predicted positives",
                            color: .blue
                        )

                        ModelMetricCard(
                            title: "Recall",
                            value: String(format: "%.1f%%", AnalyticsConfig.ai.modelRecall * 100),
                            subtitle: "True positives / actual positives",
                            color: .green
                        )

                        ModelMetricCard(
                            title: "F1-Score",
                            value: String(format: "%.1f%%", AnalyticsConfig.ai.modelF1Score * 100),
                            subtitle: "Harmonic mean of precision/recall",
                            color: .orange
                        )

                        ModelMetricCard(
                            title: "AUC-ROC",
                            value: String(format: "%.3f", AnalyticsConfig.ai.modelAUC),
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
                                LearningProgressChart(progress: AnalyticsConfig.ai.generateLearningProgress(startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, endDate: Date()))
                                    .frame(height: 150)
                                    .padding()

                                // Learning Insights
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recent Improvements")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    ForEach(AnalyticsConfig.ai.recentImprovements, id: \.self) { improvement in
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
                            recommendation: AnalyticsConfig.ai.portfolioRecommendation,
                            confidence: AnalyticsConfig.ai.portfolioConfidence,
                            action: "Rebalance Portfolio"
                        )

                        AIRecommendationCard(
                            title: "Risk Management",
                            recommendation: AnalyticsConfig.ai.riskRecommendation,
                            confidence: AnalyticsConfig.ai.riskConfidence,
                            action: "Adjust Risk Limits"
                        )

                        AIRecommendationCard(
                            title: "Strategy Enhancement",
                            recommendation: AnalyticsConfig.ai.strategyRecommendation,
                            confidence: AnalyticsConfig.ai.strategyConfidence,
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

public struct CorrelationData: Identifiable {
    public let id = UUID()
    public let asset1: String
    public let asset2: String
    public let value: Double
}

public struct DrawdownData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let percentage: Double
}

public struct PredictionAccuracyData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let accuracy: Double
}

public struct LearningProgressData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let accuracy: Double
    public let f1Score: Double
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
        self.var95 = AnalyticsConfig.risk.var95
        self.var99 = AnalyticsConfig.risk.var99
        self.var999 = AnalyticsConfig.risk.var999
        self.expectedShortfall = AnalyticsConfig.risk.expectedShortfall

        self.crisis2008Loss = AnalyticsConfig.risk.crisis2008Loss
        self.crisis2008Probability = AnalyticsConfig.risk.crisis2008Probability
        self.covidCrashLoss = AnalyticsConfig.risk.covidCrashLoss
        self.covidCrashProbability = AnalyticsConfig.risk.covidCrashProbability
        self.techBubbleLoss = AnalyticsConfig.risk.techBubbleLoss
        self.techBubbleProbability = AnalyticsConfig.risk.techBubbleProbability
        self.rateShockLoss = AnalyticsConfig.risk.rateShockLoss
        self.rateShockProbability = AnalyticsConfig.risk.rateShockProbability

        self.correlationMatrix = AnalyticsConfig.risk.correlationMatrix
        self.drawdownHistory = AnalyticsConfig.risk.generateDrawdownHistory(startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, endDate: Date())
        self.maxDrawdown = AnalyticsConfig.risk.maxDrawdown
        self.averageDrawdown = AnalyticsConfig.risk.averageDrawdown
        self.averageRecoveryDays = AnalyticsConfig.risk.averageRecoveryDays

        self.dailyLoss = 8500
        self.dailyLossLimit = AnalyticsConfig.risk.dailyLossLimit
        self.portfolioVar = 28000
        self.portfolioVarLimit = AnalyticsConfig.risk.portfolioVarLimit
        self.maxPositionSize = 12.5
        self.maxPositionLimit = AnalyticsConfig.risk.maxPositionLimit
        self.maxSectorExposure = 28.3
        self.maxSectorLimit = AnalyticsConfig.risk.maxSectorLimit
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
        self.bullishEngulfingAccuracy = AnalyticsConfig.ai.bullishEngulfingAccuracy
        self.bullishEngulfingSignals = AnalyticsConfig.ai.bullishEngulfingSignals
        self.bullishEngulfingProfitable = Int(Double(AnalyticsConfig.ai.bullishEngulfingSignals) * AnalyticsConfig.ai.bullishEngulfingAccuracy)
        self.bearishEngulfingAccuracy = AnalyticsConfig.ai.bearishEngulfingAccuracy
        self.bearishEngulfingSignals = AnalyticsConfig.ai.bearishEngulfingSignals
        self.bearishEngulfingProfitable = Int(Double(AnalyticsConfig.ai.bearishEngulfingSignals) * AnalyticsConfig.ai.bearishEngulfingAccuracy)
        self.doubleBottomAccuracy = AnalyticsConfig.ai.doubleBottomAccuracy
        self.doubleBottomSignals = AnalyticsConfig.ai.doubleBottomSignals
        self.doubleBottomProfitable = Int(Double(AnalyticsConfig.ai.doubleBottomSignals) * AnalyticsConfig.ai.doubleBottomAccuracy)
        self.headShouldersAccuracy = AnalyticsConfig.ai.headShouldersAccuracy
        self.headShouldersSignals = AnalyticsConfig.ai.headShouldersSignals
        self.headShouldersProfitable = Int(Double(AnalyticsConfig.ai.headShouldersSignals) * AnalyticsConfig.ai.headShouldersAccuracy)

        self.predictionAccuracyHistory = AnalyticsConfig.ai.generatePredictionAccuracyHistory(startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, endDate: Date())
        self.overallAccuracy = AnalyticsConfig.ai.overallAccuracy
        self.accuracyTrend = AnalyticsConfig.ai.accuracyTrend
        self.bullPredictionAccuracy = AnalyticsConfig.ai.bullPredictionAccuracy
        self.bullAccuracyTrend = AnalyticsConfig.ai.bullAccuracyTrend
        self.bearPredictionAccuracy = AnalyticsConfig.ai.bearPredictionAccuracy
        self.bearAccuracyTrend = AnalyticsConfig.ai.bearAccuracyTrend

        self.modelPrecision = AnalyticsConfig.ai.modelPrecision
        self.modelRecall = AnalyticsConfig.ai.modelRecall
        self.modelF1Score = AnalyticsConfig.ai.modelF1Score
        self.modelAUC = AnalyticsConfig.ai.modelAUC

        self.learningProgress = AnalyticsConfig.ai.generateLearningProgress(startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, endDate: Date())
        self.recentImprovements = AnalyticsConfig.ai.recentImprovements

        self.portfolioRecommendation = AnalyticsConfig.ai.portfolioRecommendation
        self.portfolioConfidence = AnalyticsConfig.ai.portfolioConfidence
        self.riskRecommendation = AnalyticsConfig.ai.riskRecommendation
        self.riskConfidence = AnalyticsConfig.ai.riskConfidence
        self.strategyRecommendation = AnalyticsConfig.ai.strategyRecommendation
        self.strategyConfidence = AnalyticsConfig.ai.strategyConfidence
    }
}
