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

    var onTick: ((MarketData) -> Void)? {
        didSet { ws.onTick = onTick }
    }
    var onError: ((Error) -> Void)? {
        didSet { ws.onError = onError }
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
    }

    func subscribe(symbols: [String]) {
        // TODO: map symbols to instrument tokens; for now, no-op as WS subscription is binary.
        if symbols.contains("NIFTY") {
            ws.subscribeToSymbol("NIFTY") // logs placeholder
        }
    }
}

final class ZerodhaHistoricalDataProvider: HistoricalDataProvider {
    private let client = ZerodhaAPIClient()

    func fetchCandles(symbol: String, completion: @escaping (Result<[MarketData], Error>) -> Void) {
        client.fetchHistoricalData(symbol: symbol, completion: completion)
    }
}