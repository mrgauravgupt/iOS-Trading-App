import Foundation

struct MarketData: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let price: Double
    let timestamp: Date
}

struct Trade: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let quantity: Int
    let price: Double
    let type: TradeType
    let timestamp: Date
}

enum TradeType: String, Codable {
    case buy, sell
}

struct Portfolio: Codable {
    let holdings: [Holding]
    let cash: Double
}

struct Holding: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let quantity: Int
    let averagePrice: Double
}
