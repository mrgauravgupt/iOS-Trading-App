import Foundation

class DataExportManager {
    static let shared = DataExportManager()

    func exportData(to url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = PersistenceController.shared.fetchTradingData()
        let jsonData = try? JSONEncoder().encode(data)
        do {
            try jsonData?.write(to: url)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func importData(from url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let data = try Data(contentsOf: url)
            let tradingData = try JSONDecoder().decode([TradingData].self, from: data)
            for item in tradingData {
                PersistenceController.shared.addTradingData(symbol: item.symbol ?? "", price: item.price, volume: item.volume, timestamp: item.timestamp ?? Date())
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
