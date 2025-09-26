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
        case "INFY": return "NSE:INFY"
        case "TCS": return "NSE:TCS"
        case "RELIANCE": return "NSE:RELIANCE"
        case "BANKNIFTY": return "NSE:NIFTY BANK"
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

        // Zerodha expects: yyyy-MM-dd HH:mm:ss (exchange timezone)
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "Asia/Kolkata")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let fromStr = df.string(from: from)
        let toStr = df.string(from: to)

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
        request.setValue("3", forHTTPHeaderField: "X-Kite-Version")
        request.timeoutInterval = 30
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let http = response as? HTTPURLResponse, let data = data else {
                completion(.failure(NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1)))
                return
            }
            guard http.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                completion(.failure(NSError(domain: "HTTP Error", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: body])))
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
        request.setValue("3", forHTTPHeaderField: "X-Kite-Version")
        request.timeoutInterval = 15
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let http = response as? HTTPURLResponse, let data = data else {
                completion(.failure(NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1)))
                return
            }
            guard http.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                completion(.failure(NSError(domain: "HTTP Error", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: body])))
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
    
    // MARK: - Trading Methods (Stub implementations for development)
    
    func placeOrder(_ orderRequest: [String: Any]) async throws -> [String: Any] {
        // Real implementation not available - throw error
        throw NSError(domain: "TradingAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Real trading not implemented. Use paper trading mode."])
    }
    
    func cancelOrder(orderId: String) async throws -> [String: Any] {
        // Real implementation not available - throw error
        throw NSError(domain: "TradingAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Real order cancellation not implemented. Use paper trading mode."])
    }
    
    func getPositions() async throws -> [[String: Any]] {
        // Real implementation not available - return empty positions
        return []
    }
    
    func getQuote(symbol: String) -> MarketData? {
        // Real implementation not available - return nil to indicate no data
        return nil
    }
    
    func getAvailableFunds() async throws -> Double {
        // Real implementation not available - throw error to indicate no data
        throw NSError(domain: "TradingAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Real funds data not available. Use paper trading mode."])
    }
}
