import SwiftUI

struct PatternScannerView: View {
    let multiTimeframeAnalysis: [String: [PatternRecognitionEngine.PatternResult]]
    let patternAlerts: [PatternRecognitionEngine.PatternAlert]
    let confluencePatterns: [PatternRecognitionEngine.ConfluencePattern]
    
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
    }
    
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
    
    private var filteredAlerts: [PatternRecognitionEngine.PatternAlert] {
        var alerts = patternAlerts
        
        if let urgency = filterUrgency {
            alerts = alerts.filter { alert in
                switch (urgency, alert.urgency) {
                case (.critical, .critical), (.high, .high), (.medium, .medium), (.low, .low):
                    return true
                default:
                    return false
                }
            }
        }
        
        return alerts.sorted { $0.urgency.rawValue < $1.urgency.rawValue }
    }
    
    private var sortedPatterns: [PatternRecognitionEngine.PatternResult] {
        let patterns = multiTimeframeAnalysis[selectedTimeframe] ?? []
        
        switch sortBy {
        case .confidence:
            return patterns.sorted { $0.confidence > $1.confidence }
        case .strength:
            return patterns.sorted { $0.strength.rawValue > $1.strength.rawValue }
        case .urgency:
            return patterns.sorted { $0.confidence > $1.confidence } // Fallback to confidence
        case .alphabetical:
            return patterns.sorted { $0.patternName < $1.patternName }
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
        return multiTimeframeAnalysis.values.flatMap { $0 }.filter { $0.strength == .strong || $0.strength == .veryStrong }.count
    }
}

// MARK: - Supporting Views

struct PatternAlertsSection: View {
    let alerts: [PatternRecognitionEngine.PatternAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("Active Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(alerts.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ForEach(alerts.indices, id: \.self) { index in
                PatternAlertCard(alert: alerts[index])
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PatternAlertCard: View {
    let alert: PatternRecognitionEngine.PatternAlert
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.patternName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    urgencyBadge
                }
                
                Text("Confidence: \(String(format: "%.1f%%", alert.confidence * 100))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let message = alert.message {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack {
                Image(systemName: urgencyIcon)
                    .foregroundColor(urgencyColor)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var urgencyBadge: some View {
        Text(alert.urgency.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(urgencyColor.opacity(0.2))
            .foregroundColor(urgencyColor)
            .cornerRadius(4)
    }
    
    private var urgencyColor: Color {
        switch alert.urgency {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    private var urgencyIcon: String {
        switch alert.urgency {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
}

struct ConfluencePatternsSection: View {
    let patterns: [PatternRecognitionEngine.ConfluencePattern]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.merge")
                    .foregroundColor(.purple)
                Text("Confluence Patterns")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(patterns.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ForEach(patterns.indices, id: \.self) { index in
                ConfluencePatternCard(pattern: patterns[index])
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ConfluencePatternCard: View {
    let pattern: PatternRecognitionEngine.ConfluencePattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.dominantPattern)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(pattern.timeframes.count) TF")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text("Confidence: \(String(format: "%.1f%%", pattern.confluenceScore * 100))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Timeframes:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ForEach(pattern.timeframes, id: \.self) { timeframe in
                    Text(timeframe)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(3)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct TimeframePatternsSection: View {
    let patterns: [PatternRecognitionEngine.PatternResult]
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PatternCard: View {
    let pattern: PatternRecognitionEngine.PatternResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.patternName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Confidence: \(String(format: "%.1f%%", pattern.confidence * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    strengthBadge
                }
                
                if let successRate = pattern.historicalSuccessRate {
                    Text("Success Rate: \(String(format: "%.1f%%", successRate * 100))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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
        .background(Color(.systemBackground))
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