import Foundation
import NaturalLanguage
import os.log
import SharedCoreModels

public enum Sentiment: String {
    case positive = "Positive"
    case negative = "Negative"
    case neutral = "Neutral"
    case unknown = "Unknown"
}

/// A class that analyzes sentiment in text using Natural Language framework
public class SentimentAnalyzer {
    // MARK: - Properties
    
    /// Logger for debugging and monitoring
    private let logger = Logger(subsystem: "com.trading.app", category: "SentimentAnalyzer")
    
    /// In a production app, this would be a custom model trained on financial news
    private var model: NLModel?
    
    /// NLTagger for sentiment analysis
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    // MARK: - Initialization
    
    public init() {
        // In the future, you can load a custom Core ML model like this:
        // if let compiledModelURL = Bundle.main.url(forResource: "FinancialSentimentClassifier", withExtension: "mlmodelc") {
        //     model = try? NLModel(contentsOf: compiledModelURL)
        // }
    }
    
    // MARK: - Public Methods
    
    /// Analyzes the sentiment of a given text using the Natural Language framework.
    /// - Parameter text: The input string to analyze.
    /// - Returns: A tuple containing the `Sentiment` and the raw score.
    public func analyzeSentiment(for text: String) -> (sentiment: Sentiment, score: Double) {
        // If a custom model is loaded, use it for prediction.
        if let model = model {
            let sentimentString = model.predictedLabel(for: text) ?? "Neutral"
            // This assumes the custom model returns one of the Sentiment rawValues.
            // You would also need a way to get a score from a custom model.
            return (Sentiment(rawValue: sentimentString) ?? .neutral, 0.0)
        }
        
        // Fallback to the built-in NLTagger if no custom model is available.
        tagger.string = text
        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)

        guard let sentimentScoreString = tag?.rawValue,
              let sentimentScore = Double(sentimentScoreString) else {
            return (.unknown, 0.0)
        }

        let sentiment: Sentiment
        if sentimentScore > 0.25 {
            sentiment = .positive
        } else if sentimentScore < -0.25 {
            sentiment = .negative
        } else {
            sentiment = .neutral
        }
        
        return (sentiment, sentimentScore)
    }
    
    /// Creates a MarketSentimentAnalysis object from the sentiment analysis result
    /// - Parameter text: The text to analyze
    /// - Returns: A dictionary with sentiment analysis results
    public func createMarketSentimentAnalysis(for text: String) -> [String: Any] {
        let (sentiment, score) = analyzeSentiment(for: text)
        
        return [
            "sentimentScore": score,
            "marketSentiment": sentiment.rawValue,
            "keywords": [] as [String],
            "sources": [] as [String]
        ]
    }

    /// Analyzes sentiment for multiple news contents
    /// - Parameter newsContents: Array of news article contents
    /// - Returns: Aggregated sentiment result
    public func analyzeNewsContent(newsContents: [String]) -> SentimentResult {
        guard !newsContents.isEmpty else {
            return SentimentResult(sentiment: .unknown, score: 0.0, description: "No content provided")
        }

        // Concatenate all news contents
        let combinedText = newsContents.joined(separator: " ")

        let (sentiment, score) = analyzeSentiment(for: combinedText)

        let sentimentType: SentimentType
        switch sentiment {
        case .positive:
            sentimentType = .positive
        case .negative:
            sentimentType = .negative
        case .neutral:
            sentimentType = .neutral
        case .unknown:
            sentimentType = .unknown
        }

        let description: String
        switch sentiment {
        case .positive:
            description = "Overall positive market sentiment detected in news."
        case .negative:
            description = "Overall negative market sentiment detected in news."
        case .neutral:
            description = "Neutral market sentiment detected in news."
        case .unknown:
            description = "Unable to determine sentiment from news content."
        }

        return SentimentResult(sentiment: sentimentType, score: score, description: description)
    }
}
