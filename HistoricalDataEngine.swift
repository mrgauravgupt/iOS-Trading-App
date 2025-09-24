import Foundation

class HistoricalDataEngine {
    private var historicalData: [MarketData] = []
    private let zerodhaClient = ZerodhaAPIClient()
    
    func fetchHistoricalData(symbol: String, startDate: Date, endDate: Date) async throws {
        // Fetch real historical data from Zerodha API using completion handler
        return try await withCheckedThrowingContinuation { continuation in
            zerodhaClient.fetchHistoricalData(symbol: symbol) { result in
                switch result {
                case .success(let data):
                    self.historicalData = data
                    continuation.resume()
                case .failure(let error):
                    print("Error fetching historical data for \(symbol): \(error.localizedDescription)")
                    self.historicalData = [] // Clear any existing data on error
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getHistoricalData() -> [MarketData] {
        return historicalData
    }
    
    func preprocessData() -> [[Double]] {
        guard !historicalData.isEmpty else {
            print("Warning: No historical data available for preprocessing")
            return []
        }
        return historicalData.map { [$0.price] }
    }
    
    func isDataAvailable() -> Bool {
        return !historicalData.isEmpty
    }
}
