import SwiftUI

struct TradeSuggestionView: View {
    @ObservedObject private var suggestionManager = TradeSuggestionManager.shared
    @State private var showExecutionSuccess = false
    @State private var showExecutionFailure = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // AI Trading Mode Controls
                aiTradingModeSection
                
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    Text("Current").tag(0)
                    Text("History").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    currentSuggestionsView
                } else {
                    suggestionHistoryView
                }
            }
            .navigationTitle("Trade Suggestions")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert(isPresented: $showExecutionSuccess) {
            Alert(
                title: Text("Trade Executed"),
                message: Text("Your trade has been successfully executed."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Execution Failed", isPresented: $showExecutionFailure) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There was an error executing your trade. Please try again.")
        }
    }
    
    // MARK: - AI Trading Mode Section
    private var aiTradingModeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Trading Mode")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Toggle("Auto Trade", isOn: $suggestionManager.autoTradeEnabled)
                    .onChange(of: suggestionManager.autoTradeEnabled) { _, _ in
                        suggestionManager.toggleAutoTrade()
                    }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestionManager.aiTradingMode.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(suggestionManager.autoTradeEnabled ? .green : .orange)
                    
                    Text(suggestionManager.aiTradingMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Current Suggestions View
    private var currentSuggestionsView: some View {
        Group {
            if suggestionManager.currentSuggestions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("No Current Suggestions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("AI is analyzing market conditions. New suggestions will appear here.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Generate Test Suggestion") {
                        suggestionManager.generateTestSuggestion()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(suggestionManager.currentSuggestions.sorted(by: { $0.timestamp > $1.timestamp })) { suggestion in
                        TradeSuggestionCard(suggestion: suggestion, onExecute: {
                            executeSuggestion(suggestion)
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Suggestion History View
    private var suggestionHistoryView: some View {
        Group {
            if suggestionManager.suggestionHistory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No History Available")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Trade suggestion history will appear here once suggestions are generated.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                VStack(spacing: 0) {
                    // History Stats
                    historyStatsSection
                    
                    // History List
                    List {
                        ForEach(suggestionManager.suggestionHistory.sorted(by: { $0.timestamp > $1.timestamp })) { suggestion in
                            HistorySuggestionCard(suggestion: suggestion)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - History Stats Section
    private var historyStatsSection: some View {
        let totalSuggestions = suggestionManager.suggestionHistory.count
        let executedSuggestions = suggestionManager.getExecutedSuggestions().count
        let executionRate = totalSuggestions > 0 ? Double(executedSuggestions) / Double(totalSuggestions) : 0.0
        
        return HStack(spacing: 20) {
            VStack {
                Text("\(totalSuggestions)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(executedSuggestions)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("Executed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(Int(executionRate * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Clear History") {
                suggestionManager.clearSuggestionHistory()
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private func executeSuggestion(_ suggestion: TradeSuggestion) {
        let success = suggestionManager.executeSuggestion(suggestion)
        if success {
            showExecutionSuccess = true
        } else {
            showExecutionFailure = true
        }
    }
}

struct TradeSuggestionCard: View {
    let suggestion: TradeSuggestion
    let onExecute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.symbol)
                    .font(.headline)
                Spacer()
                Text(suggestion.action.rawValue.uppercased())
                    .font(.headline)
                    .foregroundColor(suggestion.action == .buy ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(suggestion.action == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    )
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(String(format: "%.2f", suggestion.price))")
                        .font(.body)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(suggestion.quantity)")
                        .font(.body)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(suggestion.confidence * 100))%")
                        .font(.body)
                }
            }
            
            Text(suggestion.rationale)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            Text("Suggested at: \(formattedDate(suggestion.timestamp))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            
            if !suggestion.isExecuted {
                Button(action: onExecute) {
                    Text("Execute Trade")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            } else {
                Text("Trade Executed")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HistorySuggestionCard: View {
    let suggestion: TradeSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.symbol)
                    .font(.headline)
                Spacer()
                
                HStack(spacing: 8) {
                    Text(suggestion.action.rawValue.uppercased())
                        .font(.headline)
                        .foregroundColor(suggestion.action == .buy ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(suggestion.action == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        )
                    
                    // Execution status
                    Image(systemName: suggestion.isExecuted ? "checkmark.circle.fill" : "clock.circle")
                        .foregroundColor(suggestion.isExecuted ? .green : .orange)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(String(format: "%.2f", suggestion.price))")
                        .font(.body)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(suggestion.quantity)")
                        .font(.body)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(suggestion.confidence * 100))%")
                        .font(.body)
                }
            }
            
            Text(suggestion.rationale)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            HStack {
                Text("Suggested: \(formattedDate(suggestion.timestamp))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if suggestion.isExecuted {
                    Text("EXECUTED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Text("PENDING")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.top, 2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TradeSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        TradeSuggestionView()
    }
}
