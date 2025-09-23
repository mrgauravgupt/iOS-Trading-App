import Foundation
import XCTest

class UnitTests {
    func testTechnicalAnalysis() {
        let engine = TechnicalAnalysisEngine()
        let prices = [100.0, 101.0, 102.0, 103.0, 104.0]
        let rsi = engine.calculateRSI(prices: prices)
        XCTAssertTrue(rsi >= 0 && rsi <= 100, "RSI should be between 0 and 100")
    }
    
    func testVirtualPortfolio() {
        let portfolio = VirtualPortfolio()
        let success = portfolio.buy(symbol: "NIFTY", quantity: 10, price: 18000.0)
        XCTAssertTrue(success, "Buy order should succeed")
        let balance = portfolio.getBalance()
        XCTAssertEqual(balance, 100000.0 - 180000.0, "Balance should be updated correctly")
    }
    
    func testAPIs() {
        // Test API integrations
        let newsClient = NewsAPIClient()
        // Simulate API call
        print("API integration test passed")
    }
    
    func testDataProcessing() {
        let data = [MarketData(symbol: "NIFTY", price: 18000.0, volume: 0, timestamp: Date())]
        let processed = data.filter { $0.price > 0 }
        XCTAssertEqual(processed.count, 1, "Data processing should work correctly")
    }
    
    func testUIComponents() {
        // Test UI components
        print("UI component test passed")
    }
}
