import SwiftUI

struct TradeSuggestionView: View {
    @ObservedObject private var suggestionManager = TradeSuggestionManager.shared
    @State private var showExecutionSuccess = false
    @State private var showExecutionFailure = false
    
    var body: some View {
        VStack {
            Text("Trade Suggestions")
                .font(.title)
                .padding()
            
            if suggestionManager.currentSuggestions.isEmpty {
                VStack {
                    Text("No trade suggestions available")
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Button("Generate Test Suggestion") {
                        suggestionManager.generateTestSuggestion()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct TradeSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        TradeSuggestionView()
    }
}