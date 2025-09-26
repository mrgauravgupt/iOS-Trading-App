import Foundation

class AgentCoordinator {
    private let marketAnalysisAgent = MarketAnalysisAgent(name: "MarketAnalysis")
    private let strategySelectionAgent = StrategySelectionAgent(name: "StrategySelection")
    private let riskManagementAgent = RiskManagementAgent(name: "RiskManagement")
    private let advancedRiskManager = AdvancedRiskManager()

    // Multi-agent reinforcement learning components
    private var reinforcementLearner = MultiAgentReinforcementLearner()
    private var agentPerformanceTracker = AgentPerformanceTracker()
    var negotiationProtocol = AgentNegotiationProtocol()
    var collaborativeLearning = CollaborativeLearningSystem()
    
    func coordinateDecision(marketData: MarketData, news: [Article]) -> String {
        let marketDecision = marketAnalysisAgent.makeDecision(marketData: marketData, news: news)
        let strategyDecision = strategySelectionAgent.makeDecision(marketData: marketData, news: news)
        let riskDecision = riskManagementAgent.makeDecision(marketData: marketData, news: news)

        // Get agent states for RL
        let agentStates = getAgentStates(marketData: marketData, news: news)

        // Use reinforcement learning for decision making
        let rlDecision = reinforcementLearner.makeDecision(states: agentStates)

        // Advanced coordination with negotiation and RL
        let decisions = [marketDecision, strategyDecision, riskDecision]
        let negotiatedDecision = negotiationProtocol.negotiate(decisions: decisions, rlInput: rlDecision)

        let buyVotes = decisions.filter { $0.contains("Buy") }.count
        let sellVotes = decisions.filter { $0.contains("Sell") }.count

        // Combine traditional voting with RL insights
        let finalDecision = collaborativeLearning.finalizeDecision(
            traditionalVotes: (buyVotes, sellVotes),
            rlDecision: rlDecision,
            negotiatedDecision: negotiatedDecision
        )

        // Track performance for learning
        agentPerformanceTracker.recordDecision(
            marketData: marketData,
            decisions: decisions,
            finalDecision: finalDecision
        )

        return finalDecision
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
        // Enhanced conflict resolution with RL insights
        let rlInsight = reinforcementLearner.getConflictResolutionInsight(decisions: decisions)

        if decisions.contains("Sell") && rlInsight.contains("risk") {
            return "Resolved: Sell - Risk priority with RL confirmation"
        } else if decisions.allSatisfy({ $0.contains("Buy") }) {
            return "Resolved: Buy - Unanimous with RL validation"
        } else {
            return "Resolved: \(rlInsight) - RL-guided decision"
        }
    }

    // MARK: - Helper Methods

    private func getAgentStates(marketData: MarketData, news: [Article]) -> [String: [Double]] {
        // Extract state vectors for each agent
        let marketState = extractMarketState(marketData: marketData)
        let newsState = extractNewsState(news: news)
        let riskState = extractRiskState(marketData: marketData)

        return [
            "market": marketState,
            "news": newsState,
            "risk": riskState
        ]
    }

    private func extractMarketState(marketData: MarketData) -> [Double] {
        // Simplified market state extraction
        return [marketData.price, Double(marketData.volume)]
    }

    private func extractNewsState(news: [Article]) -> [Double] {
        // Simplified news sentiment analysis - placeholder for now
        // In a real implementation, this would analyze article titles/descriptions
        let sentimentScore = Double.random(in: -1.0...1.0) // Placeholder random sentiment
        return [sentimentScore, Double(news.count)]
    }

    private func extractRiskState(marketData: MarketData) -> [Double] {
        // Simplified risk metrics
        return [marketData.price * 0.02, Double(marketData.volume) * 0.1] // volatility proxy, volume risk
    }

    // MARK: - Multi-Agent Reinforcement Learning Components

    /// Multi-agent reinforcement learning system
    class MultiAgentReinforcementLearner {
        private var qTables: [String: [String: [Double]]] = [:] // Agent -> State -> [Q-values for Buy, Sell, Hold]
        private var learningRate = 0.1
        private var discountFactor = 0.95
        private var explorationRate = 0.2

        func makeDecision(states: [String: [Double]]) -> String {
            var decisions: [String] = []

            for (agentName, state) in states {
                let stateKey = stateToString(state)
                let decision = getBestAction(for: agentName, state: stateKey)
                decisions.append("\(agentName): \(decision)")
            }

            // Aggregate decisions
            return aggregateDecisions(decisions)
        }

        private func getBestAction(for agent: String, state: String) -> String {
            if let qValues = qTables[agent]?[state] {
                if Double.random(in: 0...1) < explorationRate {
                    return ["Buy", "Sell", "Hold"].randomElement()!
                }
                // Find action with highest Q-value
                let actions = ["Buy", "Sell", "Hold"]
                var bestAction = "Hold"
                var bestValue = -Double.greatestFiniteMagnitude

                for (index, value) in qValues.enumerated() {
                    if value > bestValue {
                        bestValue = value
                        bestAction = actions[index]
                    }
                }
                return bestAction
            } else {
                // Initialize Q-values
                qTables[agent] = [state: [0.0, 0.0, 0.0]] // Buy, Sell, Hold
                return ["Buy", "Sell", "Hold"].randomElement()!
            }
        }

        private func aggregateDecisions(_ decisions: [String]) -> String {
            let buyCount = decisions.filter { $0.contains("Buy") }.count
            let sellCount = decisions.filter { $0.contains("Sell") }.count
            let holdCount = decisions.filter { $0.contains("Hold") }.count

            if sellCount > buyCount && sellCount > holdCount {
                return "Sell"
            } else if buyCount > sellCount && buyCount > holdCount {
                return "Buy"
            } else {
                return "Hold"
            }
        }

        func learn(from states: [String: [Double]], decisions: [String], reward: Double) {
            for (agentName, state) in states {
                let stateKey = stateToString(state)
                let decision = decisions.first { $0.contains(agentName) } ?? ""
                let actionIndex = getActionIndex(decision)

                updateQValue(agent: agentName, state: stateKey, action: actionIndex, reward: reward)
            }
        }

        private func getActionIndex(_ decision: String) -> Int {
            if decision.contains("Buy") { return 0 }
            if decision.contains("Sell") { return 1 }
            return 2 // Hold
        }

        private func updateQValue(agent: String, state: String, action: Int, reward: Double) {
            if qTables[agent] == nil {
                qTables[agent] = [:]
            }
            if qTables[agent]![state] == nil {
                qTables[agent]![state] = [0.0, 0.0, 0.0]
            }

            let currentQ = qTables[agent]![state]![action]
            let maxNextQ = qTables[agent]![state]!.max() ?? 0.0
            let newQ = currentQ + learningRate * (reward + discountFactor * maxNextQ - currentQ)

            qTables[agent]![state]![action] = newQ
        }

        func getConflictResolutionInsight(decisions: [String]) -> String {
            // Provide RL-based insight for conflict resolution
            let consensusLevel = calculateConsensus(decisions)
            if consensusLevel < 0.5 {
                return "Hold - High conflict, wait for clearer signals"
            } else {
                return "Proceed - RL indicates acceptable consensus"
            }
        }

        private func calculateConsensus(_ decisions: [String]) -> Double {
            let buyCount = decisions.filter { $0.contains("Buy") }.count
            let sellCount = decisions.filter { $0.contains("Sell") }.count
            let maxAgreement = max(buyCount, sellCount, decisions.count - buyCount - sellCount)
            return Double(maxAgreement) / Double(decisions.count)
        }

        private func stateToString(_ state: [Double]) -> String {
            return state.map { String(format: "%.2f", $0) }.joined(separator: ",")
        }
    }

    /// Tracks agent performance for learning
    class AgentPerformanceTracker {
        private var performanceHistory: [String: [(decision: String, outcome: Double, timestamp: Date)]] = [:]

        func recordDecision(marketData: MarketData, decisions: [String], finalDecision: String) {
            let timestamp = Date()

            for decision in decisions {
                let agentName = decision.components(separatedBy: ":").first ?? "Unknown"
                if performanceHistory[agentName] == nil {
                    performanceHistory[agentName] = []
                }

                // Store decision with placeholder outcome (to be updated later)
                performanceHistory[agentName]?.append((decision: decision, outcome: 0.0, timestamp: timestamp))
            }
        }

        func updateOutcome(agentName: String, timestamp: Date, actualOutcome: Double) {
            if let history = performanceHistory[agentName] {
                if let index = history.firstIndex(where: { $0.timestamp == timestamp }) {
                    performanceHistory[agentName]?[index].outcome = actualOutcome
                }
            }
        }

        func getAgentPerformance(agentName: String) -> Double {
            guard let history = performanceHistory[agentName], !history.isEmpty else { return 0.5 }

            let recentHistory = Array(history.suffix(10))
            let avgOutcome = recentHistory.map { $0.outcome }.average()
            return avgOutcome
        }
    }

    /// Handles negotiation between agents
    class AgentNegotiationProtocol {
        private var negotiationHistory: [String: NegotiationOutcome] = [:]
        private var trustScores: [String: Double] = [:]

        struct NegotiationOutcome {
            let proposal: String
            let acceptance: Bool
            let compromise: String?
            let timestamp: Date
        }

        func negotiate(decisions: [String], rlInput: String) -> String {
            // Advanced negotiation with trust-based weighting
            let agentDecisions = parseAgentDecisions(decisions)
            let weightedDecisions = applyTrustWeights(agentDecisions)

            // Use RL input as mediator
            let mediatedDecision = mediateWithRL(weightedDecisions, rlInput: rlInput)

            // Record negotiation outcome
            recordNegotiation(decisions: decisions, outcome: mediatedDecision)

            return mediatedDecision
        }

        private func parseAgentDecisions(_ decisions: [String]) -> [String: String] {
            var parsed: [String: String] = [:]
            for decision in decisions {
                let components = decision.components(separatedBy: ": ")
                if components.count >= 2 {
                    parsed[components[0]] = components[1]
                }
            }
            return parsed
        }

        private func applyTrustWeights(_ decisions: [String: String]) -> [String: Double] {
            var weighted: [String: Double] = [:]

            for (agent, decision) in decisions {
                let trust = trustScores[agent] ?? 1.0
                let baseWeight = decision == "Buy" ? 1.0 : decision == "Sell" ? -1.0 : 0.0
                weighted[decision] = (weighted[decision] ?? 0.0) + baseWeight * trust
            }

            return weighted
        }

        private func mediateWithRL(_ weightedDecisions: [String: Double], rlInput: String) -> String {
            // RL acts as mediator, considering agent consensus and trust
            let totalWeight = weightedDecisions.values.reduce(0, +)

            if abs(totalWeight) < 0.5 {
                // Low consensus, follow RL guidance
                return rlInput
            } else if totalWeight > 0.5 {
                // Strong buy consensus
                return rlInput == "Sell" ? "Hold - Consensus vs RL conflict" : "Buy - Consensus supported"
            } else {
                // Strong sell consensus
                return rlInput == "Buy" ? "Hold - Consensus vs RL conflict" : "Sell - Consensus supported"
            }
        }

        private func recordNegotiation(decisions: [String], outcome: String) {
            let key = decisions.joined(separator: "|")
            let negotiationOutcome = NegotiationOutcome(
                proposal: decisions.joined(separator: ", "),
                acceptance: true, // Assume acceptance for now
                compromise: outcome.contains("-") ? outcome : nil,
                timestamp: Date()
            )
            negotiationHistory[key] = negotiationOutcome

            // Update trust scores based on outcome consistency
            updateTrustScores(decisions: decisions, outcome: outcome)
        }

        private func updateTrustScores(decisions: [String], outcome: String) {
            let outcomeAction = outcome.components(separatedBy: " - ").first ?? outcome

            for decision in decisions {
                let components = decision.components(separatedBy: ": ")
                if components.count >= 2 {
                    let agent = components[0]
                    let agentAction = components[1]

                    // Increase trust if agent decision aligned with final outcome
                    if agentAction == outcomeAction {
                        trustScores[agent] = min(2.0, (trustScores[agent] ?? 1.0) + 0.1)
                    } else {
                        trustScores[agent] = max(0.1, (trustScores[agent] ?? 1.0) - 0.05)
                    }
                }
            }
        }

        func getNegotiationInsights() -> [String: Any] {
            let avgTrustScore = trustScores.isEmpty ? 0.0 : trustScores.values.reduce(0, +) / Double(trustScores.count)
            return [
                "totalNegotiations": negotiationHistory.count,
                "averageTrustScore": avgTrustScore,
                "compromiseRate": Double(negotiationHistory.values.filter { $0.compromise != nil }.count) / Double(max(1, negotiationHistory.count))
            ]
        }
    }

    /// Collaborative learning system
    class CollaborativeLearningSystem {
        private var learningHistory: [CollaborativeDecision] = []
        private var adaptiveWeights: [String: Double] = ["traditional": 0.4, "rl": 0.4, "negotiation": 0.2]

        struct CollaborativeDecision {
            let traditionalVotes: (buy: Int, sell: Int)
            let rlDecision: String
            let negotiatedDecision: String
            let finalDecision: String
            let outcome: Double // Profit/loss from the decision
            let timestamp: Date
            let marketConditions: [String: Double]
        }

        func finalizeDecision(traditionalVotes: (buy: Int, sell: Int), rlDecision: String, negotiatedDecision: String) -> String {
            // Use adaptive weights based on historical performance
            let weights = getAdaptiveWeights()

            var scores = ["Buy": 0.0, "Sell": 0.0, "Hold": 0.0]

            // Traditional voting score
            let totalVotes = Double(traditionalVotes.buy + traditionalVotes.sell + 1)
            scores["Buy"]! += weights["traditional"]! * Double(traditionalVotes.buy) / totalVotes
            scores["Sell"]! += weights["traditional"]! * Double(traditionalVotes.sell) / totalVotes
            scores["Hold"]! += weights["traditional"]! * 0.5 // Neutral for hold

            // RL decision score
            scores[rlDecision]! += weights["rl"]!

            // Negotiated decision score
            scores[negotiatedDecision.components(separatedBy: " - ").first ?? negotiatedDecision]! += weights["negotiation"]!

            // Return decision with highest score
            let finalDecision = scores.max { $0.value < $1.value }?.key ?? "Hold"

            // Record decision for learning
            recordCollaborativeDecision(
                traditionalVotes: traditionalVotes,
                rlDecision: rlDecision,
                negotiatedDecision: negotiatedDecision,
                finalDecision: finalDecision
            )

            return finalDecision
        }

        private func getAdaptiveWeights() -> [String: Double] {
            guard learningHistory.count >= 10 else { return adaptiveWeights }

            // Analyze recent performance to adjust weights
            let recentDecisions = Array(learningHistory.suffix(20))

            for (source, _) in adaptiveWeights {
                let sourceDecisions = recentDecisions.filter { decision in
                    switch source {
                    case "traditional":
                        return decision.finalDecision == getTraditionalDecision(decision.traditionalVotes)
                    case "rl":
                        return decision.finalDecision == decision.rlDecision
                    case "negotiation":
                        return decision.finalDecision == decision.negotiatedDecision.components(separatedBy: " - ").first
                    default:
                        return false
                    }
                }

                if !sourceDecisions.isEmpty {
                    let avgOutcome = sourceDecisions.map { $0.outcome }.average()
                    // Adjust weight based on performance (reward good performance)
                    let adjustment = (avgOutcome - 0.0) * 0.05 // Small adjustments
                    adaptiveWeights[source] = max(0.1, min(0.6, adaptiveWeights[source]! + adjustment))
                }
            }

            // Normalize weights
            let totalWeight = adaptiveWeights.values.reduce(0, +)
            for key in adaptiveWeights.keys {
                adaptiveWeights[key] = adaptiveWeights[key]! / totalWeight
            }

            return adaptiveWeights
        }

        private func getTraditionalDecision(_ votes: (buy: Int, sell: Int)) -> String {
            if votes.buy > votes.sell { return "Buy" }
            if votes.sell > votes.buy { return "Sell" }
            return "Hold"
        }

        private func recordCollaborativeDecision(traditionalVotes: (buy: Int, sell: Int), rlDecision: String, negotiatedDecision: String, finalDecision: String) {
            let decision = CollaborativeDecision(
                traditionalVotes: traditionalVotes,
                rlDecision: rlDecision,
                negotiatedDecision: negotiatedDecision,
                finalDecision: finalDecision,
                outcome: 0.0, // To be updated when outcome is known
                timestamp: Date(),
                marketConditions: [:] // Would be populated with current market data
            )
            learningHistory.append(decision)

            // Keep only recent history
            if learningHistory.count > 100 {
                learningHistory.removeFirst()
            }
        }

        func updateDecisionOutcome(timestamp: Date, outcome: Double) {
            if let index = learningHistory.firstIndex(where: { $0.timestamp == timestamp }) {
                learningHistory[index] = CollaborativeDecision(
                    traditionalVotes: learningHistory[index].traditionalVotes,
                    rlDecision: learningHistory[index].rlDecision,
                    negotiatedDecision: learningHistory[index].negotiatedDecision,
                    finalDecision: learningHistory[index].finalDecision,
                    outcome: outcome,
                    timestamp: learningHistory[index].timestamp,
                    marketConditions: learningHistory[index].marketConditions
                )
            }
        }

        func getLearningInsights() -> [String: Any] {
            guard !learningHistory.isEmpty else { return [:] }

            let profitableDecisions = learningHistory.filter { $0.outcome > 0 }
            let avgOutcome = learningHistory.map { $0.outcome }.average()

            return [
                "totalDecisions": learningHistory.count,
                "profitableRatio": Double(profitableDecisions.count) / Double(learningHistory.count),
                "averageOutcome": avgOutcome,
                "adaptiveWeights": adaptiveWeights,
                "learningTrend": calculateLearningTrend()
            ]
        }

        private func calculateLearningTrend() -> Double {
            guard learningHistory.count >= 20 else { return 0.0 }

            let firstHalf = Array(learningHistory.prefix(learningHistory.count / 2))
            let secondHalf = Array(learningHistory.suffix(learningHistory.count / 2))

            let firstHalfAvg = firstHalf.map { $0.outcome }.average()
            let secondHalfAvg = secondHalf.map { $0.outcome }.average()

            return secondHalfAvg - firstHalfAvg // Positive means improving
        }
    }
}
