// This is a partial refactoring to replace the mock implementation in PaperTradingView

/// Get current market prices for all symbols
private func getCurrentMarketPrices() async throws -> [String: Double] {
    logger.info("Fetching current market prices")
    
    // Get the list of symbols in the portfolio
    let portfolioSymbols = portfolio.positions.map { $0.symbol }
    
    // Add watchlist symbols
    let watchlistSymbols = watchlist.map { $0.symbol }
    
    // Combine and remove duplicates
    let allSymbols = Array(Set(portfolioSymbols + watchlistSymbols))
    
    guard !allSymbols.isEmpty else {
        logger.info("No symbols to fetch prices for")
        return [:]
    }
    
    // Create a dictionary to store results
    var prices: [String: Double] = [:]
    
    do {
        // Fetch latest prices for all symbols
        let marketDataPoints = try await dataProvider.fetchLatestPrices(for: allSymbols)
        
        // Convert to dictionary mapping symbol to price
        for dataPoint in marketDataPoints {
            prices[dataPoint.symbol] = dataPoint.close
        }
        
        logger.info("Successfully fetched prices for \(prices.count) symbols")
        return prices
    } catch {
        logger.error("Failed to fetch market prices: \(error.localizedDescription)")
        throw error
    }
}

/// Get current market prices for all symbols (synchronous version with completion handler)
private func getCurrentMarketPrices(completion: @escaping ([String: Double]) -> Void) {
    Task {
        do {
            let prices = try await getCurrentMarketPrices()
            DispatchQueue.main.async {
                completion(prices)
            }
        } catch {
            logger.error("Error fetching market prices: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion([:])
            }
        }
    }
}
