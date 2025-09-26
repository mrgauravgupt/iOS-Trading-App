import Foundation
import SwiftUI

protocol Agent {
    var name: String { get }
    func makeDecision(marketData: MarketData, news: [Article]) -> String
}

class BaseAgent: Agent, Hashable, ObservableObject {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func makeDecision(marketData: MarketData, news: [Article]) -> String {
        return "Base decision: Hold position"
    }
    
    static func == (lhs: BaseAgent, rhs: BaseAgent) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
