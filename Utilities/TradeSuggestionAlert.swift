import SwiftUI

struct TradeSuggestionAlert: ViewModifier {
    @ObservedObject var suggestionManager = TradeSuggestionManager.shared
    @State private var showExecutionSuccess = false
    @State private var showExecutionFailure = false
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $suggestionManager.showSuggestionAlert) {
                guard let suggestion = suggestionManager.latestSuggestion else {
                    return Alert(
                        title: Text("Error"),
                        message: Text("No suggestion available"),
                        dismissButton: .default(Text("OK"))
                    )
                }
                
                return Alert(
                    title: Text("Trade Suggestion: \(suggestion.action.rawValue.uppercased()) \(suggestion.symbol)"),
                    message: Text("\(suggestion.quantity) shares at ₹\(String(format: "%.2f", suggestion.price))\n\nRationale: \(suggestion.rationale)\n\nConfidence: \(Int(suggestion.confidence * 100))%"),
                    primaryButton: .default(Text("Execute Now")) {
                        executeSuggestion(suggestion)
                    },
                    secondaryButton: .cancel(Text("View Later"))
                )
            }
            .alert("Trade Executed", isPresented: $showExecutionSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your trade has been successfully executed.")
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

extension View {
    func tradeSuggestionAlert() -> some View {
        self.modifier(TradeSuggestionAlert())
    }
}