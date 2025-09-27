import Foundation

// Simple struct for data export/import
struct ExportableTradingData: Codable {
    let symbol: String?
    let price: Double
    let timestamp: Date?
    let volume: Int64
}

class DataExportManager {
    static let shared = DataExportManager()

    func exportData(to url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = PersistenceController.shared.fetchTradingData()
        // Convert to exportable format
        let exportableData = data.map { item in
            ExportableTradingData(symbol: item.symbol, price: item.price, timestamp: item.timestamp, volume: item.volume)
        }
        let jsonData = try? JSONEncoder().encode(exportableData)
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
            let tradingData = try JSONDecoder().decode([ExportableTradingData].self, from: data)
            for item in tradingData {
                PersistenceController.shared.addTradingData(symbol: item.symbol ?? "", price: item.price, volume: item.volume, timestamp: item.timestamp ?? Date())
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
