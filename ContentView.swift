import SwiftUI

struct ContentView: View {
    @State private var articles: [Article] = []
    @State private var isLoading = false
    @State private var marketData: String = "No data"
    private let sentimentAnalyzer = SentimentAnalyzer()
    private let webSocketManager = WebSocketManager()

    var body: some View {
        TabView {
            // Dashboard Tab
            VStack {
                Text("iOS Trading Bot Dashboard")
                    .font(.largeTitle)
                    .padding()
                
                // Market Overview
                Text("Market Overview")
                    .font(.title)
                    .padding()
                
                Text("Real-time Market Data: \(marketData)")
                    .font(.body)
                    .padding()
                
                // News Feed Widget
                if isLoading {
                    ProgressView("Loading news...")
                } else {
                    List(articles) { article in
                    VStack(alignment: .leading) {
                        Text(article.title)
                            .font(.headline)
                        if let description = article.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            let sentiment = sentimentAnalyzer.analyzeSentiment(for: description)
                            Text("Sentiment: \(sentiment)")
                                .font(.caption)
                                .foregroundColor(sentiment == "Positive" ? .green : sentiment == "Negative" ? .red : .blue)
                        } else {
                            Text("No description available")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Text(article.publishedAt)
                            .font(.caption)
                    }
                    }
                }
                .onAppear {
                    loadNews()
                    webSocketManager.onMessageReceived = { message in
                        DispatchQueue.main.async {
                            self.marketData = message
                        }
                    }
                    // Connect to Zerodha WebSocket with a sample token (replace with actual token)
                    webSocketManager.connectToZerodhaWebSocket(token: Config.zerodhaAPIKey)
                }
                .onDisappear {
                    webSocketManager.disconnect()
                }
                
                Spacer()
            }
            .tabItem {
                Image(systemName: "house")
                Text("Dashboard")
            }
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
    
    private func loadNews() {
        isLoading = true
        NewsAPIClient().fetchIndianMarketNews { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedArticles):
                    self.articles = fetchedArticles
                case .failure(let error):
                    print("Error fetching news: \(error)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
