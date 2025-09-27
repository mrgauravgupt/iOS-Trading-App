import Foundation
import Combine



class NIFTYOptionsDataProvider: ObservableObject, DataProviderProtocol {
    private var cancellables = Set<AnyCancellable>()
    private var _isConnected = true
    private var realTimeTimer: Timer?

    @Published var optionsChain: NIFTYOptionsChain? = nil
    @Published var realTimeData: RealTimeMarketData? = nil
    private let analyzer = OptionsChainAnalyzer()

    var currentOptionsChain: NIFTYOptionsChain? {
        return optionsChain
    }
    
    // MARK: - Public Methods
    
    /// Fetch options chain data for a given symbol
    func fetchOptionsChain(for symbol: String) -> AnyPublisher<NIFTYOptionsChain, Error> {
        // In a real app, this would make an API call to fetch live data
        // For this demo, we'll generate mock data
        return Just(generateMockOptionsChain(for: symbol))
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
    
    /// Fetch historical options data
    func fetchHistoricalOptionsData(for symbol: String, from startDate: Date, to endDate: Date) -> AnyPublisher<[NIFTYOptionsChain], Error> {
        // Generate mock historical data
        let calendar = Calendar.current
        var currentDate = startDate
        var historicalChains: [NIFTYOptionsChain] = []
        
        while currentDate <= endDate {
            if calendar.isDateInWeekend(currentDate) {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                continue
            }
            
            var chain = generateMockOptionsChain(for: symbol)
            chain.timestamp = currentDate
            historicalChains.append(chain)
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return Just(historicalChains)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(2), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
    
    /// Fetch options analytics for a given symbol
    func fetchOptionsAnalytics(for symbol: String) -> AnyPublisher<OptionsAnalysis, Error> {
        // Generate mock analytics
        return fetchOptionsChain(for: symbol)
            .map { [weak self] chain -> OptionsAnalysis in
                guard let self = self else {
                    return OptionsAnalysis.empty()
                }

                let atmStrike = chain.getATMStrike()

                return OptionsAnalysis(
                    atmStrike: atmStrike,
                    metrics: self.generateMockOptionsMetrics(chain: chain),
                    greeksExposure: self.generateMockGreeksExposure(),
                    volatilitySurface: self.generateMockVolatilitySurface(),
                    sentimentAnalysis: self.generateMockSentimentAnalysis()
                )
            }
            .eraseToAnyPublisher()
    }

    /// Fetch latest price for a symbol
    func fetchLatestPrice(for symbol: String) async throws -> MarketDataPoint {
        // Generate mock market data point
        let price = 18500.0 + Double.random(in: -100...100)
        return MarketDataPoint(
            date: Date(),
            open: price,
            high: price * 1.01,
            low: price * 0.99,
            close: price,
            volume: Int.random(in: 100000...500000),
            symbol: symbol
        )
    }

    /// Initialize the data provider
    func initialize() async throws {
        // Initialize the data provider - setup any necessary connections or configurations
        print("NIFTYOptionsDataProvider initialized")
    }
    
    // MARK: - Private Methods
    
    /// Generate mock options chain data
    private func generateMockOptionsChain(for symbol: String) -> NIFTYOptionsChain {
        let underlyingPrice = 18500.0
        let expiryDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        
        var callOptions: [NIFTYOptionContract] = []
        var putOptions: [NIFTYOptionContract] = []
        
        // Generate options at different strike prices
        for i in -10...10 {
            let strike = underlyingPrice + Double(i * 100)
            let callOption = generateMockOption(symbol: symbol, strikePrice: strike, optionType: .call, underlyingPrice: underlyingPrice, expiryDate: expiryDate)
            let putOption = generateMockOption(symbol: symbol, strikePrice: strike, optionType: .put, underlyingPrice: underlyingPrice, expiryDate: expiryDate)
            
            callOptions.append(callOption)
            putOptions.append(putOption)
        }
        
        return NIFTYOptionsChain(
            underlyingPrice: underlyingPrice,
            expiryDate: expiryDate,
            callOptions: callOptions,
            putOptions: putOptions,
            timestamp: Date()
        )
    }
    
    /// Generate a mock option contract
    private func generateMockOption(symbol: String, strikePrice: Double, optionType: OptionType, underlyingPrice: Double, expiryDate: Date) -> NIFTYOptionContract {
        let daysToExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 30
        let timeToExpiry = Double(daysToExpiry) / 365.0
        
        // Calculate theoretical price and greeks
        let volatility = 0.2 + Double.random(in: -0.05...0.05)
        let delta = calculateMockDelta(strikePrice: strikePrice, underlyingPrice: underlyingPrice, optionType: optionType)
        let gamma = 0.01 * (1.0 - abs(delta - 0.5) * 2.0)
        let theta = -delta * volatility * underlyingPrice * 0.01 / sqrt(timeToExpiry)
        let vega = underlyingPrice * sqrt(timeToExpiry) * 0.01
        
        // Generate realistic volume and open interest
        let atm = abs(strikePrice - underlyingPrice) < 100
        let nearAtm = abs(strikePrice - underlyingPrice) < 300
        
        let baseVolume = atm ? 5000 : (nearAtm ? 2000 : 500)
        let baseOI = atm ? 15000 : (nearAtm ? 8000 : 2000)
        
        let volume = Int.random(in: Int(Double(baseVolume) * 0.8)...Int(Double(baseVolume) * 1.2))
        let openInterest = Int.random(in: Int(Double(baseOI) * 0.8)...Int(Double(baseOI) * 1.2))
        
        // Calculate price based on Black-Scholes approximation
        let price = calculateMockPrice(
            strikePrice: strikePrice,
            underlyingPrice: underlyingPrice,
            timeToExpiry: timeToExpiry,
            volatility: volatility,
            optionType: optionType
        )
        
        let bid = price * 0.99
        let ask = price * 1.01
        
        return NIFTYOptionContract(
            symbol: "\(symbol)\(optionType == .call ? "CE" : "PE")\(Int(strikePrice))",
            underlyingSymbol: symbol,
            strikePrice: strikePrice,
            expiryDate: expiryDate,
            optionType: optionType,
            lotSize: 50,
            currentPrice: price,
            bid: bid,
            ask: ask,
            volume: volume,
            openInterest: openInterest,
            impliedVolatility: volatility,
            delta: delta,
            gamma: gamma,
            theta: theta,
            vega: vega,
            timestamp: Date()
        )
    }
    
    /// Calculate mock delta for an option
    private func calculateMockDelta(strikePrice: Double, underlyingPrice: Double, optionType: OptionType) -> Double {
        let moneyness = underlyingPrice / strikePrice
        var delta = 0.5 + (moneyness - 1.0) * 2.0
        delta = min(max(delta, 0.01), 0.99)
        
        return optionType == .call ? delta : delta - 1.0
    }
    
    /// Calculate mock option price
    private func calculateMockPrice(strikePrice: Double, underlyingPrice: Double, timeToExpiry: Double, volatility: Double, optionType: OptionType) -> Double {
        let moneyness = underlyingPrice / strikePrice
        let timeValue = underlyingPrice * volatility * sqrt(timeToExpiry) * 0.4
        
        if optionType == .call {
            return max(0, underlyingPrice - strikePrice) + timeValue * (moneyness < 1.1 ? 1.0 : 0.5)
        } else {
            return max(0, strikePrice - underlyingPrice) + timeValue * (moneyness > 0.9 ? 1.0 : 0.5)
        }
    }
    
    /// Generate mock options metrics
    private func generateMockOptionsMetrics(chain: NIFTYOptionsChain) -> OptionsMetrics {
        let totalCallVolume = chain.callOptions.reduce(0) { $0 + $1.volume }
        let totalPutVolume = chain.putOptions.reduce(0) { $0 + $1.volume }
        let totalCallOI = chain.callOptions.reduce(0) { $0 + $1.openInterest }
        let totalPutOI = chain.putOptions.reduce(0) { $0 + $1.openInterest }

        let pcr = Double(totalPutVolume) / Double(max(totalCallVolume, 1))
        let oiPcr = Double(totalPutOI) / Double(max(totalCallOI, 1))

        return OptionsMetrics(
            pcr: pcr,
            oiPcr: oiPcr,
            maxPain: 18500.0, // Mock value
            skew: Double.random(in: -0.1...0.1),
            totalCallOI: totalCallOI,
            totalPutOI: totalPutOI,
            totalCallVolume: totalCallVolume,
            totalPutVolume: totalPutVolume
        )
    }
    
    /// Generate mock Greeks exposure
    private func generateMockGreeksExposure() -> GreeksExposure {
        return GreeksExposure(
            netDelta: Double.random(in: -100000...100000),
            netGamma: Double.random(in: -50000...50000),
            netTheta: Double.random(in: -200000...0),
            netVega: Double.random(in: -50000...50000)
        )
    }
    
    /// Generate mock volatility surface
    private func generateMockVolatilitySurface() -> VolatilitySurface {
        var points: [VolatilitySurfacePoint] = []
        let strikes = [17500.0, 18000.0, 18500.0, 19000.0, 19500.0]
        let expirations = [7.0, 14.0, 30.0, 60.0, 90.0] // days

        for strike in strikes {
            for expiry in expirations {
                let iv = 0.15 + Double.random(in: -0.05...0.05) // Base 15% with some variation
                let point = VolatilitySurfacePoint(
                    strike: strike,
                    timeToExpiry: expiry / 365.0, // Convert to years
                    impliedVolatility: iv,
                    optionType: .call
                )
                points.append(point)
            }
        }

        return VolatilitySurface(points: points)
    }
    
    /// Generate mock sentiment analysis
    private func generateMockSentimentAnalysis() -> SentimentAnalysis {
        return SentimentAnalysis(
            putCallRatio: Double.random(in: 0.7...1.3),
            oiPutCallRatio: Double.random(in: 0.7...1.3),
            volatilitySkew: Double.random(in: -0.05...0.05),
            sentimentScore: Double.random(in: -0.5...0.5),
            marketSentiment: nil,
            keywords: ["volatility", "earnings", "momentum", "trend"],
            sources: ["market data", "options flow"]
        )
    }
}

// MARK: - DataProviderProtocol Conformance

extension NIFTYOptionsDataProvider {
    var isConnected: Bool {
        return _isConnected
    }

    func connect(completion: @escaping (Bool) -> Void) {
        // Simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self._isConnected = true
            completion(true)
        }
    }

    func disconnect() {
        _isConnected = false
    }

    func fetchData(for symbol: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Convert publisher to callback
        fetchOptionsChain(for: symbol)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            }, receiveValue: { chain in
                do {
                    let data = try JSONEncoder().encode(chain)
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            })
            .store(in: &cancellables)
    }

    // MARK: - Real-time Data Stream Methods

    func startRealTimeDataStream() {
        // Start timer to update real-time data every 5 seconds
        realTimeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateRealTimeData()
        }
        updateRealTimeData() // Initial update
    }

    func stopRealTimeDataStream() {
        realTimeTimer?.invalidate()
        realTimeTimer = nil
    }

    private func updateRealTimeData() {
        // Generate mock real-time data
        let niftySpotPrice = 18500.0 + Double.random(in: -50...50)
        let niftyFuturePrice = niftySpotPrice + Double.random(in: -10...10)
        let vix = 15.0 + Double.random(in: -2...2)

        // Generate options chain if not exists
        if optionsChain == nil {
            optionsChain = generateMockOptionsChain(for: "NIFTY")
        }

        guard let chain = optionsChain else { return }

        // Get top gainers/losers (mock)
        let topGainers = Array(chain.callOptions.prefix(3) + chain.putOptions.prefix(3))
        let topLosers = Array(chain.callOptions.suffix(3) + chain.putOptions.suffix(3))
        let highestVolume = chain.callOptions.sorted { $0.volume > $1.volume }.prefix(5) + chain.putOptions.sorted { $0.volume > $1.volume }.prefix(5)
        let highestOI = chain.callOptions.sorted { $0.openInterest > $1.openInterest }.prefix(5) + chain.putOptions.sorted { $0.openInterest > $1.openInterest }.prefix(5)

        realTimeData = RealTimeMarketData(
            niftySpotPrice: niftySpotPrice,
            niftyFuturePrice: niftyFuturePrice,
            vix: vix,
            optionsChain: chain,
            topGainers: Array(topGainers),
            topLosers: Array(topLosers),
            highestVolume: Array(highestVolume),
            highestOI: Array(highestOI),
            timestamp: Date()
        )
    }
}
