import Foundation

// MARK: - Abstractions

protocol MarketDataProvider {
    func connect()
    func subscribe(symbols: [String])
    var onTick: ((MarketData) -> Void)? { get set }
}

protocol HistoricalDataProvider {
    func fetchCandles(symbol: String, completion: @escaping (Result<[MarketData], Error>) -> Void)
}

// MARK: - Implementations

final class ZerodhaMarketDataProvider: MarketDataProvider {
    private let ws = WebSocketManager()
    private var retryTimer: Timer?
    private var maxRetries = 5
    private var retryCount = 0

    // Symbol to instrument token mapping for NIFTY and related options
    private static let symbolToToken: [String: String] = [
        "NIFTY": "256265",
        "BANKNIFTY": "260105",
        "FINNIFTY": "256266",
        "NIFTY50": "256265",
        "MIDCPNIFTY": "257372",
        // Add more NIFTY options tokens as needed, e.g., weekly/monthly expiries
        "NIFTY_WK": "some_weekly_token", // Placeholder; fetch dynamically in production
        "NIFTY_MTH": "some_monthly_token"
    ]

    var onTick: ((MarketData) -> Void)? {
        didSet { ws.onTick = onTick }
    }
    var onError: ((Error) -> Void)? {
        didSet { ws.onError = { error in
            self.onError?(error)
            self.handleReconnection(error: error)
        } }
    }

    func connect() {
        let apiKey = Config.zerodhaAPIKey()
        let access = Config.zerodhaAccessToken()
        if apiKey.isEmpty || access.isEmpty {
            let err = NSError(domain: "Zerodha", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Zerodha credentials. Please login."])
            onError?(err)
            return
        }
        ws.connectToZerodhaWebSocket(apiKey: apiKey, accessToken: access)
        setupReconnection()
    }

    func subscribe(symbols: [String]) {
        for symbol in symbols {
            if let token = ZerodhaMarketDataProvider.symbolToToken[symbol.uppercased()] {
                ws.subscribeToSymbol(token) // Use actual token for subscription
                print("Subscribed to \(symbol) with token \(token)")
            } else {
                let err = NSError(domain: "DataProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Unknown symbol: \(symbol). No token mapping found."])
                onError?(err)
            }
        }
    }

    private func setupReconnection() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.ws.isConnected {
                self.retryCount += 1
                if self.retryCount <= self.maxRetries {
                    print("Reconnecting to WebSocket... Attempt \(self.retryCount)/\(self.maxRetries)")
                    self.connect()
                } else {
                    let err = NSError(domain: "WebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached."])
                    self.onError?(err)
                    self.retryTimer?.invalidate()
                }
            } else {
                self.retryCount = 0
            }
        }
    }

    private func handleReconnection(error: Error) {
        if (error as NSError).code == 1006 || (error as NSError).code == 1001 { // WebSocket close codes
            print("WebSocket error detected: \(error.localizedDescription). Attempting reconnection...")
            setupReconnection()
        }
    }

    deinit {
        retryTimer?.invalidate()
    }
}

final class ZerodhaHistoricalDataProvider: HistoricalDataProvider {
    private let client = ZerodhaAPIClient()

    func fetchCandles(symbol: String, completion: @escaping (Result<[MarketData], Error>) -> Void) {
        client.fetchHistoricalData(symbol: symbol, completion: completion)
    }
}
