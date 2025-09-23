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
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func fetchTradingData() -> [TradingData] {
        let request: NSFetchRequest<TradingData> = TradingData.fetchRequest()
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Fetch failed")
            return []
        }
    }

    func addTradingData(symbol: String, price: Double, volume: Int64, timestamp: Date) {
        let newData = TradingData(context: container.viewContext)
        newData.symbol = symbol
        newData.price = price
        newData.volume = volume
        newData.timestamp = timestamp
        saveContext()
    }

    func cacheDataLocally(data: [MarketData]) {
        for item in data {
            addTradingData(symbol: item.symbol, price: item.price, volume: item.volume, timestamp: item.timestamp)
        }
    }

    func saveNewsArticle(_ article: Article) {
        let context = container.viewContext
        let newsEntity = NewsArticle(context: context)
        newsEntity.title = article.title
        newsEntity.descriptionText = article.description
        newsEntity.url = article.url
        newsEntity.publishedAt = article.publishedAt
        saveContext()
    }
}
