import Foundation

class StrategySelectionAgent: BaseAgent {
    private let technicalEngine = TechnicalAnalysisEngine()
    
    override init(name: String) {
        super.init(name: name)
    }
    
    override func makeDecision(marketData: MarketData, news: [Article]) -> String {
        let rsi = technicalEngine.calculateRSI(prices: [marketData.price])
        let macd = technicalEngine.calculateMACD(prices: [marketData.price])
        
        if rsi > 70 {
            return "Strategy: Sell - RSI indicates overbought"
        } else if rsi < 30 {
            return "Strategy: Buy - RSI indicates oversold"
        } else if macd.macd > macd.signal {
            return "Strategy: Buy - MACD bullish"
        } else {
            return "Strategy: Hold - No clear signal"
        }
    }
}
