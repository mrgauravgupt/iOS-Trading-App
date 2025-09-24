import Foundation

/// Manages WebSocket connections for real-time data streaming
class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!
    var onMessageReceived: ((String) -> Void)?
    var onTick: ((MarketData) -> Void)?
    var onError: ((Error) -> Void)?
    private var notificationManager = NotificationManager.shared
    private var priceAlerts: [String: Double] = [:]
    private var isConnected = false

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    /// Connect to a WebSocket endpoint
    /// - Parameter url: WebSocket URL
    func connect(to url: URL) {
        guard !isConnected else {
            print("Already connected to WebSocket")
            return
        }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        receiveMessage()
    }

    /// Disconnect from WebSocket
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }

    /// Receive messages from WebSocket
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error)")
                self.onError?(error)
                self.isConnected = false
            case .success(let message):
                switch message {
                case .string(let text):
                    self.onMessageReceived?(text)
                    if let tick = self.parseMessage(text) {
                        self.onTick?(tick)
                    }
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    break
                }
                // Continue receiving if still connected
                if self.isConnected {
                    self.receiveMessage()
                }
            }
        }
    }

    /// WebSocket connected handler
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        isConnected = true
    }

    /// WebSocket closed handler
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed with code: \(closeCode)")
        isConnected = false
    }

    /// Connect to Zerodha WebSocket
    /// Requires both API key and access token. No simulator stubs.
    func connectToZerodhaWebSocket(apiKey: String, accessToken: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAccess = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, !trimmedAccess.isEmpty else {
            print("Missing Zerodha credentials")
            return
        }
        var components = URLComponents(string: "wss://ws.kite.trade/")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: trimmedKey),
            URLQueryItem(name: "access_token", value: trimmedAccess)
        ]
        guard let url = components.url else {
            print("Failed to build Zerodha WS URL")
            return
        }
        connect(to: url)
    }

    /// Subscribe to a symbol for real-time updates
    /// - Parameter symbol: Trading symbol
    func subscribeToSymbol(_ symbol: String) {
        guard isConnected else {
            print("Not connected to WebSocket")
            return
        }

        // Map to Zerodha instrument token (minimal): NIFTY index -> 256265
        let token: Int?
        switch symbol.uppercased() {
        case "NIFTY": token = 256265
        default: token = nil
        }
        guard let token = token else {
            print("Unknown symbol for subscription: \(symbol)")
            return
        }

        // Send subscribe and set mode to LTP (text JSON as per Kite Ticker protocol)
        let subscribe = ["a": "subscribe", "v": [token]] as [String : Any]
        let mode = ["a": "mode", "v": ["ltp", [token]]] as [String : Any]
        if let sData = try? JSONSerialization.data(withJSONObject: subscribe),
           let sText = String(data: sData, encoding: .utf8) {
            sendMessage(sText)
        }
        if let mData = try? JSONSerialization.data(withJSONObject: mode),
           let mText = String(data: mData, encoding: .utf8) {
            sendMessage(mText)
        }
        print("Requested subscription for: \(symbol) [token: \(token)]")
    }

    /// Send a message through WebSocket
    /// - Parameter message: Message to send
    private func sendMessage(_ message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("Error sending message: \(error)")
                self.onError?(error)
            }
        }
    }

    /// Parse incoming message into MarketData
    /// - Parameter message: Raw message string
    /// - Returns: Parsed MarketData or nil
    func parseMessage(_ message: String) -> MarketData? {
        // Parse the JSON message from Zerodha WebSocket
        guard let data = message.data(using: .utf8) else { return nil }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let type = json?["type"] as? String else { return nil }
            
            if type == "tick" {
                guard let data = json?["data"] as? [String: Any],
                      let instrumentToken = data["instrument_token"] as? Int,
                      let lastPrice = data["last_price"] as? Double,
                      let volume = data["volume_traded"] as? Int else { return nil }

                let marketData = MarketData(symbol: "NIFTY", price: lastPrice, volume: volume, timestamp: Date())
                checkPriceAlerts(for: marketData)
                return marketData
            }
        } catch {
            print("Error parsing message: \(error)")
        }
        return nil
    }

    /// Start data streaming from Zerodha WebSocket
    func startDataStreaming() {
        let apiKey = Config.zerodhaAPIKey()
        let access = Config.zerodhaAccessToken()
        guard !apiKey.isEmpty, !access.isEmpty else {
            print("Missing creds for startDataStreaming")
            return
        }
        connectToZerodhaWebSocket(apiKey: apiKey, accessToken: access)
        subscribeToSymbol("NIFTY")
    }

    // Removed simulator mock method to enforce real-time data only
    // (If needed for unit tests, provide a separate test-only implementation.)

    /// Set a price alert for a symbol
    /// - Parameters:
    ///   - symbol: Trading symbol
    ///   - price: Target price
    func setPriceAlert(for symbol: String, price: Double) {
        priceAlerts[symbol] = price
    }

    /// Check if any price alerts should be triggered
    /// - Parameter marketData: Latest market data
    private func checkPriceAlerts(for marketData: MarketData) {
        if let alertPrice = priceAlerts[marketData.symbol] {
            if marketData.price >= alertPrice {
                notificationManager.scheduleNotification(
                    title: "Price Alert",
                    body: "\(marketData.symbol) has reached ₹\(marketData.price)"
                )
                priceAlerts.removeValue(forKey: marketData.symbol)
            }
        }
    }
}