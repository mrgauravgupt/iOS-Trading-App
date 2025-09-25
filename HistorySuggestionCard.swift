import SwiftUI

struct HistorySuggestionCard: View {
    let suggestion: TradeSuggestion
    let confidence: Double
    let rationale: String
    
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
                    Text("\(Int(confidence * 100))%")
                        .font(.body)
                }
            }
            
            Text(rationale)
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