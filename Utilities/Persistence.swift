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

    func saveContext() -> Bool {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                let nserror = error as NSError
                print("Unresolved error saving context: \(nserror), \(nserror.userInfo)")
                return false
            }
        }
        return true
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

    func addTradingData(symbol: String, price: Double, volume: Int64, timestamp: Date) -> Bool {
        let newData = TradingData(context: container.viewContext)
        newData.symbol = symbol
        newData.price = price
        newData.volume = volume
        newData.timestamp = timestamp
        return saveContext()
    }

    func cacheDataLocally(data: [MarketData]) -> Int {
        var successCount = 0
        for item in data {
            if addTradingData(symbol: item.symbol, price: item.price, volume: Int64(item.volume), timestamp: item.timestamp) {
                successCount += 1
            }
        }
        return successCount
    }

    func saveNewsArticle(_ article: Article) -> Bool {
        let context = container.viewContext
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
            print("Failed to parse publishedAt date for article: \(article.title), using current date")
        }
        return saveContext()
    }

    func fetchNewsArticles() -> [NewsArticle] {
        let request: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Fetch news articles failed")
            return []
        }
    }


}
