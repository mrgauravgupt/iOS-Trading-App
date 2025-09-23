import Foundation
import CoreData

@objc(TradingData)
public class TradingData: NSManagedObject {
}

extension TradingData {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TradingData> {
        return NSFetchRequest<TradingData>(entityName: "TradingData")
    }

    @NSManaged public var symbol: String?
    @NSManaged public var price: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var volume: Int64
}

extension TradingData : Identifiable {
}