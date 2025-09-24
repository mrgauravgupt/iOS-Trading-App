import Foundation

class ZerodhaAPIClient {
    private let baseURL = Config.apiBaseURL
    private var apiKey: String { Config.zerodhaAPIKey() }
    private var accessToken: String { Config.zerodhaAccessToken() }

    // Map app symbols to Zerodha identifiers
    // NIFTY uses instrument token 256265 (index). Quote identifier is NSE:NIFTY 50
    private func instrumentToken(for symbol: String) -> String? {
        switch symbol.uppercased() {
        case "NIFTY": return "256265"
        default: return nil
        }
    }

    private func quoteIdentifier(for symbol: String) -> String? {
        switch symbol.uppercased() {
        case "NIFTY": return "NSE:NIFTY 50"
        default: return nil
        }
    }

    // Real historical data (no stubs). Uses day candles for past ~30 days.
    func fetchHistoricalData(symbol: String, completion: @escaping (Result<[MarketData], Error>) -> Void) {
        guard let token = instrumentToken(for: symbol) else {
            completion(.failure(NSError(domain: "Unknown symbol", code: 0)))
            return
        }
        // last 30 days
        let calendar = Calendar.current
        let to = Date()
        let from = calendar.date(byAdding: .day, value: -30, to: to) ?? to
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fromStr = ISO8601DateFormatter.string(from: from, timeZone: .current, formatOptions: [.withInternetDateTime])
        let toStr = ISO8601DateFormatter.string(from: to, timeZone: .current, formatOptions: [.withInternetDateTime])

        var components = URLComponents(string: "\(baseURL)/instruments/historical/\(token)/day")!
        components.queryItems = [
            URLQueryItem(name: "from", value: fromStr),
            URLQueryItem(name: "to", value: toStr)
        ]
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("token \(apiKey):\(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, let data = data else {
                completion(.failure(NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1)))
                return
            }
            do {
                // Expected JSON: { data: { candles: [[timestamp, open, high, low, close, volume], ...] } }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let dataObj = json?["data"] as? [String: Any],
                      let candles = dataObj["candles"] as? [[Any]] else {
                    throw NSError(domain: "Invalid historical payload", code: 0)
                }
                let mapped: [MarketData] = candles.compactMap { arr in
                    guard arr.count >= 6,
                          let tsStr = arr[0] as? String,
                          let close = arr[4] as? Double,
                          let volume = arr[5] as? Double // Kite volume may be Double
                    else { return nil }
                    let ts = ISO8601DateFormatter().date(from: tsStr) ?? Date()
                    return MarketData(symbol: symbol, price: close, volume: Int(volume), timestamp: ts)
                }
                completion(.success(mapped))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Real-time LTP quote fetch (can be used as fallback/polling, but no stubs)
    func fetchLTP(symbol: String, completion: @escaping (Result<MarketData, Error>) -> Void) {
        guard let identifier = quoteIdentifier(for: symbol) else {
            completion(.failure(NSError(domain: "Unknown symbol", code: 0)))
            return
        }
        var components = URLComponents(string: "\(baseURL)/quote/ltp")!
        components.queryItems = [URLQueryItem(name: "i", value: identifier)]
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("token \(apiKey):\(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, let data = data else {
                completion(.failure(NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1)))
                return
            }
            do {
                // Expected: { data: { "NSE:NIFTY 50": { instrument_token, last_price, ... } } }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let dataObj = json?["data"] as? [String: Any],
                      let quote = dataObj[identifier] as? [String: Any],
                      let ltp = quote["last_price"] as? Double else {
                    throw NSError(domain: "Invalid LTP payload", code: 0)
                }
                let md = MarketData(symbol: symbol, price: ltp, volume: 0, timestamp: Date())
                completion(.success(md))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
