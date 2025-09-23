import Foundation

protocol Agent {
    var name: String { get }
    func makeDecision(marketData: MarketData, news: [Article]) -> String
}

class BaseAgent: Agent {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func makeDecision(marketData: MarketData, news: [Article]) -> String {
        return "Base decision: Hold position"
    }
}
