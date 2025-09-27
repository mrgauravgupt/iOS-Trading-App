import Foundation

class AgentNegotiationProtocol {
    private var agentWeights: [String: Double] = [:]
    private var agentConfidence: [String: Double] = [:]
    private var negotiationHistory: [[String: Any]] = []
    
    // Initialize the protocol
    init() {
        print("AgentNegotiationProtocol initialized")
        
        // Set default weights
        agentWeights = [
            "MarketAnalysis": 0.4,
            "StrategySelection": 0.3,
            "RiskManagement": 0.3
        ]
    }
    
    // Register an agent with the protocol
    func registerAgent(name: String, initialWeight: Double = 0.33) {
        agentWeights[name] = initialWeight
        agentConfidence[name] = 0.5 // Start with neutral confidence
    }
    
    // Update agent weight based on performance
    func updateAgentWeight(name: String, performance: Double) {
        guard var weight = agentWeights[name] else { return }
        
        // Adjust weight based on performance (between -1 and 1)
        let adjustment = performance * 0.05 // Small adjustment
        weight = max(0.1, min(0.7, weight + adjustment)) // Keep between 0.1 and 0.7
        
        agentWeights[name] = weight
        
        // Normalize weights to ensure they sum to 1.0
        normalizeWeights()
    }
    
    // Update agent confidence
    func updateAgentConfidence(name: String, confidence: Double) {
        agentConfidence[name] = max(0.0, min(1.0, confidence))
    }
    
    // Normalize weights to ensure they sum to 1.0
    private func normalizeWeights() {
        let totalWeight = agentWeights.values.reduce(0.0, +)
        
        if totalWeight > 0 {
            for (name, weight) in agentWeights {
                agentWeights[name] = weight / totalWeight
            }
        } else {
            // If total weight is 0, set equal weights
            let equalWeight = 1.0 / Double(agentWeights.count)
            for name in agentWeights.keys {
                agentWeights[name] = equalWeight
            }
        }
    }
    
    // Get the weight for an agent
    func getAgentWeight(name: String) -> Double {
        return agentWeights[name] ?? 0.0
    }
    
    // Get the confidence for an agent
    func getAgentConfidence(name: String) -> Double {
        return agentConfidence[name] ?? 0.5
    }
    
    // Negotiate a decision between agents
    func negotiateDecision(decisions: [String: String], confidences: [String: Double]? = nil) -> String {
        // Record this negotiation
        var negotiationRecord: [String: Any] = [
            "timestamp": Date(),
            "decisions": decisions
        ]
        
        // Update confidences if provided
        if let confidences = confidences {
            for (name, confidence) in confidences {
                agentConfidence[name] = confidence
            }
            negotiationRecord["confidences"] = confidences
        }
        
        // Calculate weighted decision
        var buyScore = 0.0
        var sellScore = 0.0
        var holdScore = 0.0
        
        for (agentName, decision) in decisions {
            let weight = getAgentWeight(name: agentName)
            let confidence = getAgentConfidence(name: agentName)
            let weightedConfidence = weight * confidence
            
            if decision.lowercased().contains("buy") {
                buyScore += weightedConfidence
            } else if decision.lowercased().contains("sell") {
                sellScore += weightedConfidence
            } else {
                holdScore += weightedConfidence
            }
        }
        
        // Determine final decision
        let finalDecision: String
        if buyScore > sellScore && buyScore > holdScore {
            finalDecision = "Negotiated Decision: Buy"
        } else if sellScore > buyScore && sellScore > holdScore {
            finalDecision = "Negotiated Decision: Sell"
        } else {
            finalDecision = "Negotiated Decision: Hold"
        }
        
        // Record the final decision
        negotiationRecord["finalDecision"] = finalDecision
        negotiationRecord["buyScore"] = buyScore
        negotiationRecord["sellScore"] = sellScore
        negotiationRecord["holdScore"] = holdScore
        
        negotiationHistory.append(negotiationRecord)
        
        // Keep history manageable
        if negotiationHistory.count > 100 {
            negotiationHistory = Array(negotiationHistory.suffix(100))
        }
        
        return finalDecision
    }
    
    // Get negotiation history
    func getNegotiationHistory() -> [[String: Any]] {
        return negotiationHistory
    }
    
    // Reset the protocol
    func reset() {
        // Reset to default weights
        agentWeights = [
            "MarketAnalysis": 0.4,
            "StrategySelection": 0.3,
            "RiskManagement": 0.3
        ]
        
        // Reset confidences
        for name in agentConfidence.keys {
            agentConfidence[name] = 0.5
        }
        
        // Clear history
        negotiationHistory.removeAll()
    }
}
