import Foundation
import Combine
import SharedCoreModels

/// Manages multi-timeframe OHLC data aggregation and real-time updates
class TimeframeDataManager: ObservableObject {
    // MARK: - Properties

    @Published var timeframeData: [Timeframe: [String: [OHLCData]]] = [:]
    @Published var lastUpdateTime: Date?

    private var cancellables = Set<AnyCancellable>()
    private var webSocketManager: WebSocketManager!
    private var dataBuffers: [Timeframe: [String: [MarketData]]] = [:]
    private var timers: [Timeframe: Timer] = [:]
    private var subscribedSymbols: [String: Set<Timeframe>] = [:]

    // MARK: - Initialization

    init() {
        // Initialize without WebSocketManager - will be set up later
        setupTimeframeTimers()
    }

    func setupWebSocketManager(_ webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        setupWebSocketSubscription()
    }

    deinit {
        timers.values.forEach { $0.invalidate() }
        cancellables.removeAll()
    }

    // MARK: - Public Methods

    /// Subscribe to real-time data for a specific symbol and timeframe
    func subscribeToSymbol(_ symbol: String, timeframe: Timeframe) {
        // Initialize data buffer for this timeframe if needed
        if dataBuffers[timeframe] == nil {
            dataBuffers[timeframe] = [:]
        }
        if dataBuffers[timeframe]?[symbol] == nil {
            dataBuffers[timeframe]?[symbol] = []
        }

        // Initialize timeframe data storage
        if timeframeData[timeframe] == nil {
            timeframeData[timeframe] = [:]
        }
        if timeframeData[timeframe]?[symbol] == nil {
            timeframeData[timeframe]?[symbol] = []
        }
        
        // Track subscribed timeframes for this symbol
        if subscribedSymbols[symbol] == nil {
            subscribedSymbols[symbol] = []
        }
        subscribedSymbols[symbol]?.insert(timeframe)

        // Subscribe to WebSocket for real-time updates
        webSocketManager.subscribeToSymbol(symbol)
    }

    /// Get OHLC data for a specific symbol and timeframe
    func getOHLCData(for symbol: String, timeframe: Timeframe) -> [OHLCData] {
        return timeframeData[timeframe]?[symbol] ?? []
    }

    /// Get latest OHLC bar for a symbol and timeframe
    func getLatestOHLC(for symbol: String, timeframe: Timeframe) -> OHLCData? {
        return timeframeData[timeframe]?[symbol]?.last
    }

    // MARK: - Private Methods

    private func setupWebSocketSubscription() {
        webSocketManager.onTick = { [weak self] marketData in
            self?.processMarketData(marketData)
        }
    }

    private func setupTimeframeTimers() {
        // Set up timers for each timeframe to aggregate data
        for timeframe in Timeframe.allCases {
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeframe.seconds), repeats: true) { [weak self] _ in
                self?.aggregateTimeframeData(timeframe)
            }
            timers[timeframe] = timer
        }
    }

    private func processMarketData(_ marketData: MarketData) {
        // Add market data to 1-minute buffer (base timeframe)
        let oneMinuteTimeframe = Timeframe.oneMinute
        if dataBuffers[oneMinuteTimeframe] == nil {
            dataBuffers[oneMinuteTimeframe] = [:]
        }
        if dataBuffers[oneMinuteTimeframe]?[marketData.symbol] == nil {
            dataBuffers[oneMinuteTimeframe]?[marketData.symbol] = []
        }

        dataBuffers[oneMinuteTimeframe]?[marketData.symbol]?.append(marketData)

        // Update last update time
        lastUpdateTime = Date()
    }

    private func aggregateTimeframeData(_ timeframe: Timeframe) {
        guard timeframe != .oneMinute else {
            // For 1-minute, directly convert market data to OHLC
            aggregateOneMinuteData()
            return
        }

        // For higher timeframes, resample from 1-minute data
        resampleFromOneMinute(to: timeframe)
    }

    private func aggregateOneMinuteData() {
        let timeframe = Timeframe.oneMinute

        for (symbol, marketDataArray) in dataBuffers[timeframe] ?? [:] {
            guard !marketDataArray.isEmpty else { continue }

            // Group by minute intervals
            let groupedData = Dictionary(grouping: marketDataArray) { data in
                // Round down to nearest minute
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: data.timestamp)
                return calendar.date(from: components)!
            }

            // Create OHLC bars for each minute
            let ohlcBars = groupedData.map { (timestamp, dataPoints) -> OHLCData in
                let prices = dataPoints.map { $0.price }
                let volumes = dataPoints.map { $0.volume }

                return OHLCData(
                    timestamp: timestamp,
                    open: prices.first ?? 0,
                    high: prices.max() ?? 0,
                    low: prices.min() ?? 0,
                    close: prices.last ?? 0,
                    volume: volumes.reduce(0, +),
                    timeframe: timeframe
                )
            }.sorted { $0.timestamp < $1.timestamp }

            // Update timeframe data
            if timeframeData[timeframe] == nil {
                timeframeData[timeframe] = [:]
            }
            timeframeData[timeframe]?[symbol] = ohlcBars

            // Clear processed data
            dataBuffers[timeframe]?[symbol] = []
        }
    }

    private func resampleFromOneMinute(to targetTimeframe: Timeframe) {
        let sourceTimeframe = Timeframe.oneMinute

        for (symbol, oneMinuteData) in timeframeData[sourceTimeframe] ?? [:] {
            guard !oneMinuteData.isEmpty else { continue }

            // Calculate number of source bars per target bar
            let barsPerTarget = targetTimeframe.seconds / sourceTimeframe.seconds

            // Group 1-minute bars into target timeframe groups
            let resampledBars = stride(from: 0, to: oneMinuteData.count, by: barsPerTarget).map { startIndex -> OHLCData? in
                let endIndex = min(startIndex + barsPerTarget, oneMinuteData.count)
                let bars = Array(oneMinuteData[startIndex..<endIndex])

                guard !bars.isEmpty else { return nil }

                let open = bars.first!.open
                let high = bars.map { $0.high }.max() ?? 0
                let low = bars.map { $0.low }.min() ?? 0
                let close = bars.last!.close
                let volume = bars.map { $0.volume }.reduce(0, +)
                let timestamp = bars.first!.timestamp

                return OHLCData(
                    timestamp: timestamp,
                    open: open,
                    high: high,
                    low: low,
                    close: close,
                    volume: volume,
                    timeframe: targetTimeframe
                )
            }.compactMap { $0 }

            // Update timeframe data
            if timeframeData[targetTimeframe] == nil {
                timeframeData[targetTimeframe] = [:]
            }
            timeframeData[targetTimeframe]?[symbol] = resampledBars
        }
    }

    // MARK: - Data Management

    /// Clear all data for a specific symbol
    func clearData(for symbol: String) {
        for timeframe in Timeframe.allCases {
            timeframeData[timeframe]?[symbol] = []
            dataBuffers[timeframe]?[symbol] = []
        }
    }

    /// Clear all data
    func clearAllData() {
        timeframeData.removeAll()
        dataBuffers.removeAll()
    }

    /// Get available symbols for a timeframe
    func getAvailableSymbols(for timeframe: Timeframe) -> [String] {
        return Array((timeframeData[timeframe] ?? [:]).keys)
    }
    
    /// Unsubscribe from a symbol for a specific timeframe
    func unsubscribeFromSymbol(_ symbol: String, timeframe: Timeframe) {
        // Remove data for this symbol and timeframe
        timeframeData[timeframe]?[symbol] = nil
        dataBuffers[timeframe]?[symbol] = nil
        
        // Check if symbol is subscribed to any other timeframes
        if let timeframes = subscribedSymbols[symbol] {
            var updatedTimeframes = timeframes
            updatedTimeframes.remove(timeframe)
            
            if updatedTimeframes.isEmpty {
                // If no other timeframes are subscribed, unsubscribe from WebSocket
                subscribedSymbols.removeValue(forKey: symbol)
                webSocketManager?.unsubscribeFromSymbol(symbol)
            } else {
                // Update the set of timeframes
                subscribedSymbols[symbol] = updatedTimeframes
            }
        }
    }
}
