import Foundation

class DataSyncManager {
    static let shared = DataSyncManager()

    func syncData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Placeholder for data synchronization
        // This would sync local Core Data with remote server
        completion(.success(()))
    }

    func syncHistoricalData(symbol: String) async throws {
        let data = try await withCheckedThrowingContinuation { continuation in
            ZerodhaAPIClient().fetchHistoricalData(symbol: symbol) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        for item in data {
            try await PersistenceController.shared.addTradingData(symbol: item.symbol, price: item.price, volume: Int64(item.volume), timestamp: item.timestamp)
        }
    }
}
