import SwiftUI
import UIKit
import SharedPatternModels

struct PatternScannerView: View {
    let multiTimeframeAnalysis: [String: [TechnicalAnalysisEngine.PatternResult]]
    let patternAlerts: [SharedPatternModels.PatternAlert]
    let confluencePatterns: [SharedPatternModels.ConfluencePattern]
    
    @State private var selectedTimeframe: String = "1D"
    @State private var sortBy: SortOption = .confidence
    @State private var filterUrgency: AlertUrgency? = nil
    @State private var showOnlyConfluence = false
    
    private let timeframes = ["1m", "5m", "15m", "1h", "4h", "1D"]
    
    enum SortOption: String, CaseIterable {
        case confidence = "Confidence"
        case strength = "Strength"
        case urgency = "Urgency"
        case alphabetical = "Name"
    }
    
    enum AlertUrgency: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var priority: Int {
            switch self {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }
    
    // Removed duplicate PatternAlert and ConfluencePattern structs - now using SharedPatternModels
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Controls
                VStack(spacing: 12) {
                    HStack {
                        Text("Pattern Scanner")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button("Close") {
                            // Dismiss handled by parent
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // Filter Controls
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Timeframe Selection
                            HStack {
                                Text("Timeframe:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("Timeframe", selection: $selectedTimeframe) {
                                    ForEach(timeframes, id: \.self) { timeframe in
                                        Text(timeframe).tag(timeframe)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            Divider()
                                .frame(height: 20)
                            
                            // Sort Options
                            HStack {
                                Text("Sort:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("Sort", selection: $sortBy) {
                                    ForEach(SortOption.allCases, id: \.self) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            // Confluence Toggle
                            Toggle("Confluence Only", isOn: $showOnlyConfluence)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 1)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Pattern Alerts Section
                        if !filteredAlerts.isEmpty {
                            PatternAlertsSection(alerts: filteredAlerts)
                        }
                        
                        // Confluence Patterns Section
                        if !confluencePatterns.isEmpty && showOnlyConfluence {
                            ConfluencePatternsSection(patterns: confluencePatterns)
                        }
                        
                        // Timeframe Patterns Section
                        if !showOnlyConfluence {
                            TimeframePatternsSection(
                                patterns: sortedPatterns,
                                timeframe: selectedTimeframe
                            )
                        }
                        
                        // Statistics Section
                        StatisticsSection(
                            totalPatterns: totalPatterns,
                            averageConfidence: averageConfidence,
                            strongPatterns: strongPatterns
                        )
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredAlerts: [SharedPatternModels.PatternAlert] {
        var alerts = patternAlerts
        
        if let urgency = filterUrgency {
            alerts = alerts.filter { alert in
                guard let alertUrgency = alert.urgency else { return false }
                switch (urgency, alertUrgency) {
                case (.critical, .critical), (.high, .high), (.medium, .medium), (.low, .low):
                    return true
                default:
                    return false
                }
            }
        }
        
        switch sortBy {
        case .confidence:
            alerts = alerts.sorted { $0.confidence > $1.confidence }
        case .strength:
            // We need to implement strength comparison for SharedPatternModels
            break
        case .urgency:
            alerts = alerts.sorted { 
                guard let firstUrgency = $0.urgency, let secondUrgency = $1.urgency else { 
                    return false 
                }
                return getUrgencyPriority(firstUrgency) > getUrgencyPriority(secondUrgency)
            }
        case .alphabetical:
            // We need to implement pattern name access for SharedPatternModels
            break
        }
        
        return alerts
    }
    
    private var sortedPatterns: [TechnicalAnalysisEngine.PatternResult] {
        let patterns = multiTimeframeAnalysis[selectedTimeframe] ?? []
        
        switch sortBy {
        case .confidence:
            return patterns.sorted { $0.confidence > $1.confidence }
        case .strength:
            return patterns.sorted { $0.strength.rawValue > $1.strength.rawValue }
        case .urgency:
            return patterns.sorted { $0.confidence > $1.confidence } // Fallback to confidence
        case .alphabetical:
            return patterns.sorted { $0.pattern < $1.pattern }
        }
    }
    
    private var totalPatterns: Int {
        return multiTimeframeAnalysis.values.flatMap { $0 }.count
    }
    
    private var averageConfidence: Double {
        let allPatterns = multiTimeframeAnalysis.values.flatMap { $0 }
        guard !allPatterns.isEmpty else { return 0 }
        return allPatterns.map { $0.confidence }.reduce(0, +) / Double(allPatterns.count)
    }
    
    private var strongPatterns: Int {
        let allPatterns = multiTimeframeAnalysis.values.flatMap { $0 }
        return allPatterns.filter { 
            $0.strength == .strong || $0.strength == .veryStrong 
        }.count
    }
    
    private func getUrgencyPriority(_ urgency: SharedPatternModels.PatternAlert.AlertUrgency) -> Int {
        switch urgency {
        case .critical:
            return 4
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        }
    }
}

// MARK: - Supporting Views

struct PatternAlertsSection: View {
    let alerts: [SharedPatternModels.PatternAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("Active Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("\(alerts.count) alerts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if alerts.isEmpty {
                EmptyStateView(
                    icon: "bell.slash.fill",
                    title: "No Alerts",
                    message: "No active pattern alerts at the moment"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(alerts.indices, id: \.self) { index in
                            PatternAlertCard(alert: alerts[index])
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct PatternAlertCard: View {
    let alert: SharedPatternModels.PatternAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(alert.patternType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let urgency = alert.urgency {
                    Text(urgency.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(urgencyColor(urgency).opacity(0.2))
                        .foregroundColor(urgencyColor(urgency))
                        .cornerRadius(8)
                }
            }
            
            Text("\(Int(alert.confidence * 100))% confidence")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Signal: \(signalText(alert.signal))")
                    .font(.caption)
                
                Spacer()
                
                Text("Strength: \(strengthText(alert.strength))")
                    .font(.caption)
            }
        }
        .padding()
        .frame(width: 280)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func urgencyColor(_ urgency: SharedPatternModels.PatternAlert.AlertUrgency) -> Color {
        switch urgency {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        }
    }
    
    private func signalText(_ signal: SharedPatternModels.PatternAlert.TradingSignal) -> String {
        switch signal {
        case .buy:
            return "Buy"
        case .sell:
            return "Sell"
        case .hold:
            return "Hold"
        case .strongBuy:
            return "Strong Buy"
        case .strongSell:
            return "Strong Sell"
        }
    }
    
    private func strengthText(_ strength: SharedPatternModels.PatternAlert.PatternStrength) -> String {
        switch strength {
        case .weak:
            return "Weak"
        case .moderate:
            return "Moderate"
        case .strong:
            return "Strong"
        case .veryStrong:
            return "Very Strong"
        }
    }
}

struct ConfluencePatternsSection: View {
    let patterns: [SharedPatternModels.ConfluencePattern]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.merge")
                    .foregroundColor(.purple)
                Text("Confluence Patterns")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("\(patterns.count) patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if patterns.isEmpty {
                EmptyStateView(
                    icon: "arrow.triangle.merge",
                    title: "No Confluence Patterns",
                    message: "No confluence patterns detected at the moment"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(patterns.indices, id: \.self) { index in
                            ConfluencePatternCard(pattern: patterns[index])
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct ConfluencePatternCard: View {
    let pattern: SharedPatternModels.ConfluencePattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.dominantPattern)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(pattern.overallConfidence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            Text("Timeframes: \(pattern.timeframes.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Signal: \(signalText(pattern.signal))")
                    .font(.caption)
                
                Spacer()
                
                Text("Strength: \(strengthText(pattern.strength))")
                    .font(.caption)
            }
            
            Text("Confluence Score: \(String(format: "%.2f", pattern.confluenceScore))")
                .font(.caption)
                .italic()
        }
        .padding()
        .frame(width: 280)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func signalText(_ signal: SharedPatternModels.PatternAlert.TradingSignal) -> String {
        switch signal {
        case .buy:
            return "Buy"
        case .sell:
            return "Sell"
        case .hold:
            return "Hold"
        case .strongBuy:
            return "Strong Buy"
        case .strongSell:
            return "Strong Sell"
        }
    }
    
    private func strengthText(_ strength: SharedPatternModels.PatternAlert.PatternStrength) -> String {
        switch strength {
        case .weak:
            return "Weak"
        case .moderate:
            return "Moderate"
        case .strong:
            return "Strong"
        case .veryStrong:
            return "Very Strong"
        }
    }
}

/// A reusable empty state view component
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

struct TimeframePatternsSection: View {
    let patterns: [TechnicalAnalysisEngine.PatternResult]
    let timeframe: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("\(timeframe) Patterns")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(patterns.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if patterns.isEmpty {
                Text("No patterns detected in this timeframe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(patterns.indices, id: \.self) { index in
                    PatternCard(pattern: patterns[index])
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct PatternCard: View {
    let pattern: TechnicalAnalysisEngine.PatternResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.pattern)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Confidence: \(String(format: "%.1f%%", pattern.confidence * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    strengthBadge
                }
                
                Text("Success Rate: \(String(format: "%.1f%%", pattern.successRate * 100))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(strengthColor)
                    .font(.title2)
                
                Text(pattern.strength.rawValue)
                    .font(.caption2)
                    .foregroundColor(strengthColor)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var strengthBadge: some View {
        Text(pattern.strength.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(strengthColor.opacity(0.2))
            .foregroundColor(strengthColor)
            .cornerRadius(4)
    }
    
    private var strengthColor: Color {
        switch pattern.strength {
        case .veryStrong: return .green
        case .strong: return .blue
        case .moderate: return .orange
        case .weak: return .gray
        }
    }
}

struct StatisticsSection: View {
    let totalPatterns: Int
    let averageConfidence: Double
    let strongPatterns: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.green)
                Text("Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack {
                StatCard(title: "Total Patterns", value: "\(totalPatterns)", color: .blue)
                StatCard(title: "Avg Confidence", value: "\(String(format: "%.1f%%", averageConfidence * 100))", color: .orange)
                StatCard(title: "Strong Patterns", value: "\(strongPatterns)", color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    PatternScannerView(
        multiTimeframeAnalysis: [:],
        patternAlerts: [],
        confluencePatterns: []
    )
}