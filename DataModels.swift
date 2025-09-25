import Foundation

struct MarketData: Codable, Identifiable, Hashable {
    var id = UUID()
    let symbol: String
    let price: Double
    let volume: Int
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case symbol, price, volume, timestamp
    }
}

struct TradeData: Codable, Identifiable {
    var id = UUID()
    let symbol: String
    let quantity: Int
    let price: Double
    let type: TradeType
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case symbol, quantity, price, type, timestamp
    }
}

enum TradeType: String, Codable {
    case buy, sell
}

struct Portfolio: Codable {
    let holdings: [Holding]
    let cash: Double
}

struct Holding: Codable, Identifiable {
    var id = UUID()
    let symbol: String
    let quantity: Int
    let averagePrice: Double

    enum CodingKeys: String, CodingKey {
        case symbol, quantity, averagePrice
    }
}
