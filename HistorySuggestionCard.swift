import SwiftUI

struct HistorySuggestionCard: View {
    let suggestion: TradeSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with symbol and timestamp
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(suggestion.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(suggestion.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Execution status badge
                HStack {
                    Image(systemName: suggestion.isExecuted ? "checkmark.circle.fill" : "clock.circle.fill")
                        .foregroundColor(suggestion.isExecuted ? .green : .orange)
                    Text(suggestion.isExecuted ? "Executed" : "Pending")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(suggestion.isExecuted ? .green : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(suggestion.isExecuted ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                )
            }
            
            // Action and price info
            HStack {
                // Action badge
                HStack {
                    Image(systemName: suggestion.action == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(suggestion.action == .buy ? .green : .red)
                    Text(suggestion.action == .buy ? "BUY" : "SELL")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(suggestion.action == .buy ? .green : .red)
                }
                
                Spacer()
                
                // Price info
                VStack(alignment: .trailing, spacing: 2) {
                    Text("₹\(String(format: "%.2f", suggestion.price))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let quantity = suggestion.quantity {
                        Text("Qty: \(quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Rationale
            if !suggestion.rationale.isEmpty {
                Text(suggestion.rationale)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Confidence level
            HStack {
                Text("Confidence:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(suggestion.confidence * 5) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Spacer()
                
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        HistorySuggestionCard(
            suggestion: TradeSuggestion(
                symbol: "RELIANCE",
                action: .buy,
                price: 1376.50,
                quantity: 10,
                rationale: "Strong bullish momentum with high volume",
                confidence: 0.85,
                timestamp: Date(),
                isExecuted: true
            )
        )
        
        HistorySuggestionCard(
            suggestion: TradeSuggestion(
                symbol: "TCS",
                action: .sell,
                price: 4100.25,
                quantity: 5,
                rationale: "Resistance level reached, profit booking recommended",
                confidence: 0.72,
                timestamp: Date().addingTimeInterval(-3600),
                isExecuted: false
            )
        )
    }
    .padding()
    .background(Color(.systemGray6))
}