import SwiftUI
import Charts

struct AgentPerformanceDetailView: View {
    let selectedAgent: AIControlCenterView.AgentType
    @Environment(\.dismiss) private var dismiss
    
    @State private var performanceData: [PerformanceMetric] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Performance Overview
                    performanceOverviewSection
                    
                    // Decision History
                    decisionHistorySection
                    
                    // Learning Metrics
                    learningMetricsSection
                    
                    // Risk Analysis
                    riskAnalysisSection
                }
                .padding()
            }
            .navigationTitle("\(selectedAgent.rawValue) Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPerformanceData()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: agentIcon)
                .font(.title)
                .foregroundColor(agentColor)
                .frame(width: 60, height: 60)
                .background(agentColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(selectedAgent.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(agentDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
        }
    }
    
    // MARK: - Performance Overview Section
    
    private var performanceOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Performance Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if isLoading {
                ProgressView("Loading performance data...")
                    .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    PerformanceMetricCard(
                        title: "Overall Accuracy",
                        value: "\(Int(overallAccuracy))%",
                        percentage: "+2.3%",
                        isPositive: true,
                        color: .green
                    )
                    
                    PerformanceMetricCard(
                        title: "Total Decisions",
                        value: "\(totalDecisions)",
                        percentage: "+15",
                        isPositive: true,
                        color: .blue
                    )
                    
                    PerformanceMetricCard(
                        title: "Win Rate",
                        value: "\(Int(winRate))%",
                        percentage: "+1.8%",
                        isPositive: true,
                        color: .green
                    )
                    
                    PerformanceMetricCard(
                        title: "Average Confidence",
                        value: "\(String(format: "%.1f", avgConfidence * 100))%",
                        percentage: "+0.5%",
                        isPositive: true,
                        color: .orange
                    )
                }
                
                // Performance Trend Chart
                Chart(performanceData) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Accuracy", data.accuracy)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Accuracy", data.accuracy)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Decision History Section
    
    private var decisionHistorySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.purple)
                Text("Recent Decisions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 100)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentDecisions) { decision in
                        DecisionHistoryRow(decision: decision)
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    // MARK: - Learning Metrics Section
    
    private var learningMetricsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                Text("Learning Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                LearningMetricRow(
                    title: "Model Update Frequency",
                    value: "Daily",
                    description: "Last updated: 2 hours ago"
                )
                
                LearningMetricRow(
                    title: "Learning Rate",
                    value: "0.015",
                    description: "Optimal range: 0.01-0.02"
                )
                
                LearningMetricRow(
                    title: "Improvement Rate",
                    value: "+12.3%",
                    description: "Over last 30 days"
                )
                
                LearningMetricRow(
                    title: "Data Quality Score",
                    value: "94.2%",
                    description: "High-quality training data"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Risk Analysis Section
    
    private var riskAnalysisSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "shield")
                    .foregroundColor(.red)
                Text("Risk Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                RiskMetricRow(
                    title: "False Positive Rate",
                    value: "8.2%",
                    riskLevel: .low
                )
                
                RiskMetricRow(
                    title: "Overconfidence Risk",
                    value: "Low",
                    riskLevel: .low
                )
                
                RiskMetricRow(
                    title: "Market Regime Adaptation",
                    value: "Excellent",
                    riskLevel: .low
                )
                
                RiskMetricRow(
                    title: "Data Drift Detection",
                    value: "Active",
                    riskLevel: .low
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // MARK: - Computed Properties
    
    private var agentIcon: String {
        switch selectedAgent {
        case .trader: return "person"
        case .analyzer: return "magnifyingglass"
        case .riskManager: return "shield"
        case .coordinator: return "arrow.triangle.2.circlepath"
        }
    }
    
    private var agentColor: Color {
        switch selectedAgent {
        case .trader: return .blue
        case .analyzer: return .purple
        case .riskManager: return .red
        case .coordinator: return .green
        }
    }
    
    private var agentDescription: String {
        switch selectedAgent {
        case .trader:
            return "Executes automated trading decisions based on AI analysis and risk parameters."
        case .analyzer:
            return "Analyzes market conditions, patterns, and technical indicators in real-time."
        case .riskManager:
            return "Monitors portfolio risk, position sizing, and compliance with risk limits."
        case .coordinator:
            return "Orchestrates multi-agent collaboration and strategy coordination."
        }
    }
    
    private var overallAccuracy: Double {
        // Placeholder - implement actual calculation
        87.3
    }
    
    private var totalDecisions: Int {
        // Placeholder - implement actual calculation
        156
    }
    
    private var winRate: Double {
        // Placeholder - implement actual calculation
        73.5
    }
    
    private var avgConfidence: Double {
        // Placeholder - implement actual calculation
        0.82
    }
    
    private var recentDecisions: [DecisionHistoryItem] {
        // Placeholder data
        [
            DecisionHistoryItem(
                timestamp: Date().addingTimeInterval(-300),
                decision: "BUY NIFTY 25000 CE",
                confidence: 0.85,
                outcome: .success,
                pnl: 125.50
            ),
            DecisionHistoryItem(
                timestamp: Date().addingTimeInterval(-1200),
                decision: "SELL NIFTY 24900 PE",
                confidence: 0.78,
                outcome: .success,
                pnl: 89.20
            ),
            DecisionHistoryItem(
                timestamp: Date().addingTimeInterval(-3600),
                decision: "HOLD Current Positions",
                confidence: 0.92,
                outcome: .neutral,
                pnl: 0.0
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private func loadPerformanceData() {
        // Simulate loading data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.performanceData = [
                PerformanceMetric(date: Date().addingTimeInterval(-7*24*3600), accuracy: 82.1),
                PerformanceMetric(date: Date().addingTimeInterval(-6*24*3600), accuracy: 84.3),
                PerformanceMetric(date: Date().addingTimeInterval(-5*24*3600), accuracy: 86.7),
                PerformanceMetric(date: Date().addingTimeInterval(-4*24*3600), accuracy: 88.2),
                PerformanceMetric(date: Date().addingTimeInterval(-3*24*3600), accuracy: 87.5),
                PerformanceMetric(date: Date().addingTimeInterval(-2*24*3600), accuracy: 89.1),
                PerformanceMetric(date: Date().addingTimeInterval(-1*24*3600), accuracy: 87.3)
            ]
            self.isLoading = false
        }
    }
}

// MARK: - Supporting Data Structures

struct PerformanceMetric: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
}

struct DecisionHistoryItem: Identifiable {
    let id = UUID()
    let timestamp: Date
    let decision: String
    let confidence: Double
    let outcome: Outcome
    let pnl: Double
    
    enum Outcome {
        case success, failure, neutral
    }
}

// MARK: - Supporting Views



struct DecisionHistoryRow: View {
    let decision: DecisionHistoryItem
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: decision.timestamp)
    }
    
    private var outcomeColor: Color {
        switch decision.outcome {
        case .success: return .green
        case .failure: return .red
        case .neutral: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(decision.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Text(decision.decision)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    Text("P&L: \(String(format: "%.2f", decision.pnl))")
                        .font(.caption)
                        .foregroundColor(decision.pnl > 0 ? .green : .red)
                    
                    Spacer()
                    
                    Circle()
                        .fill(outcomeColor)
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct LearningMetricRow: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct RiskMetricRow: View {
    let title: String
    let value: String
    let riskLevel: RiskLevel
    
    enum RiskLevel {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "checkmark.circle.fill"
            case .medium: return "exclamationmark.triangle.fill"
            case .high: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: riskLevel.icon)
                .foregroundColor(riskLevel.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(riskLevel.color)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(riskLevel.color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AgentPerformanceDetailView(selectedAgent: .trader)
}
