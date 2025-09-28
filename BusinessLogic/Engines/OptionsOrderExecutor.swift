import UIKit
import Foundation
import Combine
import SharedCoreModels

class OptionsOrderExecutor: ObservableObject {
    @Published var executionResults: [ExecutionResult] = []
    @Published var pendingOrders: [OptionsOrder] = []
    @Published var orderHistory: [OrderRecord] = []
    @Published var positions: [OptionsPosition] = []
    
    private let zerodhaClient = ZerodhaAPIClient()
    private let riskManager = AdvancedRiskManager()
    private let maxSlippage: Double = 0.01 // 1% slippage protection
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    func initialize() async throws {
        // Initialize the order executor
        // This could include setting up connections, loading configurations, etc.
        print("OptionsOrderExecutor initialized")
    }
    
    // MARK: - Order Execution
    
    func executeOrder(_ order: OptionsOrder) async throws -> ExecutionResult {
        print("Executing order: \(order.symbol) - \(order.action) \(order.quantity)")
        
        do {
            // Pre-execution validation
            try await validateOrder(order)
            
            // Determine execution strategy
            let strategy = determineExecutionStrategy(for: order)
            
            // Execute based on strategy
            let result = try await executeWithStrategy(order, strategy: strategy)
            
            // Post-execution processing
            await processExecutionResult(order, result: result)
            
            return result
            
        } catch {
            let errorResult = ExecutionResult(
                isSuccessful: false,
                orderId: nil,
                executedPrice: nil,
                executedQuantity: nil,
                errorMessage: error.localizedDescription
            )
            
            throw error
        }
    }
    
    func cancelOrder(_ orderId: String) async throws -> Bool {
        print("Cancelling order: \(orderId)")
        
        // Implementation for order cancellation
        // This would integrate with your broker's API
        let result = try await zerodhaClient.cancelOrder(orderId: orderId)
        
        // Parse the response
        guard let responseDict = result as? [String: Any],
              let status = responseDict["status"] as? String else {
            throw OrderExecutionError.invalidResponse
        }
        
        return status == "SUCCESS"
    }
    
    func getPositionPnL(_ symbol: String) -> Double {
        guard let position = positions.first(where: { $0.symbol == symbol }) else {
            return 0.0
        }
        return position.unrealizedPnL
    }
    
    func closePosition(_ symbol: String) async throws -> ExecutionResult {
        guard let position = positions.first(where: { $0.symbol == symbol }) else {
            throw OrderExecutionError.positionNotFound
        }
        
        let closeOrder = OptionsOrder(
            symbol: position.symbol,
            action: position.quantity > 0 ? .sell : .buy,
            quantity: abs(position.quantity),
            orderType: .market,
            price: position.currentPrice,
            strikePrice: position.strikePrice,
            expiryDate: position.expiryDate,
            optionType: position.optionType
        )
        
        return try await executeOrder(closeOrder)
    }
    
    func closeAllPositions() async throws -> [ExecutionResult] {
        var results: [ExecutionResult] = []
        
        for position in positions {
            do {
                let result = try await closePosition(position.symbol)
                results.append(result)
            } catch {
                let errorResult = ExecutionResult(
                    isSuccessful: false,
                    orderId: nil,
                    executedPrice: nil,
                    executedQuantity: nil,
                    errorMessage: "Failed to close \(position.symbol): \(error.localizedDescription)"
                )
                results.append(errorResult)
            }
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    private func validateOrder(_ order: OptionsOrder) async throws {
        // Check market hours
        guard isMarketOpen() else {
            throw OrderExecutionError.marketClosed
        }
        
        // Validate order parameters
        guard order.quantity > 0 else {
            throw OrderExecutionError.invalidQuantity
        }
        
        guard order.strikePrice > 0 else {
            throw OrderExecutionError.invalidStrikePrice
        }
        
        // Check expiry date
        guard order.expiryDate > Date() else {
            throw OrderExecutionError.expiredContract
        }
        
        // Risk validation
        guard riskManager.validateOrder(order) else {
            throw OrderExecutionError.riskValidationFailed
        }
        
        // Check available funds (for buy orders)
        if order.action == .buy {
            try await validateFunds(for: order)
        }
    }
    
    private func determineExecutionStrategy(for order: OptionsOrder) -> ExecutionStrategy {
        // Determine best execution strategy based on:
        // - Order size
        // - Market conditions
        // - Liquidity
        // - Volatility
        
        if order.quantity <= 50 { // Small orders
            return .immediate
        } else if order.quantity <= 200 { // Medium orders
            return .twap // Time-weighted average price
        } else { // Large orders
            return .iceberg // Break into smaller chunks
        }
    }
    
    private func executeWithStrategy(_ order: OptionsOrder, strategy: ExecutionStrategy) async throws -> ExecutionResult {
        switch strategy {
        case .immediate:
            return try await executeImmediate(order)
        case .twap:
            return try await executeTWAP(order)
        case .iceberg:
            return try await executeIceberg(order)
        case .vwap:
            return try await executeVWAP(order)
        }
    }
    
    private func executeImmediate(_ order: OptionsOrder) async throws -> ExecutionResult {
        // Get current market price
        let marketPrice = try await getCurrentMarketPrice(for: order.symbol)
        
        // Apply slippage protection
        let executionPrice = applySlippageProtection(marketPrice, for: order)
        
        // Execute the order and parse the response
        let orderRequest = createOrderRequest(order, price: executionPrice)
        guard let response = try await zerodhaClient.placeOrder(orderRequest) as? [String: Any] else {
            throw OrderExecutionError.invalidResponse
        }
        
        // Extract values with proper type checking
        let status = response["status"] as? String ?? "FAILED"
        let orderId = response["order_id"] as? String
        let message = response["message"] as? String
        
        // Create execution result
        return ExecutionResult(
            isSuccessful: status == "SUCCESS",
            orderId: orderId,
            executedPrice: executionPrice,
            executedQuantity: order.quantity,
            errorMessage: status == "SUCCESS" ? nil : message
        )
    }
    
    private func executeTWAP(_ order: OptionsOrder) async throws -> ExecutionResult {
        // Time-Weighted Average Price execution
        let chunks = splitOrderIntoChunks(order, chunkCount: 5)
        let interval: TimeInterval = 60 // 1 minute between chunks
        
        var totalExecuted = 0
        var totalValue = 0.0
        var lastOrderId: String?
        
        for (index, chunk) in chunks.enumerated() {
            if index > 0 {
                // Wait between chunks
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            
            let result = try await executeImmediate(chunk)
            
            if result.isSuccessful {
                totalExecuted += result.executedQuantity ?? 0
                totalValue += Double(result.executedQuantity ?? 0) * (result.executedPrice ?? 0)
                lastOrderId = result.orderId
            } else {
                // If any chunk fails, return the error
                return result
            }
        }
        
        let averagePrice = totalExecuted > 0 ? totalValue / Double(totalExecuted) : 0
        
        return ExecutionResult(
            isSuccessful: true,
            orderId: lastOrderId,
            executedPrice: averagePrice,
            executedQuantity: totalExecuted,
            errorMessage: nil
        )
    }
    
    private func executeIceberg(_ order: OptionsOrder) async throws -> ExecutionResult {
        // Iceberg execution - show only small portions at a time
        let visibleSize = min(order.quantity / 10, 25) // Show max 25 lots at a time
        let chunks = splitOrderIntoChunks(order, chunkSize: visibleSize)
        
        var totalExecuted = 0
        var totalValue = 0.0
        var lastOrderId: String?
        
        for chunk in chunks {
            let result = try await executeImmediate(chunk)
            
            if result.isSuccessful {
                totalExecuted += result.executedQuantity ?? 0
                totalValue += Double(result.executedQuantity ?? 0) * (result.executedPrice ?? 0)
                lastOrderId = result.orderId
                
                // Small delay between chunks
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            } else {
                return result
            }
        }
        
        let averagePrice = totalExecuted > 0 ? totalValue / Double(totalExecuted) : 0
        
        return ExecutionResult(
            isSuccessful: true,
            orderId: lastOrderId,
            executedPrice: averagePrice,
            executedQuantity: totalExecuted,
            errorMessage: nil
        )
    }
    
    private func executeVWAP(_ order: OptionsOrder) async throws -> ExecutionResult {
        // Volume-Weighted Average Price execution
        // This is a simplified implementation
        return try await executeTWAP(order)
    }
    
    private func processExecutionResult(_ order: OptionsOrder, result: ExecutionResult) async {
        guard result.isSuccessful else { return }
        
        // Update positions
        await updatePosition(from: order, result: result)
        
        // Record order history
        let orderRecord = OrderRecord(
            order: order,
            result: result,
            timestamp: Date()
        )
        orderHistory.append(orderRecord)
        
        // Notify about execution
        NotificationCenter.default.post(name: .orderExecuted, object: orderRecord)
        
        print("Order executed successfully: \(order.symbol)")
    }
    
    private func updatePosition(from order: OptionsOrder, result: ExecutionResult) async {
        guard let executedQuantity = result.executedQuantity,
              let executedPrice = result.executedPrice else { return }
        
        if let existingIndex = positions.firstIndex(where: { $0.symbol == order.symbol }) {
            // Update existing position
            let existing = positions[existingIndex]
            let newQuantity = existing.quantity + (order.action == .buy ? executedQuantity : -executedQuantity)
            
            if newQuantity == 0 {
                // Position closed
                positions.remove(at: existingIndex)
            } else {
                // Update position
                let newAvgPrice = calculateNewAveragePrice(
                    existingQuantity: existing.quantity,
                    existingPrice: existing.entryPrice,
                    newQuantity: executedQuantity,
                    newPrice: executedPrice,
                    action: order.action
                )
                
                positions[existingIndex] = OptionsPosition(
                    symbol: order.symbol,
                    quantity: newQuantity,
                    strikePrice: order.strikePrice,
                    expiryDate: order.expiryDate,
                    optionType: order.optionType,
                    entryPrice: newAvgPrice,
                    currentPrice: executedPrice,
                    timestamp: existing.timestamp
                )
            }
        } else if order.action == .buy {
            // New position
            let newPosition = OptionsPosition(
                symbol: order.symbol,
                quantity: executedQuantity,
                strikePrice: order.strikePrice,
                expiryDate: order.expiryDate,
                optionType: order.optionType,
                entryPrice: executedPrice,
                currentPrice: executedPrice,
                timestamp: Date()
            )
            positions.append(newPosition)
        }
    }
    
    private func loadExistingPositions() async {
        // Load positions from broker API
        do {
            let brokerPositionsData = try await zerodhaClient.getPositions()
            
            // Parse the JSON response
            guard let brokerPositions = brokerPositionsData as? [[String: Any]] else {
                print("Failed to parse positions data")
                return
            }
            
            // Convert broker positions to our format
            positions = brokerPositions.compactMap { brokerPosition in
                convertBrokerPosition(brokerPosition)
            }
            
            print("Loaded \(positions.count) existing positions")
            
        } catch {
            print("Failed to load existing positions: \(error)")
        }
    }
    
    private func setupPositionUpdates() {
        // Setup real-time position value updates
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePositionValues()
            }
        }
    }
    
    private func updatePositionValues() async {
        for (index, position) in positions.enumerated() {
            do {
                let currentPrice = try await getCurrentMarketPrice(for: position.symbol)
                positions[index] = OptionsPosition(
                    symbol: position.symbol,
                    quantity: position.quantity,
                    strikePrice: position.strikePrice,
                    expiryDate: position.expiryDate,
                    optionType: position.optionType,
                    entryPrice: position.entryPrice,
                    currentPrice: currentPrice,
                    timestamp: position.timestamp
                )
            } catch {
                print("Failed to update price for \(position.symbol): \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMarketPrice(for symbol: String) async throws -> Double {
        // Get current market price from data provider
        let quoteData = await zerodhaClient.getQuote(symbol: symbol)
        
        // Parse the quote data to get the last price
        guard let quote = quoteData as? [String: Any],
              let lastPrice = quote["last_price"] as? Double else {
            throw OrderExecutionError.invalidMarketData
        }
        
        return lastPrice
    }
    
    private func applySlippageProtection(_ marketPrice: Double, for order: OptionsOrder) -> Double {
        let slippageAmount = marketPrice * maxSlippage
        
        switch order.action {
        case .buy:
            return marketPrice + slippageAmount // Pay slightly more for buys
        case .sell:
            return marketPrice - slippageAmount // Accept slightly less for sells
        case .hold:
            return marketPrice // No slippage adjustment for hold orders
        }
    }
    
    private func createOrderRequest(_ order: OptionsOrder, price: Double) -> [String: Any] {
        var requestDict: [String: Any] = [
            "tradingsymbol": order.symbol,
            "exchange": "NFO",
            "transaction_type": order.action == .buy ? "BUY" : "SELL",
            "quantity": order.quantity,
            "product": "MIS", // Intraday
            "order_type": order.orderType == .market ? "MARKET" : "LIMIT",
            "validity": "DAY"
        ]
        
        // Add price only for limit orders
        if order.orderType != .market {
            requestDict["price"] = price
        }
        
        return requestDict
    }
    
    private func splitOrderIntoChunks(_ order: OptionsOrder, chunkCount: Int) -> [OptionsOrder] {
        let chunkSize = order.quantity / chunkCount
        let remainder = order.quantity % chunkCount
        
        var chunks: [OptionsOrder] = []
        
        for i in 0..<chunkCount {
            let quantity = chunkSize + (i < remainder ? 1 : 0)
            
            let chunk = OptionsOrder(
                symbol: order.symbol,
                action: order.action,
                quantity: quantity,
                orderType: order.orderType,
                price: order.price,
                strikePrice: order.strikePrice,
                expiryDate: order.expiryDate,
                optionType: order.optionType
            )
            
            chunks.append(chunk)
        }
        
        return chunks
    }
    
    private func splitOrderIntoChunks(_ order: OptionsOrder, chunkSize: Int) -> [OptionsOrder] {
        var chunks: [OptionsOrder] = []
        var remainingQuantity = order.quantity
        
        while remainingQuantity > 0 {
            let currentChunkSize = min(remainingQuantity, chunkSize)
            
            let chunk = OptionsOrder(
                symbol: order.symbol,
                action: order.action,
                quantity: currentChunkSize,
                orderType: order.orderType,
                price: order.price,
                strikePrice: order.strikePrice,
                expiryDate: order.expiryDate,
                optionType: order.optionType
            )
            
            chunks.append(chunk)
            remainingQuantity -= currentChunkSize
        }
        
        return chunks
    }
    
    private func calculateNewAveragePrice(existingQuantity: Int, existingPrice: Double, newQuantity: Int, newPrice: Double, action: TradeAction) -> Double {
        if action == .buy {
            let totalValue = (Double(existingQuantity) * existingPrice) + (Double(newQuantity) * newPrice)
            let totalQuantity = existingQuantity + newQuantity
            return totalValue / Double(totalQuantity)
        } else {
            // For sells, keep the existing average price
            return existingPrice
        }
    }
    
    private func validateFunds(for order: OptionsOrder) async throws {
        // Check if sufficient funds are available
        let requiredMargin = try await calculateRequiredMargin(for: order)
        let availableFunds = try await zerodhaClient.getAvailableFunds()
        
        guard availableFunds >= requiredMargin else {
            throw OrderExecutionError.insufficientFunds
        }
    }
    
    private func calculateRequiredMargin(for order: OptionsOrder) async throws -> Double {
        // Calculate required margin for the order
        // This is a simplified calculation
        let optionPrice = try await getCurrentMarketPrice(for: order.symbol)
        return optionPrice * Double(order.quantity) * 50 // NIFTY lot size
    }
    
    private func convertBrokerPosition(_ brokerPosition: [String: Any]) -> OptionsPosition? {
        // Convert broker-specific position format to our format
        guard let symbol = brokerPosition["tradingsymbol"] as? String,
              let quantity = brokerPosition["quantity"] as? Int,
              let averagePrice = brokerPosition["average_price"] as? Double else {
            return nil
        }
        
        // Extract option details from symbol (e.g., NIFTY22JUN18000CE)
        let strikePrice = extractStrikePrice(from: symbol)
        let expiryDate = extractExpiryDate(from: symbol)
        let optionType = symbol.hasSuffix("CE") ? OptionType.call : OptionType.put
        
        return OptionsPosition(
            symbol: symbol,
            quantity: quantity,
            strikePrice: strikePrice,
            expiryDate: expiryDate,
            optionType: optionType,
            entryPrice: averagePrice,
            currentPrice: averagePrice,
            timestamp: Date()
        )
    }
    
    private func extractStrikePrice(from symbol: String) -> Double {
        // Extract strike price from symbol (e.g., NIFTY22JUN18000CE -> 18000)
        // This is a simplified implementation
        let pattern = "\\d{5}"
        if let range = symbol.range(of: pattern, options: .regularExpression) {
            return Double(symbol[range]) ?? 0.0
        }
        return 0.0
    }
    
    private func extractExpiryDate(from symbol: String) -> Date {
        // Extract expiry date from symbol (e.g., NIFTY22JUN18000CE -> 22JUN)
        // This is a simplified implementation
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2022 // Default
        components.month = 6 // Default
        components.day = 30 // Default
        return calendar.date(from: components) ?? Date()
    }
    
    private func isMarketOpen() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        let weekday = calendar.component(.weekday, from: now)
        guard weekday >= 2 && weekday <= 6 else { return false }
        
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        let marketStart = 9 * 60 + 15
        let marketEnd = 15 * 60 + 30
        let currentTime = hour * 60 + minute
        
        return currentTime >= marketStart && currentTime <= marketEnd
    }
}

// MARK: - Supporting Types
enum ExecutionStrategy {
    case immediate
    case twap // Time-Weighted Average Price
    case iceberg
    case vwap // Volume-Weighted Average Price
}

enum OrderExecutionError: Error {
    case marketClosed
    case invalidQuantity
    case invalidStrikePrice
    case expiredContract
    case insufficientFunds
    case positionNotFound
    case executionTimeout
    case slippageExceeded
    case riskValidationFailed
    case invalidMarketData
    case invalidResponse
}

struct OrderRecord: Codable {
    var id = UUID()
    let order: OptionsOrder
    let result: ExecutionResult
    let timestamp: Date
}

// We're using [String: Any] for OrderRequest instead of a struct
// to match the JSON request format expected by the broker API

// We're using [String: Any] for BrokerPosition instead of a struct
// to match the JSON response from the broker API

// MARK: - Notifications
extension Notification.Name {
    static let orderExecuted = Notification.Name("orderExecuted")
    static let marketDataUpdated = Notification.Name("marketDataUpdated")
}