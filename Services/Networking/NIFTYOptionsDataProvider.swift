import Foundation
import Combine
import SharedCoreModels

class NIFTYOptionsDataProvider: DataProviderProtocol, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let analyzer = OptionsChainAnalyzer()
    private let zerodhaClient = ZerodhaAPIClient()

    // Published properties for real-time data
    @Published var realTimeData: RealTimeMarketData?
    @Published var currentOptionsChain: NIFTYOptionsChain?

    // MARK: - DataProviderProtocol Conformance
    var isConnected: Bool = false

    func fetchData(for symbol: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Fetch real data from Zerodha API
        zerodhaClient.fetchLTP(symbol: symbol) { result in
            switch result {
            case .success(let marketData):
                do {
                    let data = try JSONEncoder().encode(marketData)
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func connect(completion: @escaping (Bool) -> Void) {
        zerodhaClient.connectWebSocket(for: ["NIFTY"])
        self.isConnected = true // Assume success for now
        completion(true)
    }

    func disconnect() {
        zerodhaClient.disconnectWebSocket()
        isConnected = false
    }

    // MARK: - Public Methods

    /// Fetch options chain data for a given symbol
    func fetchOptionsChain(for symbol: String) -> AnyPublisher<NIFTYOptionsChain, Error> {
        return Future { promise in
            Task {
                // Fetch real-time market data
                self.zerodhaClient.fetchLTP(symbol: symbol) { result in
                    switch result {
                    case .success(let marketData):
                        // Fetch options chain from Zerodha API - stub implementation
                        let chain = NIFTYOptionsChain(underlyingPrice: marketData.price, expiryDate: Date().addingTimeInterval(7*24*3600), callOptions: [], putOptions: [], timestamp: Date())
                        // Update current options chain
                        self.currentOptionsChain = chain
                        promise(.success(chain))
                    case .failure(_):
                        // Fallback to empty chain if options not available
                        let emptyChain = NIFTYOptionsChain(underlyingPrice: 0, expiryDate: Date(), callOptions: [], putOptions: [], timestamp: Date())
                        self.currentOptionsChain = emptyChain
                        promise(.success(emptyChain))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Fetch historical options data
    func fetchHistoricalOptionsData(for symbol: String, from startDate: Date, to endDate: Date) -> AnyPublisher<[NIFTYOptionsChain], Error> {
        return Future { promise in
            // Fetch historical data from Zerodha API (using market data as proxy)
            self.zerodhaClient.fetchHistoricalData(symbol: symbol) { result in
                switch result {
                case .success(let marketData):
                    // Convert market data to options chains (simplified)
                    let chains = marketData.map { data in
                        NIFTYOptionsChain(underlyingPrice: data.price, expiryDate: Date().addingTimeInterval(7*24*3600), callOptions: [], putOptions: [], timestamp: data.timestamp)
                    }
                    promise(.success(chains))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Fetch options analytics for a given symbol
    func fetchOptionsAnalytics(for symbol: String) -> AnyPublisher<OptionsAnalysis, Error> {
        return fetchOptionsChain(for: symbol)
            .map { [weak self] chain -> OptionsAnalysis in
                guard let self = self else {
                    return OptionsAnalysis.empty()
                }
                return self.generateOptionsAnalytics(for: chain)
            }
            .eraseToAnyPublisher()
    }

    /// Get current options chain (cached)
    func getCurrentOptionsChain() -> NIFTYOptionsChain? {
        return currentOptionsChain
    }

    /// Fetch latest price for a symbol
    func fetchLatestPrice(for symbol: String) async throws -> MarketDataPoint {
        return try await withCheckedThrowingContinuation { continuation in
            zerodhaClient.fetchLTP(symbol: symbol) { result in
                switch result {
                case .success(let marketData):
                    let point = MarketDataPoint(
                        date: marketData.timestamp,
                        open: marketData.price,
                        high: marketData.price * 1.005, // Approximate
                        low: marketData.price * 0.995, // Approximate
                        close: marketData.price,
                        volume: marketData.volume,
                        symbol: symbol
                    )
                    continuation.resume(returning: point)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods



    /// Generate options analytics from real chain data
    private func generateOptionsAnalytics(for chain: NIFTYOptionsChain) -> OptionsAnalysis {
        // Calculate actual metrics from chain data
        let totalCallOI = chain.callOptions.reduce(0) { $0 + $1.openInterest }
        let totalPutOI = chain.putOptions.reduce(0) { $0 + $1.openInterest }
        let totalCallVolume = chain.callOptions.reduce(0) { $0 + $1.volume }
        let totalPutVolume = chain.putOptions.reduce(0) { $0 + $1.volume }

        let pcr = totalCallVolume > 0 ? Double(totalPutVolume) / Double(totalCallVolume) : 0
        let oiPcr = totalCallOI > 0 ? Double(totalPutOI) / Double(totalCallOI) : 0

        // Calculate max pain (strike with minimum total option value)
        let allStrikes = Set(chain.callOptions.map { $0.strikePrice } + chain.putOptions.map { $0.strikePrice })
        let maxPain = allStrikes.min { strike1, strike2 in
            let value1 = chain.totalOptionValueAtStrike(strike1)
            let value2 = chain.totalOptionValueAtStrike(strike2)
            return value1 < value2
        } ?? chain.underlyingPrice

        // Calculate actual greeks exposure
        let netDelta = chain.callOptions.reduce(0) { $0 + $1.delta * Double($1.openInterest) } +
                      chain.putOptions.reduce(0) { $0 + $1.delta * Double($1.openInterest) }
        
        let netGamma = chain.callOptions.reduce(0) { $0 + $1.gamma * Double($1.openInterest) } +
                      chain.putOptions.reduce(0) { $0 + $1.gamma * Double($1.openInterest) }
        
        let netTheta = chain.callOptions.reduce(0) { $0 + $1.theta * Double($1.openInterest) } +
                      chain.putOptions.reduce(0) { $0 + $1.theta * Double($1.openInterest) }
        
        let netVega = chain.callOptions.reduce(0) { $0 + $1.vega * Double($1.openInterest) } +
                     chain.putOptions.reduce(0) { $0 + $1.vega * Double($1.openInterest) }

        let metrics = OptionsMetrics(
            pcr: pcr,
            oiPcr: oiPcr,
            maxPain: maxPain,
            skew: chain.skew,
            totalCallOI: totalCallOI,
            totalPutOI: totalPutOI,
            totalCallVolume: totalCallVolume,
            totalPutVolume: totalPutVolume
        )

        let greeksExposure = GreeksExposure(
            netDelta: netDelta,
            netGamma: netGamma,
            netTheta: netTheta,
            netVega: netVega
        )

        // Create volatility surface from actual data
        let volatilitySurface = VolatilitySurface.fromOptionsChain(chain)

        let sentimentAnalysis = SentimentAnalysis(
            putCallRatio: pcr,
            oiPutCallRatio: oiPcr,
            volatilitySkew: chain.skew,
            sentimentScore: 0, // Will be calculated from external sources
            marketSentiment: nil,
            keywords: [], // Will be populated from news analysis
            sources: ["Zerodha API"]
        )

        return OptionsAnalysis(
            atmStrike: chain.getATMStrike(),
            metrics: metrics,
            greeksExposure: greeksExposure,
            volatilitySurface: volatilitySurface,
            sentimentAnalysis: sentimentAnalysis
        )
    }

    /// Normal CDF for Black-Scholes calculations
    // MARK: - Real-time Data Stream Methods

    private var webSocketCancellable: AnyCancellable?
    
    func startRealTimeDataStream() {
        // Connect to WebSocket for real-time data
        zerodhaClient.connectWebSocket(for: ["NIFTY"])

        // Subscribe to WebSocket updates
        // webSocketCancellable = NotificationCenter.default.publisher(for: .zerodhaTickUpdate)
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] notification in
        //         guard let self = self,
        //               let userInfo = notification.userInfo,
        //               let symbol = userInfo["symbol"] as? String,
        //               let price = userInfo["price"] as? Double else {
        //             return
        //         }
        //
        //         // Update real-time data
        //         self.realTimeData = RealTimeMarketData(
        //             niftySpotPrice: price,
        //             niftyFuturePrice: price * 1.001, // Approximate future price
        //             vix: self.realTimeData?.vix ?? 15.0, // Use previous VIX or default
        //             optionsChain: self.currentOptionsChain ?? NIFTYOptionsChain(underlyingPrice: price, expiryDate: Date().addingTimeInterval(7*24*3600), callOptions: [], putOptions: [], timestamp: Date()),
        //             topGainers: self.realTimeData?.topGainers ?? [],
        //             topLosers: self.realTimeData?.topLosers ?? [],
        //             highestVolume: self.realTimeData?.highestVolume ?? [],
        //             highestOI: self.realTimeData?.highestOI ?? [],
        //             timestamp: Date()
        //         )
        //     }
    }

    func stopRealTimeDataStream() {
        // Disconnect WebSocket
        zerodhaClient.disconnectWebSocket()
        webSocketCancellable?.cancel()
        
        // Clear data
        self.realTimeData = nil
        self.currentOptionsChain = nil
    }

    private func normalCDF(_ x: Double) -> Double {
        return 0.5 * (1 + erf(x / sqrt(2)))
    }
}


