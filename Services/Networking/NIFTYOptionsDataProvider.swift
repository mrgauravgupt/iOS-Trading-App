import Foundation
import Combine

class NIFTYOptionsDataProvider: ObservableObject {
    @Published var currentOptionsChain: NIFTYOptionsChain?
    @Published var realTimeData: RealTimeMarketData?
    @Published var intradaySignals: [IntradayTradingSignal] = []
    @Published var isConnected: Bool = false
    @Published var currentNIFTYPrice: Double = 0.0
    @Published var currentVIX: Double = 0.0
    
    private let zerodhaAPIClient = ZerodhaAPIClient()
    private let webSocketManager = WebSocketManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    func initialize() async throws {
        // Initialize the data provider
        // This could include setting up connections, loading initial data, etc.
        print("NIFTYOptionsDataProvider initialized")
    }
    
    // MARK: - Real-time Data Streaming
    
    func startRealTimeDataStream() {
        // Subscribe to NIFTY spot price
        subscribeToInstrument("NSE:NIFTY 50")
        
        // Subscribe to current month NIFTY futures
        subscribeToNIFTYFutures()
        
        // Subscribe to VIX
        subscribeToInstrument("NSE:INDIA VIX")
        
        // Subscribe to options chain for current expiry
        subscribeToOptionsChain()
        
        isConnected = true
    }
    
    func stopRealTimeDataStream() {
        webSocketManager.disconnect()
        isConnected = false
    }
    
    private func subscribeToInstrument(_ instrument: String) {
        // Use the existing subscribeToSymbol method from WebSocketManager
        webSocketManager.subscribeToSymbol(instrument)
        
        // Set up the callback for processing real-time data
        webSocketManager.onTick = { [weak self] marketData in
            self?.processRealTimeData(marketData)
        }
    }
    
    private func subscribeToNIFTYFutures() {
        // Get current month NIFTY futures symbol
        let futuresSymbol = getCurrentMonthNIFTYFutures()
        subscribeToInstrument(futuresSymbol)
    }
    
    private func subscribeToOptionsChain() {
        // Subscribe to ATM and nearby strikes for current expiry
        let currentExpiry = getNextExpiryDate()
        let atmStrike = getATMStrike()
        
        // Subscribe to calls and puts around ATM
        for i in -5...5 {
            let strike = atmStrike + Double(i * 50)
            let callSymbol = "NSE:NIFTY\(formatExpiryDate(currentExpiry))\(Int(strike))CE"
            let putSymbol = "NSE:NIFTY\(formatExpiryDate(currentExpiry))\(Int(strike))PE"
            
            subscribeToInstrument(callSymbol)
            subscribeToInstrument(putSymbol)
        }
    }
    
    // MARK: - Historical Data Fetching
    
    func fetchHistoricalOptionsData(
        expiry: Date,
        strikes: [Double],
        startDate: Date,
        endDate: Date,
        timeframe: Timeframe
    ) async throws -> [IntradayOptionsData] {
        
        var historicalData: [IntradayOptionsData] = []
        
        for strike in strikes {
            // Fetch call option data
            let callSymbol = "NSE:NIFTY\(formatExpiryDate(expiry))\(Int(strike))CE"
            let callData = try await fetchHistoricalOHLC(
                symbol: callSymbol,
                startDate: startDate,
                endDate: endDate,
                timeframe: timeframe
            )
            
            // Fetch put option data
            let putSymbol = "NSE:NIFTY\(formatExpiryDate(expiry))\(Int(strike))PE"
            let putData = try await fetchHistoricalOHLC(
                symbol: putSymbol,
                startDate: startDate,
                endDate: endDate,
                timeframe: timeframe
            )
            
            // Create option contracts and historical data
            let callContract = createOptionContract(
                symbol: callSymbol,
                strike: strike,
                expiry: expiry,
                type: .call
            )
            
            let putContract = createOptionContract(
                symbol: putSymbol,
                strike: strike,
                expiry: expiry,
                type: .put
            )
            
            historicalData.append(IntradayOptionsData(
                contract: callContract,
                ohlcData: callData,
                volumeProfile: [],
                orderBookData: nil,
                timestamp: Date()
            ))
            
            historicalData.append(IntradayOptionsData(
                contract: putContract,
                ohlcData: putData,
                volumeProfile: [],
                orderBookData: nil,
                timestamp: Date()
            ))
        }
        
        return historicalData
    }
    
    internal func fetchHistoricalOHLC(
        symbol: String,
        startDate: Date,
        endDate: Date,
        timeframe: Timeframe
    ) async throws -> [OHLCData] {
        
        // Use Zerodha API to fetch historical data
        return try await withCheckedThrowingContinuation { continuation in
            zerodhaAPIClient.fetchHistoricalData(symbol: symbol) { result in
                switch result {
                case .success(let marketDataArray):
                    let ohlcData = marketDataArray.map { data in
                        OHLCData(
                            timestamp: data.timestamp,
                            open: data.price, // Using price as close, need to enhance MarketData for full OHLC
                            high: data.price,
                            low: data.price,
                            close: data.price,
                            volume: data.volume,
                            timeframe: timeframe
                        )
                    }
                    continuation.resume(returning: ohlcData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Options Chain Analysis
    
    func analyzeOptionsChain() -> OptionsChainAnalysis {
        guard let chain = currentOptionsChain else {
            return OptionsChainAnalysis.empty()
        }
        
        // Calculate Put-Call Ratio
        let totalCallOI = chain.callOptions.reduce(0) { $0 + $1.openInterest }
        let totalPutOI = chain.putOptions.reduce(0) { $0 + $1.openInterest }
        let putCallRatio = totalCallOI > 0 ? Double(totalPutOI) / Double(totalCallOI) : 0
        
        // Find max pain point
        let maxPainPoint = calculateMaxPain(chain: chain)
        
        // Identify support and resistance levels
        _ = identifySupportLevels(chain: chain)
        _ = identifyResistanceLevels(chain: chain)
        
        // Create properly initialized analysis object
        let analysis = OptionsChainAnalysis(
            metrics: OptionsChainMetrics(
                pcr: putCallRatio,
                oiPcr: putCallRatio,
                maxPain: maxPainPoint,
                skew: 0.0,
                totalCallOI: totalCallOI,
                totalPutOI: totalPutOI,
                totalCallVolume: chain.callOptions.reduce(0) { $0 + $1.volume },
                totalPutVolume: chain.putOptions.reduce(0) { $0 + $1.volume }
            ),
            ivAnalysis: IVChainAnalysis(
                averageIV: chain.callOptions.reduce(0.0) { $0 + $1.impliedVolatility } / Double(chain.callOptions.count),
                atmIV: 0.0,
                callIV: chain.callOptions.reduce(0.0) { $0 + $1.impliedVolatility } / Double(chain.callOptions.count),
                putIV: chain.putOptions.reduce(0.0) { $0 + $1.impliedVolatility } / Double(chain.putOptions.count),
                ivSkew: 0.0,
                termStructure: [],
                volatilitySurface: [],
                strikes: [],
                callIVs: [],
                putIVs: []
            ),
            greeksExposure: GreeksExposure(
                netDelta: chain.callOptions.reduce(0.0) { $0 + $1.delta } + chain.putOptions.reduce(0.0) { $0 + $1.delta },
                netGamma: chain.callOptions.reduce(0.0) { $0 + $1.gamma } + chain.putOptions.reduce(0.0) { $0 + $1.gamma },
                netTheta: chain.callOptions.reduce(0.0) { $0 + $1.theta } + chain.putOptions.reduce(0.0) { $0 + $1.theta },
                netVega: chain.callOptions.reduce(0.0) { $0 + $1.vega } + chain.putOptions.reduce(0.0) { $0 + $1.vega },
                netRho: 0.0
            ),
            liquidityAnalysis: LiquidityAnalysis(
                averageSpread: 0.0,
                totalVolume: chain.callOptions.reduce(0) { $0 + $1.volume } + chain.putOptions.reduce(0) { $0 + $1.volume },
                totalOpenInterest: totalCallOI + totalPutOI,
                volumeConcentration: 0.0,
                oiConcentration: 0.0
            ),
            sentimentAnalysis: SentimentAnalysis(
                putCallRatio: putCallRatio,
                oiPutCallRatio: putCallRatio,
                volatilitySkew: 0.0,
                sentimentScore: 0.0,
                marketSentiment: .neutral,
                confidenceLevel: 0.0
            ),
            riskMetrics: ChainRiskMetrics(
                valueAtRisk: 0.0,
                gammaRisk: 0.0,
                thetaDecay: 0.0,
                vegaRisk: 0.0,
                stressTestResults: [:],
                riskScore: 0.0
            ),
            recommendations: []
        )
        
        return analysis
    }
    
    private func calculateMaxPain(chain: NIFTYOptionsChain) -> Double {
        let strikes = Set(chain.callOptions.map { $0.strikePrice } + chain.putOptions.map { $0.strikePrice })
        var maxPainStrike = 0.0
        var minPain = Double.infinity
        
        for strike in strikes {
            var totalPain = 0.0
            
            // Calculate pain for calls
            for call in chain.callOptions {
                if call.strikePrice < strike {
                    totalPain += (strike - call.strikePrice) * Double(call.openInterest)
                }
            }
            
            // Calculate pain for puts
            for put in chain.putOptions {
                if put.strikePrice > strike {
                    totalPain += (put.strikePrice - strike) * Double(put.openInterest)
                }
            }
            
            if totalPain < minPain {
                minPain = totalPain
                maxPainStrike = strike
            }
        }
        
        return maxPainStrike
    }
    
    private func identifySupportLevels(chain: NIFTYOptionsChain) -> [Double] {
        // Identify strikes with high put open interest
        let putsByOI = chain.putOptions.sorted { $0.openInterest > $1.openInterest }
        return Array(putsByOI.prefix(5).map { $0.strikePrice })
    }
    
    private func identifyResistanceLevels(chain: NIFTYOptionsChain) -> [Double] {
        // Identify strikes with high call open interest
        let callsByOI = chain.callOptions.sorted { $0.openInterest > $1.openInterest }
        return Array(callsByOI.prefix(5).map { $0.strikePrice })
    }
    
    private func calculateIVSkew(chain: NIFTYOptionsChain) -> Double {
        let atmStrike = chain.getATMStrike()
        
        // Find ATM call and put IV
        guard let atmCall = chain.callOptions.first(where: { $0.strikePrice == atmStrike }),
              let atmPut = chain.putOptions.first(where: { $0.strikePrice == atmStrike }) else {
            return 0.0
        }
        
        return atmPut.impliedVolatility - atmCall.impliedVolatility
    }
    
    // MARK: - Helper Methods
    
    private func processRealTimeData(_ marketData: MarketData) {
        // Process incoming real-time data and update published properties
        DispatchQueue.main.async {
            // Update current NIFTY price if this is NIFTY data
            if marketData.symbol.contains("NIFTY") && !marketData.symbol.contains("CE") && !marketData.symbol.contains("PE") {
                self.currentNIFTYPrice = marketData.price
            }
            
            // Update VIX if this is VIX data
            if marketData.symbol.contains("VIX") {
                self.currentVIX = marketData.price
            }
            
            // Update options chain data if this is options data
            if marketData.symbol.contains("CE") || marketData.symbol.contains("PE") {
                self.updateOptionsChainData(marketData)
            }
        }
    }
    
    private func updateOptionsChainData(_ marketData: MarketData) {
        // Update options chain with real-time data
        // This would update the currentOptionsChain with live prices
        // Implementation would parse the symbol to extract strike and option type
        // and update the corresponding option in the chain
    }
    
    private func getCurrentMonthNIFTYFutures() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMM"
        let monthYear = formatter.string(from: Date()).uppercased()
        return "NSE:NIFTY\(monthYear)FUT"
    }
    
    private func getNextExpiryDate() -> Date {
        // Calculate next Thursday (NIFTY expiry day)
        let calendar = Calendar.current
        let today = Date()
        
        var nextThursday = today
        while calendar.component(.weekday, from: nextThursday) != 5 { // Thursday = 5
            nextThursday = calendar.date(byAdding: .day, value: 1, to: nextThursday)!
        }
        
        // If today is Thursday and market is closed, get next Thursday
        if calendar.component(.weekday, from: today) == 5 && isMarketClosed() {
            nextThursday = calendar.date(byAdding: .weekOfYear, value: 1, to: nextThursday)!
        }
        
        return nextThursday
    }
    
    private func getATMStrike() -> Double {
        // This would be updated from real-time NIFTY price
        // For now, return a placeholder
        return 18000.0
    }
    
    private func formatExpiryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMMdd"
        return formatter.string(from: date).uppercased()
    }
    
    private func createOptionContract(
        symbol: String,
        strike: Double,
        expiry: Date,
        type: OptionType
    ) -> NIFTYOptionContract {
        return NIFTYOptionContract(
            symbol: symbol,
            underlyingSymbol: "NIFTY",
            strikePrice: strike,
            expiryDate: expiry,
            optionType: type,
            lotSize: 50, // NIFTY lot size
            currentPrice: 0.0, // Will be updated from real-time data
            bid: 0.0,
            ask: 0.0,
            volume: 0,
            openInterest: 0,
            impliedVolatility: 0.0,
            delta: 0.0,
            gamma: 0.0,
            theta: 0.0,
            vega: 0.0,
            timestamp: Date()
        )
    }
    
    private func isMarketClosed() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour < 9 || hour >= 15 // Market hours: 9:15 AM to 3:30 PM
    }
}

