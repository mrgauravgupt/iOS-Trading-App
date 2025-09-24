import CoreML
import Foundation

/// Manages the machine learning model for trading decisions
class MLModelManager {
    static let shared = MLModelManager()
    private var model: MLModel?
    private var learningRate = 0.01
    private var discountFactor = 0.95
    private var explorationRate = 0.1
    private var qTable: [String: [Double]] = [:] // Q-table for reinforcement learning

    /// Initialize the MLModelManager and load the model
    init() {
        loadModel()
    }

    /// Load the machine learning model
    private func loadModel() {
        // In a real implementation, load a trained Core ML model
        // For now, this is a placeholder
        print("ML Model loaded")
    }

    /// Make a prediction based on input data
    /// - Parameter input: Array of doubles representing the state
    /// - Returns: Predicted value
    func makePrediction(input: [Double]) -> Double {
        // Use reinforcement learning to make predictions
        let state = stateToString(input)
        if let qValues = qTable[state] {
            return qValues.max() ?? 0.0
        } else {
            // Initialize Q-values for new state
            qTable[state] = [0.0, 0.0, 0.0] // Buy, Sell, Hold
            return 0.0
        }
    }

    /// Train the model with provided data
    /// - Parameters:
    ///   - data: Training data
    ///   - labels: Corresponding labels
    func trainModel(data: [[Double]], labels: [Double]) {
        // Placeholder for on-device training
        print("Training model with \(data.count) samples")
    }

    /// Save the current model
    func saveModel() {
        // Placeholder for model versioning
        print("Model saved")
    }

    // MARK: - Reinforcement Learning Methods

    /// Update Q-value based on action and reward
    /// - Parameters:
    ///   - state: Current state
    ///   - action: Action taken
    ///   - reward: Reward received
    ///   - nextState: Next state
    func updateQValue(state: [Double], action: Int, reward: Double, nextState: [Double]) {
        let stateKey = stateToString(state)
        let nextStateKey = stateToString(nextState)

        let currentQ = qTable[stateKey]?[action] ?? 0.0
        let maxNextQ = qTable[nextStateKey]?.max() ?? 0.0

        let newQ = currentQ + learningRate * (reward + discountFactor * maxNextQ - currentQ)
        qTable[stateKey]?[action] = newQ
    }

    /// Get the best action for a given state
    /// - Parameter state: Current state
    /// - Returns: Best action index (0=Buy, 1=Sell, 2=Hold)
    func getBestAction(state: [Double]) -> Int {
        let stateKey = stateToString(state)
        if let qValues = qTable[stateKey] {
            // Exploration vs exploitation
            if Double.random(in: 0...1) < explorationRate {
                return Int.random(in: 0...2) // Explore
            } else {
                // Find index of maximum Q-value
                guard let maxValue = qValues.max(), 
                      let index = qValues.firstIndex(of: maxValue) else {
                    return Int.random(in: 0...2) // Fallback
                }
                return index // Exploit
            }
        } else {
            // Initialize Q-values for new state
            qTable[stateKey] = [0.0, 0.0, 0.0]
            return Int.random(in: 0...2)
        }
    }

    /// Learn from a trade
    /// - Parameters:
    ///   - state: State before trade
    ///   - action: Action taken
    ///   - reward: Reward received
    ///   - nextState: State after trade
    func learnFromTrade(state: [Double], action: Int, reward: Double, nextState: [Double]) {
        updateQValue(state: state, action: action, reward: reward, nextState: nextState)
        // Decay exploration rate
        explorationRate = max(0.01, explorationRate * 0.995)
    }

    /// Convert state array to string for Q-table key
    /// - Parameter state: State array
    /// - Returns: String representation
    private func stateToString(_ state: [Double]) -> String {
        return state.map { String(format: "%.2f", $0) }.joined(separator: ",")
    }

    /// Get model performance as average Q-value
    /// - Returns: Average Q-value
    func getModelPerformance() -> Double {
        // Handle empty Q-table
        guard !qTable.isEmpty else { return 0.0 }
        
        // Calculate average Q-value as a measure of model performance
        let allQValues = qTable.values.flatMap { $0 }
        guard !allQValues.isEmpty else { return 0.0 }
        
        return allQValues.reduce(0, +) / Double(allQValues.count)
    }
}