import Foundation

class MultiAgentReinforcementLearner {
    private var qTable: [String: [Double]] = [:]
    private let learningRate: Double = 0.1
    private let discountFactor: Double = 0.9
    private var explorationRate: Double = 0.2
    
    // Initialize the learner
    init() {
        print("MultiAgentReinforcementLearner initialized")
    }
    
    // Update Q-values based on state, action, reward, and next state
    func learn(state: String, action: Int, reward: Double, nextState: String) {
        // Initialize Q-values for state if they don't exist
        if qTable[state] == nil {
            qTable[state] = Array(repeating: 0.0, count: 3) // 3 actions: buy, sell, hold
        }
        
        // Initialize Q-values for next state if they don't exist
        if qTable[nextState] == nil {
            qTable[nextState] = Array(repeating: 0.0, count: 3)
        }
        
        // Get current Q-value
        let currentQ = qTable[state]![action]
        
        // Get maximum Q-value for next state
        let maxNextQ = qTable[nextState]!.max() ?? 0.0
        
        // Update Q-value using Q-learning formula
        let newQ = currentQ + learningRate * (reward + discountFactor * maxNextQ - currentQ)
        qTable[state]![action] = newQ
        
        // Decay exploration rate
        explorationRate = max(0.01, explorationRate * 0.995)
    }
    
    // Get best action for a given state
    func getBestAction(for state: String) -> Int {
        // Initialize Q-values for state if they don't exist
        if qTable[state] == nil {
            qTable[state] = Array(repeating: 0.0, count: 3)
        }
        
        // Exploration vs exploitation
        if Double.random(in: 0...1) < explorationRate {
            return Int.random(in: 0...2) // Explore
        } else {
            // Find index of maximum Q-value
            let qValues = qTable[state]!
            if let maxIndex = qValues.indices.max(by: { qValues[$0] < qValues[$1] }) {
                return maxIndex
            } else {
                return Int.random(in: 0...2) // Fallback
            }
        }
    }
    
    // Get performance metrics
    func getPerformanceMetrics() -> [String: Double] {
        let avgQValue = qTable.values.flatMap { $0 }.reduce(0.0, +) / Double(max(1, qTable.values.flatMap { $0 }.count))
        let maxQValue = qTable.values.flatMap { $0 }.max() ?? 0.0
        
        return [
            "averageQValue": avgQValue,
            "maxQValue": maxQValue,
            "explorationRate": explorationRate,
            "stateCount": Double(qTable.count)
        ]
    }
    
    // Reset the learner
    func reset() {
        qTable.removeAll()
        explorationRate = 0.2
    }
}
