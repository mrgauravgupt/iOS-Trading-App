import Foundation

class AgentCoordinator {
    private let marketAnalysisAgent = MarketAnalysisAgent()
    private let strategySelectionAgent = StrategySelectionAgent()
    private let riskManagementAgent = RiskManagementAgent()
    private let advancedRiskManager = AdvancedRiskManager()
    
    func coordinateDecision(marketData: MarketData, news: [Article]) -> String {
        let marketDecision = marketAnalysisAgent.makeDecision(marketData: marketData, news: news)
        let strategyDecision = strategySelectionAgent.makeDecision(marketData: marketData, news: news)
        let riskDecision = riskManagementAgent.makeDecision(marketData: marketData, news: news)
        
        // Advanced coordination with negotiation
        let decisions = [marketDecision, strategyDecision, riskDecision]
        let buyVotes = decisions.filter { $0.contains("Buy") }.count
        let sellVotes = decisions.filter { $0.contains("Sell") }.count
        
        if sellVotes > buyVotes {
            return "Final Decision: Sell - Majority consensus"
        } else if buyVotes > sellVotes {
            return "Final Decision: Buy - Majority consensus"
        } else {
            return "Final Decision: Hold - No clear consensus"
        }
    }
    
    func allocateResources(agents: [BaseAgent], resources: Double) -> [BaseAgent: Double] {
        var allocation: [BaseAgent: Double] = [:]
        let equalShare = resources / Double(agents.count)
        
        for agent in agents {
            allocation[agent] = equalShare
        }
        
        return allocation
    }
    
    func resolveConflicts(decisions: [String]) -> String {
        // Simple conflict resolution
        if decisions.contains("Sell") {
            return "Resolved: Sell - Risk priority"
        } else if decisions.allSatisfy({ $0.contains("Buy") }) {
            return "Resolved: Buy - Unanimous"
        } else {
            return "Resolved: Hold - Default"
        }
    }
}
