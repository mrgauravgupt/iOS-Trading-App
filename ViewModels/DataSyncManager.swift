import Foundation

class DataSyncManager {
    static let shared = DataSyncManager()

    func syncData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Placeholder for data synchronization
        // This would sync local Core Data with remote server
        completion(.success(()))
    }

    func syncHistoricalData(symbol: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ZerodhaAPIClient().fetchHistoricalData(symbol: symbol) { result in
            switch result {
            case .success(let data):
                for item in data {
                    PersistenceController.shared.addTradingData(symbol: item.symbol, price: item.price, volume: Int64(item.volume), timestamp: item.timestamp)
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
