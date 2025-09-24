import Foundation

/// Client for fetching market news from NewsAPI
class NewsAPIClient {
    private var apiKey: String {
        // Prefer Keychain value if available
        KeychainHelper.shared.read("NewsAPIKey") ?? Config.newsAPIKey
    }
    private let baseURL = "https://newsapi.org/v2"

    /// Fetch Indian market news
    /// - Parameter completion: Completion handler with result
    func fetchIndianMarketNews(completion: @escaping (Result<[Article], Error>) -> Void) {
        // Validate API key
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "Missing API Key", code: 401, userInfo: [NSLocalizedDescriptionKey: "NewsAPI key is missing"])))
            return
        }
        
        let urlString = "\(baseURL)/everything?q=Nifty+India+stock+market&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle network error
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Invalid Response", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            
            // Validate data
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Parse JSON
            do {
                let newsResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
                completion(.success(newsResponse.articles))
            } catch {
                completion(.failure(NSError(domain: "Parsing Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse news data: \(error.localizedDescription)"])))
            }
        }.resume()
    }

    /// Start real-time news streaming
    /// - Parameter completion: Handler for new articles
    func startRealTimeNewsStreaming(completion: @escaping (Article) -> Void) {
        // Placeholder for real-time streaming
        // In a real implementation, use WebSocket or polling
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.fetchIndianMarketNews { result in
                switch result {
                case .success(let articles):
                    for article in articles {
                        completion(article)
                    }
                case .failure(let error):
                    print("Error fetching news: \(error)")
                }
            }
        }
    }
}

/// Response structure from NewsAPI
struct NewsResponse: Codable {
    let articles: [Article]
}

/// News article structure
struct Article: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let url: String
    let publishedAt: String
}