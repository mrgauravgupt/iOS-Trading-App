import Foundation
import SwiftUI

/// Centralized manager for handling real-time data connections and error states
@MainActor
class DataConnectionManager: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastError: String?
    @Published var isRetrying: Bool = false
    
    private let zerodhaClient = ZerodhaAPIClient()
    private var retryTimer: Timer?
    private let maxRetryAttempts = 3
    private var currentRetryAttempt = 0
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)
        
        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting..."
            case .disconnected: return "Disconnected"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .connecting: return .orange
            case .disconnected: return .gray
            case .error: return .red
            }
        }
    }
    
    /// Test connection to Zerodha API
    func testConnection() async {
        connectionStatus = .connecting
        isRetrying = false
        currentRetryAttempt = 0
        
        await performConnectionTest()
    }
    
    private func performConnectionTest() async {
        do {
            let marketData = try await fetchLTPAsync(symbol: "NIFTY")
            connectionStatus = .connected
            lastError = nil
            currentRetryAttempt = 0
            print("✅ Connection successful - NIFTY LTP: ₹\(marketData.price)")
        } catch {
            handleConnectionError(error)
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        let errorMessage = error.localizedDescription
        lastError = errorMessage
        
        if currentRetryAttempt < maxRetryAttempts {
            currentRetryAttempt += 1
            isRetrying = true
            connectionStatus = .connecting
            
            // Retry after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(currentRetryAttempt * 2)) {
                Task {
                    await self.performConnectionTest()
                }
            }
        } else {
            connectionStatus = .error(errorMessage)
            isRetrying = false
        }
    }
    
    /// Fetch real-time LTP data with async/await
    func fetchLTPAsync(symbol: String) async throws -> MarketData {
        return try await withCheckedThrowingContinuation { continuation in
            zerodhaClient.fetchLTP(symbol: symbol) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Fetch historical data with async/await
    func fetchHistoricalDataAsync(symbol: String) async throws -> [MarketData] {
        return try await withCheckedThrowingContinuation { continuation in
            zerodhaClient.fetchHistoricalData(symbol: symbol) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Check if real-time data is available
    var isDataAvailable: Bool {
        switch connectionStatus {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    /// Get error message for display
    var errorMessage: String {
        switch connectionStatus {
        case .error(let message):
            return message
        case .disconnected:
            return "No connection to Zerodha API. Please check your credentials and internet connection."
        case .connecting:
            return "Connecting to Zerodha API..."
        case .connected:
            return ""
        }
    }
    
    deinit {
        retryTimer?.invalidate()
    }
}

/// Error view component for displaying connection issues
struct DataErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Data Connection Error")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry Connection")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .padding()
    }
}

/// Loading view component
struct DataLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .padding()
    }
}