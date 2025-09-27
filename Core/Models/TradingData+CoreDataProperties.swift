import Foundation
import CoreData

extension TradingData {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TradingData> {
        return NSFetchRequest<TradingData>(entityName: "TradingData")
    }

    @NSManaged public var symbol: String?
    @NSManaged public var price: Double
    @NSManaged public var volume: Int64
    @NSManaged public var timestamp: Date?
}

extension TradingData : Identifiable {
}
