import Foundation

class ZerodhaAPIClient {
    private let baseURL = Config.apiBaseURL
    private let apiKey = Config.zerodhaAPIKey

    func fetchHistoricalData(symbol: String, completion: @escaping (Result<[MarketData], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/instruments/historical/\(symbol)/day")!
        var request = URLRequest(url: url)
        request.setValue("token \(apiKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let marketData = try JSONDecoder().decode([MarketData].self, from: data)
                completion(.success(marketData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
