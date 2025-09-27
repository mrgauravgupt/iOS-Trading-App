import Foundation

class AgentPerformanceTracker {
    private var agentPerformance: [String: [Double]] = [:]
    private var agentRewards: [String: [Double]] = [:]
    private var agentDecisions: [String: [String]] = [:]
    
    // Initialize the tracker
    init() {
        print("AgentPerformanceTracker initialized")
    }
    
    // Record agent performance
    func recordPerformance(agentName: String, performance: Double) {
        if agentPerformance[agentName] == nil {
            agentPerformance[agentName] = []
        }
        agentPerformance[agentName]?.append(performance)
        
        // Keep only the last 100 performance records
        if let performances = agentPerformance[agentName], performances.count > 100 {
            agentPerformance[agentName] = Array(performances.suffix(100))
        }
    }
    
    // Record agent reward
    func recordReward(agentName: String, reward: Double) {
        if agentRewards[agentName] == nil {
            agentRewards[agentName] = []
        }
        agentRewards[agentName]?.append(reward)
        
        // Keep only the last 100 reward records
        if let rewards = agentRewards[agentName], rewards.count > 100 {
            agentRewards[agentName] = Array(rewards.suffix(100))
        }
    }
    
    // Record agent decision
    func recordDecision(agentName: String, decision: String) {
        if agentDecisions[agentName] == nil {
            agentDecisions[agentName] = []
        }
        agentDecisions[agentName]?.append(decision)
        
        // Keep only the last 100 decision records
        if let decisions = agentDecisions[agentName], decisions.count > 100 {
            agentDecisions[agentName] = Array(decisions.suffix(100))
        }
    }
    
    // Get average performance for an agent
    func getAveragePerformance(for agentName: String) -> Double {
        guard let performances = agentPerformance[agentName], !performances.isEmpty else {
            return 0.0
        }
        return performances.reduce(0.0, +) / Double(performances.count)
    }
    
    // Get average reward for an agent
    func getAverageReward(for agentName: String) -> Double {
        guard let rewards = agentRewards[agentName], !rewards.isEmpty else {
            return 0.0
        }
        return rewards.reduce(0.0, +) / Double(rewards.count)
    }
    
    // Get performance trend for an agent
    func getPerformanceTrend(for agentName: String) -> Double {
        guard let performances = agentPerformance[agentName], performances.count >= 10 else {
            return 0.0
        }
        
        let recentPerformances = Array(performances.suffix(10))
        let firstHalf = recentPerformances.prefix(5)
        let secondHalf = recentPerformances.suffix(5)
        
        let firstHalfAvg = firstHalf.reduce(0.0, +) / Double(firstHalf.count)
        let secondHalfAvg = secondHalf.reduce(0.0, +) / Double(secondHalf.count)
        
        return secondHalfAvg - firstHalfAvg
    }
    
    // Get all agent names
    func getAllAgentNames() -> [String] {
        return Array(agentPerformance.keys)
    }
    
    // Get performance summary for all agents
    func getPerformanceSummary() -> [String: [String: Double]] {
        var summary: [String: [String: Double]] = [:]
        
        for agentName in getAllAgentNames() {
            summary[agentName] = [
                "averagePerformance": getAveragePerformance(for: agentName),
                "averageReward": getAverageReward(for: agentName),
                "performanceTrend": getPerformanceTrend(for: agentName)
            ]
        }
        
        return summary
    }
    
    // Reset the tracker
    func reset() {
        agentPerformance.removeAll()
        agentRewards.removeAll()
        agentDecisions.removeAll()
    }
}
