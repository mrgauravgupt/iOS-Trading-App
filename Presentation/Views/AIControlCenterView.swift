import SwiftUI

struct AIControlCenterView: View {
    @StateObject private var aiTrader = AIAgentTrader()
    @StateObject private var marketAnalyzer = MarketAnalysisAgent(name: "Market Analysis Agent")
    @StateObject private var riskManager = RiskManagementAgent(name: "Risk Management Agent")
    @StateObject private var suggestionManager = TradeSuggestionManager.shared
    
    @State private var isAITradingEnabled = false
    @State private var selectedAgent: AgentType = .trader
    @State private var showPerformanceDetails = false
    @State private var showManualOverride = false
    
    enum AgentType: String, CaseIterable {
        case trader = "AI Trader"
        case analyzer = "Market Analyzer"
        case riskManager = "Risk Manager"
        case coordinator = "Agent Coordinator"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // AI Trading Master Control
                    masterControlSection
                    
                    // Agent Performance Grid
                    agentPerformanceGrid
                    
                    // Learning Progress Section
                    learningProgressSection
                    
                    // Strategy Optimization Controls
                    strategyOptimizationSection
                    
                    // Manual Override Panel
                    manualOverrideSection
                    
                    // Trade Suggestions Statistics
                    tradeSuggestionsStatsSection
                    
                    // Real-time Decisions
                    realtimeDecisionsSection
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("AI Control Center")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            // TODO: Implement these views
            // .sheet(isPresented: $showPerformanceDetails) {
            //     AgentPerformanceDetailView(selectedAgent: selectedAgent)
            // }
            // .sheet(isPresented: $showManualOverride) {
            //     ManualOverrideView(aiTrader: aiTrader)
            // }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)

                VStack(alignment: .leading) {
                    Text("AI Control Center")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Text("Multi-Agent Trading System")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                systemStatusIndicator
            }

            Divider()
        }
    }
    
    private var systemStatusIndicator: some View {
        VStack {
            Circle()
                .fill(isAITradingEnabled ? Color.green : Color.red)
                .frame(width: 12, height: 12)

            Text(isAITradingEnabled ? "ACTIVE" : "INACTIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(isAITradingEnabled ? .green : .red)
        }
    }
    
    // MARK: - Master Control Section
    
    private var masterControlSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "power")
                    .foregroundColor(.blue)
                Text("Master Controls")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                // AI Trading Toggle
                HStack {
                    VStack(alignment: .leading) {
                        Text("AI Auto-Trading")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Enable autonomous trading decisions")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $suggestionManager.autoTradeEnabled)
                        .scaleEffect(1.2)
                        .onChange(of: suggestionManager.autoTradeEnabled) { _, _ in
                            suggestionManager.toggleAutoTrade()
                            isAITradingEnabled = suggestionManager.autoTradeEnabled
                        }
                }
                
                // AI Trading Mode Display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Mode: \(suggestionManager.aiTradingMode.rawValue)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(suggestionManager.autoTradeEnabled ? .green : .orange)

                        Text(suggestionManager.aiTradingMode.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Risk Level Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Risk Tolerance")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Conservative")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }

                    Slider(value: .constant(0.3), in: 0...1)
                        .accentColor(.blue)
                }
                
                // Emergency Stop Button
                Button(action: {
                    emergencyStop()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("EMERGENCY STOP")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Agent Performance Grid
    
    private var agentPerformanceGrid: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.orange)
                Text("Agent Performance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()

                Button("Details") {
                    showPerformanceDetails = true
                }
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AgentPerformanceCard(
                    agentName: "AI Trader",
                    performance: 87.3,
                    status: .active,
                    decisions: 156,
                    accuracy: 0.73
                )

                AgentPerformanceCard(
                    agentName: "Market Analyzer",
                    performance: 92.1,
                    status: .active,
                    decisions: 342,
                    accuracy: 0.85
                )

                AgentPerformanceCard(
                    agentName: "Risk Manager",
                    performance: 95.8,
                    status: .active,
                    decisions: 89,
                    accuracy: 0.91
                )

                AgentPerformanceCard(
                    agentName: "Strategy Selector",
                    performance: 78.4,
                    status: .learning,
                    decisions: 67,
                    accuracy: 0.68
                )
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Learning Progress Section
    
    private var learningProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.green)
                Text("Learning Progress")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                LearningProgressBar(
                    title: "Pattern Recognition",
                    progress: 0.78,
                    improvement: "+12.3%"
                )

                LearningProgressBar(
                    title: "Risk Assessment",
                    progress: 0.91,
                    improvement: "+5.7%"
                )

                LearningProgressBar(
                    title: "Market Timing",
                    progress: 0.65,
                    improvement: "+23.1%"
                )

                LearningProgressBar(
                    title: "Strategy Selection",
                    progress: 0.72,
                    improvement: "+8.9%"
                )
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Strategy Optimization Section
    
    private var strategyOptimizationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.purple)
                Text("Strategy Optimization")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()

                Button("Optimize") {
                    optimizeStrategies()
                }
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                OptimizationMetric(
                    name: "Pattern Confidence Threshold",
                    currentValue: "67%",
                    optimizedValue: "73%",
                    improvement: "+8.9%"
                )

                OptimizationMetric(
                    name: "Risk-Reward Ratio",
                    currentValue: "1:2.1",
                    optimizedValue: "1:2.4",
                    improvement: "+14.3%"
                )

                OptimizationMetric(
                    name: "Position Sizing",
                    currentValue: "2.3%",
                    optimizedValue: "1.8%",
                    improvement: "+11.7%"
                )
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Trade Suggestions Statistics Section
    
    private var tradeSuggestionsStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Trade Suggestions Statistics")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(suggestionManager.suggestionHistory.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("Total Suggestions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    Text("\(suggestionManager.suggestionHistory.filter { $0.isExecuted }.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("Executed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    let executionRate = suggestionManager.suggestionHistory.isEmpty ? 0.0 : 
                        Double(suggestionManager.suggestionHistory.filter { $0.isExecuted }.count) / 
                        Double(suggestionManager.suggestionHistory.count) * 100
                    Text("\(Int(executionRate))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text("Success Rate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Manual Override Section
    
    private var manualOverrideSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.orange)
                Text("Manual Override")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()

                Button("Override") {
                    showManualOverride = true
                }
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 12) {
                OverrideButton(
                    title: "Pause AI",
                    icon: "pause.circle",
                    color: .orange
                ) {
                    pauseAI()
                }

                OverrideButton(
                    title: "Force Buy",
                    icon: "arrow.up.circle",
                    color: .green
                ) {
                    forceBuy()
                }

                OverrideButton(
                    title: "Force Sell",
                    icon: "arrow.down.circle",
                    color: .red
                ) {
                    forceSell()
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Real-time Decisions Section
    
    private var realtimeDecisionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("Real-time Decisions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()

                Text("Live")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                RealtimeDecisionCard(
                    timestamp: Date(),
                    agent: "Market Analyzer",
                    decision: "Pattern detected: Bullish Flag",
                    confidence: 0.83,
                    action: "Recommend BUY"
                )

                RealtimeDecisionCard(
                    timestamp: Date().addingTimeInterval(-120),
                    agent: "Risk Manager",
                    decision: "Portfolio exposure check",
                    confidence: 0.95,
                    action: "Position size: 1.2%"
                )

                RealtimeDecisionCard(
                    timestamp: Date().addingTimeInterval(-300),
                    agent: "AI Trader",
                    decision: "Execute trade order",
                    confidence: 0.76,
                    action: "BUY 50 shares NIFTY"
                )
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func emergencyStop() {
        isAITradingEnabled = false
        // Implement emergency stop logic
        print("EMERGENCY STOP ACTIVATED")
    }
    
    private func optimizeStrategies() {
        // Implement strategy optimization
        print("Optimizing strategies...")
    }
    
    private func pauseAI() {
        isAITradingEnabled = false
        print("AI Trading paused")
    }
    
    private func forceBuy() {
        print("Force buy executed")
    }
    
    private func forceSell() {
        print("Force sell executed")
    }
}

// MARK: - Supporting Views

struct AgentPerformanceCard: View {
    let agentName: String
    let performance: Double
    let status: AgentStatus
    let decisions: Int
    let accuracy: Double

    enum AgentStatus {
        case active, learning, inactive

        var color: Color {
            switch self {
            case .active: return .green
            case .learning: return .orange
            case .inactive: return .red
            }
        }

        var text: String {
            switch self {
            case .active: return "Active"
            case .learning: return "Learning"
            case .inactive: return "Inactive"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(agentName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                Text(status.text)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.2))
                    .foregroundColor(status.color)
                    .cornerRadius(4)
            }

            Text("\(String(format: "%.1f%%", performance))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(performance > 80 ? .green : performance > 60 ? .orange : .red)

            VStack(alignment: .leading, spacing: 4) {
                Text("Decisions: \(decisions)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Accuracy: \(String(format: "%.1f%%", accuracy * 100))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct LearningProgressBar: View {
    let title: String
    let progress: Double
    let improvement: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text(improvement)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            HStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))

                Text("\(String(format: "%.0f%%", progress * 100))")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct OptimizationMetric: View {
    let name: String
    let currentValue: String
    let optimizedValue: String
    let improvement: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)

                HStack {
                    Text("Current: \(currentValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("→")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    Text("Optimized: \(optimizedValue)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Text(improvement)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct OverrideButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct RealtimeDecisionCard: View {
    let timestamp: Date
    let agent: String
    let decision: String
    let confidence: Double
    let action: String

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(agent)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)

                    Spacer()

                    Text(timeFormatter.string(from: timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(decision)
                    .font(.caption)
                    .lineLimit(2)

                HStack {
                    Text("Confidence: \(String(format: "%.0f%%", confidence * 100))")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(action)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }

            Circle()
                .fill(confidence > 0.8 ? Color.green : confidence > 0.6 ? Color.orange : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

// MARK: - Additional Views (Stubs for sheets)

struct ManualOverrideView: View {
    @ObservedObject var aiTrader: AIAgentTrader
    
    var body: some View {
        NavigationView {
            Text("Manual Override Controls")
                .navigationTitle("Manual Override")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Manual Override")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
        }
    }
}

#Preview {
    AIControlCenterView()
}