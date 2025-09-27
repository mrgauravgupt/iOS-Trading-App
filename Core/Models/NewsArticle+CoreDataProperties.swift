import Foundation
import CoreData

extension NewsArticle {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsArticle> {
        return NSFetchRequest<NewsArticle>(entityName: "NewsArticle")
    }

    @NSManaged public var title: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var url: String?
    @NSManaged public var publishedAt: Date?
    @NSManaged public var author: String?
    @NSManaged public var sourceName: String?
    @NSManaged public var urlToImage: String?
    @NSManaged public var content: String?
}

extension NewsArticle : Identifiable {
}
