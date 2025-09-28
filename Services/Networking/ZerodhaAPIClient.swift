import Foundation

class ZerodhaAPIClient {
    private let baseURL = Config.apiBaseURL
    private var apiKey: String { Config.zerodhaAPIKey() }
    private var accessToken: String { Config.zerodhaAccessToken() }

    // Map app symbols to Zerodha identifiers
    private func instrumentToken(for symbol: String) -> String? {
        switch symbol.uppercased() {
        case "NIFTY": return "256265" // NIFTY index
        case "BANKNIFTY": return "260105" // BANKNIFTY index
        case let s where s.hasPrefix("NIFTY") && s.hasSuffix("CE"): 
            return "NFO:" + s // NIFTY options calls
        case let s where s.hasPrefix("NIFTY") && s.hasSuffix("PE"):
            return "NFO:" + s // NIFTY options puts
        default: return nil
        }
    }

    private func quoteIdentifier(for symbol: String) -> String? {
        switch symbol.uppercased() {
        case "NIFTY": return "NSE:NIFTY 50"
        case "BANKNIFTY": return "NSE:NIFTY BANK"
        case let s where s.hasPrefix("NIFTY") && s.hasSuffix("CE"):
            return "NFO:" + s // NIFTY options calls
        case let s where s.hasPrefix("NIFTY") && s.hasSuffix("PE"):
            return "NFO:" + s // NIFTY options puts
        case "INFY": return "NSE:INFY"
        case "TCS": return "NSE:TCS"
        case "RELIANCE": return "NSE:RELIANCE"
        default: return nil
        }
    }

    // MARK: - WebSocket Methods
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var webSocketRetryCount = 0
    private let maxRetryCount = 5
    
    func connectWebSocket(for symbols: [String]) {
        guard webSocketTask == nil else { return }
        
        var components = URLComponents(string: "wss://ws.zerodha.com")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        guard let url = components.url else { return }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenToWebSocket()
        subscribeToSymbols(symbols)
    }
    
    private func listenToWebSocket() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                self?.listenToWebSocket() // Continue listening
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.reconnectWebSocket()
            }
        }
    }
    
    private var lastMessageTimestamp = Date.distantPast
    private let messageRateLimit = 0.1 // 100ms between messages
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        guard Date().timeIntervalSince(lastMessageTimestamp) > messageRateLimit else {
            return // Rate limit exceeded
        }
        lastMessageTimestamp = Date()
        
        switch message {
        case .string(let text):
            processWebSocketString(text)
        case .data(let data):
            processWebSocketData(data)
        default:
            break
        }
    }
    
    private func processWebSocketString(_ text: String) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else {
                return
            }
            
            // Handle different message types
            if let tick = json["tick"] as? [String: Any] {
                processTickData(tick)
            } else if let oi = json["oi"] as? [String: Any] {
                processOIData(oi)
            } else if let depth = json["depth"] as? [String: Any] {
                processDepthData(depth)
            }
        } catch {
            print("WebSocket message parsing error: \(error)")
        }
    }
    
    private func processWebSocketData(_ data: Data) {
        // Handle binary data if needed
    }
    
    private func processTickData(_ tick: [String: Any]) {
        guard let symbol = tick["instrument_token"] as? String,
              let lastPrice = tick["last_price"] as? Double else {
            return
        }
        
        // Notify subscribers of price update
        NotificationCenter.default.post(
            name: .zerodhaTickUpdate,
            object: nil,
            userInfo: ["symbol": symbol, "price": lastPrice]
        )
    }
    
    private func processOIData(_ oi: [String: Any]) {
        // Process open interest data
    }
    
    private func processDepthData(_ depth: [String: Any]) {
        // Process market depth data
    }
    
    private func subscribeToSymbols(_ symbols: [String]) {
        guard !symbols.isEmpty else { return }
        
        let subscriptionMessage: [String: Any] = [
            "a": "subscribe",
            "v": symbols.compactMap { quoteIdentifier(for: $0) }
        ]
        
        do {
            let messageData = try JSONSerialization.data(withJSONObject: subscriptionMessage)
            webSocketTask?.send(.string(String(data: messageData, encoding: .utf8)!)) { error in
                if let error = error {
                    print("WebSocket subscription error: \(error)")
                }
            }
        } catch {
            print("WebSocket subscription message error: \(error)")
        }
    }
    
    private func reconnectWebSocket() {
        guard webSocketRetryCount < maxRetryCount else { return }
        webSocketRetryCount += 1
        
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(webSocketRetryCount)) { [weak self] in
            self?.connectWebSocket(for: [])
        }
    }
    
    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        webSocketRetryCount = 0
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

    // MARK: - Options Data Methods

    func fetchOptionsChain(symbol: String, underlyingPrice: Double) async throws -> NIFTYOptionsChain {
        // Stub implementation - return empty options chain
        throw NSError(domain: "OptionsAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Options chain data not available in stub implementation."])
    }

    func fetchHistoricalOptionsData(symbol: String, from startDate: Date, to endDate: Date) async throws -> [NIFTYOptionsChain] {
        // Stub implementation - return empty array
        return []
    }
}
