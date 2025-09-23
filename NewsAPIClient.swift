import Foundation

class NewsAPIClient {
    private let apiKey = Config.newsAPIKey
    private let baseURL = "https://newsapi.org/v2"

    func fetchIndianMarketNews(completion: @escaping (Result<[Article], Error>) -> Void) {
        let urlString = "\(baseURL)/everything?q=Nifty+India+stock+market&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let newsResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
                completion(.success(newsResponse.articles))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func startRealTimeNewsStreaming(completion: @escaping (Article) -> Void) {
        // Placeholder for real-time streaming
        // In a real implementation, use WebSocket or polling
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            fetchIndianMarketNews { result in
                if let articles = try? result.get() {
                    for article in articles {
                        completion(article)
                    }
                }
            }
        }
    }
}

struct NewsResponse: Codable {
    let articles: [Article]
}

struct Article: Codable {
    let title: String
    let description: String?
    let url: String
    let publishedAt: String
}
