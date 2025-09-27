import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TradingBot")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        // Enable lightweight migration
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveContext() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    func fetchTradingData() -> [TradingData] {
        let request: NSFetchRequest<TradingData> = TradingData.fetchRequest()
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Fetch TradingData failed: \(error)")
            return []
        }
    }

    func addTradingData(symbol: String, price: Double, volume: Int64, timestamp: Date) async throws {
        try await container.performBackgroundTask { context in
            let newData = TradingData(context: context)
            newData.symbol = symbol
            newData.price = price
            newData.volume = volume
            newData.timestamp = timestamp
            try context.save()
        }
    }

    func cacheDataLocally(data: [MarketData]) async throws -> Int {
        var successCount = 0
        for item in data {
            try await addTradingData(symbol: item.symbol, price: item.price, volume: Int64(item.volume), timestamp: item.timestamp)
            successCount += 1
        }
        return successCount
    }

    func saveNewsArticle(_ article: Article) async throws {
        try await container.performBackgroundTask { context in
            let newsEntity = NewsArticle(context: context)
            newsEntity.title = article.title
            newsEntity.descriptionText = article.description
            newsEntity.url = article.url
            // Convert publishedAt string to Date if needed
            let dateFormatter = ISO8601DateFormatter()
            if let publishedAtDate = dateFormatter.date(from: article.publishedAt) {
                newsEntity.publishedAt = publishedAtDate
            } else {
                // Fallback to current date if parsing fails
                newsEntity.publishedAt = Date()
            }
            // New attributes - set to nil for now as Article doesn't have them
            newsEntity.author = nil
            newsEntity.sourceName = nil
            newsEntity.urlToImage = nil
            newsEntity.content = nil
            try context.save()
        }
    }

    func fetchNewsArticles() throws -> [NewsArticle] {
        let request: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        return try container.viewContext.fetch(request)
    }

    func deleteNewsArticle(_ article: NewsArticle) throws {
        container.viewContext.delete(article)
        try saveContext()
    }

    func deleteTradingData(_ data: TradingData) throws {
        container.viewContext.delete(data)
        try saveContext()
    }
}
