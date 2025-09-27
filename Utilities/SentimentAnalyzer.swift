import Foundation
import NaturalLanguage
import os.log

/// Represents the sentiment of analyzed text
public enum Sentiment: String, Codable {
    case positive = "Positive"
    case negative = "Negative"
    case neutral = "Neutral"
    case unknown = "Unknown"
    
    /// Returns a descriptive emoji for the sentiment
    public var emoji: String {
        switch self {
        case .positive: return "📈"
        case .negative: return "📉"
        case .neutral: return "➖"
        case .unknown: return "❓"
        }
    }
}

/// Result of sentiment analysis containing sentiment classification and confidence score
public struct SentimentResult: Codable, Equatable {
    public let sentiment: Sentiment
    public let score: Double
    public let text: String
    public let timestamp: Date
    
    public init(sentiment: Sentiment, score: Double, text: String) {
        self.sentiment = sentiment
        self.score = score
        self.text = text
        self.timestamp = Date()
    }
    
    /// Returns a formatted description of the sentiment result
    public var description: String {
        return "\(sentiment.emoji) \(sentiment.rawValue) (confidence: \(String(format: "%.2f", abs(score))))"
    }
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
    
    /// Cache for recent sentiment analyses to improve performance
    private var cache: [String: SentimentResult] = [:]
    
    /// Maximum cache size
    private let maxCacheSize = 100
    
    /// Threshold values for sentiment classification
    private let positiveThreshold: Double
    private let negativeThreshold: Double
    
    // MARK: - Initialization
    
    /// Initializes a new SentimentAnalyzer with custom thresholds
    /// - Parameters:
    ///   - positiveThreshold: Threshold above which sentiment is considered positive (default: 0.25)
    ///   - negativeThreshold: Threshold below which sentiment is considered negative (default: -0.25)
    public init(positiveThreshold: Double = 0.25, negativeThreshold: Double = -0.25) {
        self.positiveThreshold = positiveThreshold
        self.negativeThreshold = negativeThreshold
        
        // In the future, you can load a custom Core ML model like this:
        // if let compiledModelURL = Bundle.main.url(forResource: "FinancialSentimentClassifier", withExtension: "mlmodelc") {
        //     do {
        //         model = try NLModel(contentsOf: compiledModelURL)
        //         logger.info("Successfully loaded custom sentiment model")
        //     } catch {
        //         logger.error("Failed to load custom sentiment model: \(error.localizedDescription)")
        //     }
        // }
    }
    
    // MARK: - Public Methods
    
    /// Analyzes the sentiment of a given text using the Natural Language framework
    /// - Parameter text: The input string to analyze
    /// - Returns: A SentimentResult containing the sentiment classification and confidence score
    public func analyzeSentiment(for text: String) -> SentimentResult {
        // Return cached result if available
        if let cachedResult = cache[text] {
            logger.debug("Using cached sentiment result for text")
            return cachedResult
        }
        
        // Preprocess the text
        let processedText = preprocessText(text)
        
        // If text is empty after preprocessing, return unknown sentiment
        guard !processedText.isEmpty else {
            logger.warning("Empty text after preprocessing")
            return SentimentResult(sentiment: .unknown, score: 0.0, text: text)
        }
        
        // If a custom model is loaded, use it for prediction
        if let model = model {
            logger.debug("Using custom model for sentiment analysis")
            let sentimentString = model.predictedLabel(for: processedText) ?? "Neutral"
            // This assumes the custom model returns one of the Sentiment rawValues
            let result = SentimentResult(
                sentiment: Sentiment(rawValue: sentimentString) ?? .neutral,
                score: 0.0,
                text: text
            )
            cacheResult(result, for: text)
            return result
        }
        
        // Fallback to the built-in NLTagger if no custom model is available
        logger.debug("Using NLTagger for sentiment analysis")
        tagger.string = processedText
        
        // Check if the text is empty
        guard !processedText.isEmpty else {
            return SentimentResult(sentiment: .unknown, score: 0.0, text: text)
        }
        
        let (tag, _) = tagger.tag(at: processedText.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        guard let sentimentScoreString = tag?.rawValue,
              let sentimentScore = Double(sentimentScoreString) else {
            logger.warning("Failed to get sentiment score from NLTagger")
            return SentimentResult(sentiment: .unknown, score: 0.0, text: text)
        }
        
        let sentiment: Sentiment
        if sentimentScore > positiveThreshold {
            sentiment = .positive
        } else if sentimentScore < negativeThreshold {
            sentiment = .negative
        } else {
            sentiment = .neutral
        }
        
        let result = SentimentResult(sentiment: sentiment, score: sentimentScore, text: text)
        cacheResult(result, for: text)
        return result
    }
    
    /// Analyzes sentiment for multiple texts in batch
    /// - Parameter texts: Array of strings to analyze
    /// - Returns: Array of SentimentResult objects
    public func analyzeSentimentBatch(for texts: [String]) -> [SentimentResult] {
        return texts.map { analyzeSentiment(for: $0) }
    }
    
    /// Analyzes sentiment for a collection of news content
    /// - Parameter newsContents: Array of news content strings
    /// - Returns: Overall sentiment result based on all content
    public func analyzeNewsContent(newsContents: [String]) -> SentimentResult {
        // Concatenate all news content to analyze sentiment
        let allNewsText = newsContents.joined(separator: " ")
        
        // If there are no articles with descriptions, return unknown sentiment
        guard !allNewsText.isEmpty else {
            logger.warning("No news content available for sentiment analysis")
            return SentimentResult(sentiment: .unknown, score: 0.0, text: "No news content")
        }
        
        return analyzeSentiment(for: allNewsText)
    }
    
    /// Clears the sentiment analysis cache
    public func clearCache() {
        logger.debug("Clearing sentiment analysis cache")
        cache.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Preprocesses text for better sentiment analysis
    /// - Parameter text: Raw input text
    /// - Returns: Processed text
    private func preprocessText(_ text: String) -> String {
        // Convert to lowercase
        var processedText = text.lowercased()
        
        // Remove URLs
        let urlPattern = "https?://\\S+\\b|www\\.\\S+\\b|\\S+\\.com\\S*"
        processedText = processedText.replacingOccurrences(
            of: urlPattern,
            with: "",
            options: .regularExpression
        )
        
        // Remove extra whitespace
        processedText = processedText.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
    }
    
    /// Caches a sentiment result for future use
    /// - Parameters:
    ///   - result: The sentiment result to cache
    ///   - text: The original text used for analysis
    private func cacheResult(_ result: SentimentResult, for text: String) {
        // Manage cache size
        if cache.count >= maxCacheSize {
            cache.removeValue(forKey: cache.keys.first ?? "")
        }
        
        // Add to cache
        cache[text] = result
    }
}
