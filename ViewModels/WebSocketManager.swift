import Foundation
import Combine

/// Manages WebSocket connections for real-time data streaming
class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!
    var onMessageReceived: ((String) -> Void)?
    var onTick: ((MarketData) -> Void)?
    var onError: ((Error) -> Void)?
    private var notificationManager = NotificationManager.shared
    private var priceAlerts: [String: Double] = [:]
    
    @Published var isConnected = false {
        didSet {
            // Post notification when connection status changes
            NotificationCenter.default.post(name: NSNotification.Name("WebSocketStatusChanged"), object: self)
        }
    }
    @Published var connectionStatus: String = "Disconnected"
    @Published var lastUpdateTime: Date?

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

        connectionStatus = "Connecting..."
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()

        // Set up connection timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if self?.connectionStatus == "Connecting..." {
                print("WebSocket connection timeout")
                self?.connectionStatus = "Connection Timeout"
                self?.disconnect()
                // Attempt reconnection after timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    let apiKey = Config.zerodhaAPIKey()
                    let accessToken = Config.zerodhaAccessToken()
                    if !apiKey.isEmpty && !accessToken.isEmpty {
                        print("Attempting reconnection after timeout...")
                        self?.connectToZerodhaWebSocket(apiKey: apiKey, accessToken: accessToken)
                    }
                }
            }
        }
    }

    /// Disconnect from WebSocket
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        connectionStatus = "Disconnected"
        lastUpdateTime = nil
    }

    /// Receive messages from WebSocket
    private var tokenToSymbol: [UInt32: String] = [:]

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
                    print("Received string message: \(text)")
                    self.onMessageReceived?(text)
                    if let tick = self.parseMessage(text) {
                        print("Parsed tick: \(tick.symbol) = ₹\(tick.price)")
                        DispatchQueue.main.async {
                            self.lastUpdateTime = Date()
                        }
                        self.onTick?(tick)
                    } else {
                        print("Failed to parse message as tick")
                    }
                case .data(let data):
                    print("Received binary data: \(data.count) bytes")
                    let ticks = self.parseBinaryTicks(data)
                    print("Parsed \(ticks.count) binary ticks")
                    if !ticks.isEmpty {
                        DispatchQueue.main.async {
                            self.lastUpdateTime = Date()
                        }
                    }
                    for t in ticks {
                        print("Binary tick: \(t.symbol) = ₹\(t.price)")
                        self.onTick?(t)
                    }
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

    // Parse Zerodha Kite Ticker binary frames for LTP mode
    // Frame format (big-endian):
    // [2 bytes] packet_count
    // For each packet:
    //   [2 bytes] packet_length (L)
    //   [L bytes] packet_payload
    // LTP payload (length 8):
    //   [4 bytes] instrument_token (UInt32)
    //   [4 bytes] last_traded_price (Int32, price in paise)
    private func parseBinaryTicks(_ data: Data) -> [MarketData] {
        var ticks: [MarketData] = []
        var idx = 0
        func readUInt8() -> UInt8? { guard idx + 1 <= data.count else { return nil }; defer { idx += 1 }; return data[idx] }
        func readUInt16BE() -> UInt16? {
            guard idx + 2 <= data.count else { return nil }
            let v = (UInt16(data[idx]) << 8) | UInt16(data[idx+1])
            idx += 2
            return v
        }
        func readUInt32BE() -> UInt32? {
            guard idx + 4 <= data.count else { return nil }
            let v = (UInt32(data[idx]) << 24) | (UInt32(data[idx+1]) << 16) | (UInt32(data[idx+2]) << 8) | UInt32(data[idx+3])
            idx += 4
            return v
        }
        func readInt32BE() -> Int32? {
            guard let u = readUInt32BE() else { return nil }
            return Int32(bitPattern: u)
        }

        guard let packetCount = readUInt16BE() else { return ticks }
        for _ in 0..<packetCount {
            guard let length = readUInt16BE() else { break }
            let start = idx
            let end = min(idx + Int(length), data.count)
            guard end - start == Int(length) else { break }
            // LTP payload expected length 8
            if length == 8 {
                idx = start
                if let token = readUInt32BE(), let pricePaise = readInt32BE() {
                    let symbol = tokenToSymbol[token] ?? ""
                    let price = Double(pricePaise) / 100.0
                    if !symbol.isEmpty {
                        let md = MarketData(symbol: symbol, price: price, volume: 0, timestamp: Date())
                        ticks.append(md)
                    }
                }
                idx = end
            } else {
                // Skip unknown payload lengths
                idx = end
            }
        }
        return ticks
    }

    /// WebSocket connected handler
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected successfully")
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = "Connected"
            self.lastUpdateTime = Date()
        }
    }

    /// WebSocket closed handler
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed with code: \(closeCode)")
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("Close reason: \(reasonString)")
        }

        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
            self.lastUpdateTime = nil
        }

        // Attempt reconnection if not manually disconnected and we have credentials
        if closeCode != .goingAway {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                let apiKey = Config.zerodhaAPIKey()
                let accessToken = Config.zerodhaAccessToken()
                if !apiKey.isEmpty && !accessToken.isEmpty {
                    print("Attempting reconnection after unexpected disconnect...")
                    self?.connectToZerodhaWebSocket(apiKey: apiKey, accessToken: accessToken)
                }
            }
        }
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

    private var subscribedSymbols: Set<String> = []

    /// Subscribe to a symbol for real-time updates
    /// - Parameter symbol: Trading symbol
    func subscribeToSymbol(_ symbol: String) {
        guard isConnected else {
            print("Not connected to WebSocket - cannot subscribe to \(symbol)")
            // Attempt to reconnect if credentials are available
            let apiKey = Config.zerodhaAPIKey()
            let accessToken = Config.zerodhaAccessToken()
            if !apiKey.isEmpty && !accessToken.isEmpty {
                print("Attempting to reconnect WebSocket...")
                connectToZerodhaWebSocket(apiKey: apiKey, accessToken: accessToken)

                // Wait a bit for connection and retry subscription
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    if self?.isConnected == true {
                        self?.subscribeToSymbol(symbol)
                    } else {
                        print("WebSocket reconnection failed for \(symbol)")
                    }
                }
            } else {
                print("Missing credentials for WebSocket reconnection")
            }
            return
        }

        // Check if already subscribed
        guard !subscribedSymbols.contains(symbol) else {
            print("Already subscribed to: \(symbol)")
            return
        }

        // Map to Zerodha instrument tokens for major symbols
        let token: Int?
        switch symbol.uppercased() {
        case "NIFTY": token = 256265
        case "INFY": token = 408065 // Infosys
        case "TCS": token = 2953217 // Tata Consultancy Services
        case "RELIANCE": token = 738561 // Reliance Industries
        case "BANKNIFTY": token = 260105 // Bank Nifty
        default: token = nil
        }
        guard let token = token else {
            print("Unknown symbol for subscription: \(symbol)")
            return
        }

        // Send subscribe and set mode to LTP (text JSON as per Kite Ticker protocol)
        let subscribe = ["a": "subscribe", "v": [token]] as [String : Any]
        let mode = ["a": "mode", "v": ["ltp", [token]]] as [String : Any]
        // Keep reverse map for binary decoding
        tokenToSymbol[UInt32(token)] = symbol

        if let sData = try? JSONSerialization.data(withJSONObject: subscribe),
           let sText = String(data: sData, encoding: .utf8) {
            sendMessage(sText)
        }
        if let mData = try? JSONSerialization.data(withJSONObject: mode),
           let mText = String(data: mData, encoding: .utf8) {
            sendMessage(mText)
        }

        subscribedSymbols.insert(symbol)
        print("Requested subscription for: \(symbol) [token: \(token)]")
    }

    /// Unsubscribe from a symbol
    /// - Parameter symbol: Trading symbol
    func unsubscribeFromSymbol(_ symbol: String) {
        guard isConnected else {
            print("Not connected to WebSocket")
            return
        }

        guard subscribedSymbols.contains(symbol) else {
            print("Not subscribed to: \(symbol)")
            return
        }

        // Find token for symbol
        let token = tokenToSymbol.first(where: { $0.value == symbol })?.key
        guard let token = token else {
            print("Could not find token for symbol: \(symbol)")
            return
        }

        // Send unsubscribe message
        let unsubscribe = ["a": "unsubscribe", "v": [token]] as [String : Any]
        if let uData = try? JSONSerialization.data(withJSONObject: unsubscribe),
           let uText = String(data: uData, encoding: .utf8) {
            sendMessage(uText)
        }

        // Remove from tracking
        tokenToSymbol.removeValue(forKey: token)
        subscribedSymbols.remove(symbol)
        print("Unsubscribed from: \(symbol)")
    }

    /// Get list of currently subscribed symbols
    func getSubscribedSymbols() -> [String] {
        return Array(subscribedSymbols)
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
                      let lastPrice = data["last_price"] as? Double,
                      let volume = data["volume_traded"] as? Int else { return nil }

                // Use instrument token to look up symbol
                if let instrumentToken = data["instrument_token"] as? Int {
                    let symbol = tokenToSymbol[UInt32(instrumentToken)] ?? "UNKNOWN"
                    let marketData = MarketData(symbol: symbol, price: lastPrice, volume: volume, timestamp: Date())
                    checkPriceAlerts(for: marketData)
                    return marketData
                }
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
        print("startDataStreaming - API Key: '\(apiKey)', Access Token: '\(access)'")
        print("startDataStreaming - API Key present: \(!apiKey.isEmpty), Access Token present: \(!access.isEmpty)")
        guard !apiKey.isEmpty, !access.isEmpty else {
            print("Missing creds for startDataStreaming")
            return
        }
        connectToZerodhaWebSocket(apiKey: apiKey, accessToken: access)

        // Subscribe to all major symbols for real-time data
        subscribeToSymbol("NIFTY")
        subscribeToSymbol("INFY")
        subscribeToSymbol("TCS")
        subscribeToSymbol("RELIANCE")
        subscribeToSymbol("BANKNIFTY")
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