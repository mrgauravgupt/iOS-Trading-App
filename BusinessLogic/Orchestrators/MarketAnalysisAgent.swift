import Foundation
import os.log
import SharedCoreModels

class MarketAnalysisAgent: BaseAgent {
    private let sentimentAnalyzer = SentimentAnalyzer()
    private let logger = Logger(subsystem: "com.trading.app", category: "MarketAnalysisAgent")
    
    // Thresholds for decision making
    private let strongBuyThreshold = 0.5
    private let buyThreshold = 0.25
    private let strongSellThreshold = -0.5
    private let sellThreshold = -0.25
    
    override init(name: String) {
        super.init(name: name)
        logger.info("Initialized MarketAnalysisAgent with name: \(name)")
    }
    
    override func makeDecision(marketData: MarketData, news: [Article]) -> String {
        logger.debug("Making decision based on \(news.count) news articles")
        
        // Extract news descriptions
        let newsContents = news.compactMap { $0.description }
        
        // Use the new batch analysis method for news articles
        let sentimentResult = sentimentAnalyzer.analyzeNewsContent(newsContents: newsContents)
        
        // Get the sentiment and score from the result
        let sentiment = sentimentResult.sentiment
        let score = sentimentResult.score
        
        // Log the sentiment analysis result
        logger.debug("Sentiment analysis result: \(sentimentResult.description)")
        
        // Make a more nuanced decision based on the sentiment score
        let decision: String
        
        switch sentiment {
        case .positive:
            if score > strongBuyThreshold {
                decision = "Strong Buy - Very Positive sentiment"
            } else {
                decision = "Buy - Positive sentiment"
            }
        case .negative:
            if score < strongSellThreshold {
                decision = "Strong Sell - Very Negative sentiment"
            } else {
                decision = "Sell - Negative sentiment"
            }
        case .neutral:
            // For neutral sentiment, consider price movement for a slight bias
            if marketData.price > 0 {
                decision = "Weak Buy - Neutral sentiment with positive price"
            } else if marketData.price < 0 {
                decision = "Weak Sell - Neutral sentiment with negative price"
            } else {
                decision = "Hold - Neutral sentiment"
            }
        case .unknown:
            decision = "Hold - Insufficient data for sentiment analysis"
        }
        
        // Add confidence information to the decision
        let confidenceText = String(format: " (confidence: %.2f)", abs(score))
        return decision + confidenceText
    }
    
    // Additional method to analyze historical sentiment trends
    func analyzeHistoricalSentiment(newsHistory: [[String]]) -> [SentimentResult] {
        logger.info("Analyzing historical sentiment for \(newsHistory.count) time periods")
        
        // Process each time period's news content
        return newsHistory.map { periodNews in
            sentimentAnalyzer.analyzeNewsContent(newsContents: periodNews)
        }
    }
}
