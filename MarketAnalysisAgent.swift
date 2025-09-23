import Foundation

class MarketAnalysisAgent {
    private let sentimentAnalyzer = SentimentAnalyzer()

    func analyzeMarketWithSentiment(news: [Article], marketData: [MarketData]) -> String {
        let sentiment = news.map { sentimentAnalyzer.analyzeSentiment(for: $0.title) }
        let averageSentiment = sentiment.filter { $0 != "Neutral" }.count > sentiment.count / 2 ? "Positive" : "Negative"
        return "Market sentiment is \(averageSentiment) based on recent news."
    }
}
