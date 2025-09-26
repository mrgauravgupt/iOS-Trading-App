import Foundation

class MarketAnalysisAgent: BaseAgent {
    private let sentimentAnalyzer = SentimentAnalyzer()
    
    override init(name: String) {
        super.init(name: name)
    }
    
    override func makeDecision(marketData: MarketData, news: [Article]) -> String {
        // Concatenate all news descriptions to analyze sentiment
        let allNewsText = news.compactMap { $0.description }.joined(separator: " ")
        let sentiment = sentimentAnalyzer.analyzeSentiment(for: allNewsText)
        
        if sentiment == "Positive" {
            return "Buy - Positive sentiment"
        } else if sentiment == "Negative" {
            return "Sell - Negative sentiment"
        } else {
            return "Hold - Neutral sentiment"
        }
    }
}