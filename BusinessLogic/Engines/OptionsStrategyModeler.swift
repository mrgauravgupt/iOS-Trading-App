import Foundation

// MARK: - Options Strategy Modeler

class OptionsStrategyModeler {
    static let shared = OptionsStrategyModeler()

    private let greeksCalculator = OptionsGreeksCalculator.shared

    // MARK: - Strategy Modeling

    /// Model a complete options strategy
    func modelStrategy(_ strategy: OptionsStrategy, underlyingPrice: Double) -> StrategyModel {
        let legs = strategy.legs.map { modelLeg($0, underlyingPrice: underlyingPrice) }
        let netPremium = calculateNetPremium(legs: legs)
        let payoffProfile = calculatePayoffProfile(legs: legs, underlyingPrice: underlyingPrice)
        let greeks = calculateStrategyGreeks(legs: legs, underlyingPrice: underlyingPrice)
        let riskMetrics = calculateRiskMetrics(strategy: strategy, legs: legs, payoffProfile: payoffProfile)

        return StrategyModel(
            strategy: strategy,
            legs: legs,
            netPremium: netPremium,
            payoffProfile: payoffProfile,
            greeks: greeks,
            riskMetrics: riskMetrics,
            breakevenPoints: strategy.breakEvenPoints,
            maxProfit: strategy.maxProfit,
            maxLoss: strategy.maxLoss
        )
    }

    /// Model individual strategy leg
    private func modelLeg(_ leg: OptionsLeg, underlyingPrice: Double) -> StrategyLegModel {
        let contract = leg.contract
        let greeks = greeksCalculator.calculateGreeks(for: contract, underlyingPrice: underlyingPrice)

        return StrategyLegModel(
            leg: leg,
            greeks: greeks,
            intrinsicValue: calculateIntrinsicValue(contract: contract, underlyingPrice: underlyingPrice),
            timeValue: leg.price - calculateIntrinsicValue(contract: contract, underlyingPrice: underlyingPrice),
            delta: greeks.delta,
            gamma: greeks.gamma,
            theta: greeks.theta,
            vega: greeks.vega,
            rho: greeks.rho
        )
    }

    /// Calculate net premium for the strategy
    private func calculateNetPremium(legs: [StrategyLegModel]) -> Double {
        return legs.reduce(0) { $0 + ($1.leg.action == .buy ? $1.leg.price : -$1.leg.price) * Double($1.leg.quantity) }
    }

    /// Calculate payoff profile across price range
    private func calculatePayoffProfile(legs: [StrategyLegModel], underlyingPrice: Double) -> PayoffProfile {
        let priceRange = generatePriceRange(underlyingPrice: underlyingPrice)
        var payoffs: [PayoffPoint] = []

        for price in priceRange {
            let totalPayoff = legs.reduce(0) { $0 + calculateLegPayoff(leg: $1, underlyingPrice: price) }
            payoffs.append(PayoffPoint(price: price, payoff: totalPayoff))
        }

        let maxProfit = payoffs.map { $0.payoff }.max() ?? 0
        let maxLoss = payoffs.map { $0.payoff }.min() ?? 0
        let breakevenPoints = findBreakevenPoints(payoffs: payoffs)

        return PayoffProfile(
            payoffs: payoffs,
            maxProfit: maxProfit,
            maxLoss: maxLoss,
            breakevenPoints: breakevenPoints
        )
    }

    /// Calculate payoff for individual leg
    private func calculateLegPayoff(leg: StrategyLegModel, underlyingPrice: Double) -> Double {
        let contract = leg.leg.contract
        let quantity = Double(leg.leg.quantity)
        let action = leg.leg.action

        let optionValue = calculateOptionValue(contract: contract, underlyingPrice: underlyingPrice)
        let premium = leg.leg.price

        let payoff = action == .buy ? (optionValue - premium) : (premium - optionValue)
        return payoff * quantity
    }

    /// Calculate option value at given underlying price
    private func calculateOptionValue(contract: NIFTYOptionContract, underlyingPrice: Double) -> Double {
        let intrinsic = calculateIntrinsicValue(contract: contract, underlyingPrice: underlyingPrice)
        // For simplicity, using intrinsic value. In production, use full Black-Scholes
        return intrinsic
    }

    /// Calculate intrinsic value
    private func calculateIntrinsicValue(contract: NIFTYOptionContract, underlyingPrice: Double) -> Double {
        switch contract.optionType {
        case .call:
            return max(0, underlyingPrice - contract.strikePrice)
        case .put:
            return max(0, contract.strikePrice - underlyingPrice)
        }
    }

    /// Calculate strategy Greeks
    private func calculateStrategyGreeks(legs: [StrategyLegModel], underlyingPrice: Double) -> StrategyGreeks {
        let netDelta = legs.reduce(0) { $0 + ($1.leg.action == .buy ? $1.delta : -$1.delta) * Double($1.leg.quantity) }
        let netGamma = legs.reduce(0) { $0 + ($1.leg.action == .buy ? $1.gamma : -$1.gamma) * Double($1.leg.quantity) }
        let netTheta = legs.reduce(0) { $0 + ($1.leg.action == .buy ? $1.theta : -$1.theta) * Double($1.leg.quantity) }
        let netVega = legs.reduce(0) { $0 + ($1.leg.action == .buy ? $1.vega : -$1.vega) * Double($1.leg.quantity) }
        let netRho = legs.reduce(0) { $0 + ($1.leg.action == .buy ? $1.rho : -$1.rho) * Double($1.leg.quantity) }

        return StrategyGreeks(
            netDelta: netDelta,
            netGamma: netGamma,
            netTheta: netTheta,
            netVega: netVega,
            netRho: netRho
        )
    }

    /// Calculate risk metrics for the strategy
    private func calculateRiskMetrics(strategy: OptionsStrategy, legs: [StrategyLegModel], payoffProfile: PayoffProfile) -> StrategyRiskMetrics {
        let maxProfit = payoffProfile.maxProfit
        let maxLoss = payoffProfile.maxLoss
        let riskRewardRatio = maxLoss != 0 ? abs(maxProfit / maxLoss) : 0

        // Calculate probability of profit (simplified)
        let pop = estimateProbabilityOfProfit(strategy: strategy, legs: legs)

        // Calculate expected value
        let expectedValue = calculateExpectedValue(payoffProfile: payoffProfile, probability: pop)

        return StrategyRiskMetrics(
            maxProfit: maxProfit,
            maxLoss: maxLoss,
            riskRewardRatio: riskRewardRatio,
            probabilityOfProfit: pop,
            expectedValue: expectedValue,
            marginRequired: strategy.marginRequired
        )
    }

    // MARK: - Strategy Builders

    /// Build Long Call strategy
    func buildLongCall(strike: Double, expiry: Date, premium: Double, quantity: Int = 1) -> OptionsStrategy {
        let contract = createContract(symbol: "NIFTY\(formatStrike(strike))CE", strike: strike, expiry: expiry, type: .call)
        let leg = OptionsLeg(contract: contract, action: .buy, quantity: quantity, price: premium)

        return OptionsStrategy(
            name: "Long Call",
            type: .longCall,
            legs: [leg],
            maxProfit: Double.infinity,
            maxLoss: premium * Double(quantity),
            breakEvenPoints: [strike + premium],
            marginRequired: premium * Double(quantity),
            timestamp: Date()
        )
    }

    /// Build Long Put strategy
    func buildLongPut(strike: Double, expiry: Date, premium: Double, quantity: Int = 1) -> OptionsStrategy {
        let contract = createContract(symbol: "NIFTY\(formatStrike(strike))PE", strike: strike, expiry: expiry, type: .put)
        let leg = OptionsLeg(contract: contract, action: .buy, quantity: quantity, price: premium)

        return OptionsStrategy(
            name: "Long Put",
            type: .longPut,
            legs: [leg],
            maxProfit: strike - premium,
            maxLoss: premium * Double(quantity),
            breakEvenPoints: [strike - premium],
            marginRequired: premium * Double(quantity),
            timestamp: Date()
        )
    }

    /// Build Bull Call Spread
    func buildBullCallSpread(longStrike: Double, shortStrike: Double, expiry: Date, longPremium: Double, shortPremium: Double, quantity: Int = 1) -> OptionsStrategy {
        let longContract = createContract(symbol: "NIFTY\(formatStrike(longStrike))CE", strike: longStrike, expiry: expiry, type: .call)
        let shortContract = createContract(symbol: "NIFTY\(formatStrike(shortStrike))CE", strike: shortStrike, expiry: expiry, type: .call)

        let longLeg = OptionsLeg(contract: longContract, action: .buy, quantity: quantity, price: longPremium)
        let shortLeg = OptionsLeg(contract: shortContract, action: .sell, quantity: quantity, price: shortPremium)

        let netPremium = (longPremium - shortPremium) * Double(quantity)
        let maxProfit = (shortStrike - longStrike - netPremium) * Double(quantity)
        let maxLoss = netPremium * Double(quantity)

        return OptionsStrategy(
            name: "Bull Call Spread",
            type: .bullCallSpread,
            legs: [longLeg, shortLeg],
            maxProfit: maxProfit,
            maxLoss: maxLoss,
            breakEvenPoints: [longStrike + netPremium],
            marginRequired: (shortStrike - longStrike) * Double(quantity) - netPremium,
            timestamp: Date()
        )
    }

    /// Build Iron Condor
    func buildIronCondor(lowerPutStrike: Double, lowerCallStrike: Double, upperPutStrike: Double, upperCallStrike: Double, expiry: Date, premiums: [Double], quantity: Int = 1) -> OptionsStrategy {
        let putContract1 = createContract(symbol: "NIFTY\(formatStrike(lowerPutStrike))PE", strike: lowerPutStrike, expiry: expiry, type: .put)
        let callContract1 = createContract(symbol: "NIFTY\(formatStrike(lowerCallStrike))CE", strike: lowerCallStrike, expiry: expiry, type: .call)
        let putContract2 = createContract(symbol: "NIFTY\(formatStrike(upperPutStrike))PE", strike: upperPutStrike, expiry: expiry, type: .put)
        let callContract2 = createContract(symbol: "NIFTY\(formatStrike(upperCallStrike))CE", strike: upperCallStrike, expiry: expiry, type: .call)

        let legs = [
            OptionsLeg(contract: putContract1, action: .sell, quantity: quantity, price: premiums[0]),
            OptionsLeg(contract: callContract1, action: .sell, quantity: quantity, price: premiums[1]),
            OptionsLeg(contract: putContract2, action: .buy, quantity: quantity, price: premiums[2]),
            OptionsLeg(contract: callContract2, action: .buy, quantity: quantity, price: premiums[3])
        ]

        let netPremium = premiums[0] + premiums[1] - premiums[2] - premiums[3]
        let maxProfit = netPremium * Double(quantity)
        let maxLoss = (upperPutStrike - lowerCallStrike - netPremium) * Double(quantity)

        return OptionsStrategy(
            name: "Iron Condor",
            type: .ironCondor,
            legs: legs,
            maxProfit: maxProfit,
            maxLoss: maxLoss,
            breakEvenPoints: [lowerCallStrike + netPremium, upperPutStrike - netPremium],
            marginRequired: (upperPutStrike - lowerCallStrike) * Double(quantity) - netPremium,
            timestamp: Date()
        )
    }

    // MARK: - Helper Methods

    private func generatePriceRange(underlyingPrice: Double) -> [Double] {
        let range = 0.1 // 10% range
        let minPrice = underlyingPrice * (1 - range)
        let maxPrice = underlyingPrice * (1 + range)
        let step = (maxPrice - minPrice) / 50 // 50 points

        return stride(from: minPrice, to: maxPrice, by: step).map { $0 }
    }

    private func findBreakevenPoints(payoffs: [PayoffPoint]) -> [Double] {
        var breakevens: [Double] = []

        for i in 0..<payoffs.count-1 {
            let current = payoffs[i]
            let next = payoffs[i+1]

            if (current.payoff <= 0 && next.payoff >= 0) || (current.payoff >= 0 && next.payoff <= 0) {
                // Linear interpolation for breakeven
                let ratio = abs(current.payoff) / (abs(current.payoff) + abs(next.payoff))
                let breakeven = current.price + ratio * (next.price - current.price)
                breakevens.append(breakeven)
            }
        }

        return breakevens
    }

    private func createContract(symbol: String, strike: Double, expiry: Date, type: OptionType) -> NIFTYOptionContract {
        return NIFTYOptionContract(
            symbol: symbol,
            underlyingSymbol: "NIFTY",
            strikePrice: strike,
            expiryDate: expiry,
            optionType: type,
            lotSize: 50,
            currentPrice: 0, // Will be set by caller
            bid: 0,
            ask: 0,
            volume: 0,
            openInterest: 0,
            impliedVolatility: 0.2, // Default
            delta: 0,
            gamma: 0,
            theta: 0,
            vega: 0,
            timestamp: Date()
        )
    }

    private func formatStrike(_ strike: Double) -> String {
        return String(format: "%.0f", strike)
    }

    private func estimateProbabilityOfProfit(strategy: OptionsStrategy, legs: [StrategyLegModel]) -> Double {
        // Simplified POP calculation based on delta
        let netDelta = legs.reduce(0) { $0 + ($1.leg.action == .buy ? $1.delta : -$1.delta) * Double($1.leg.quantity) }

        // For neutral strategies, POP is around 50%
        // For directional strategies, adjust based on delta
        let baseProb = 0.5
        let deltaAdjustment = netDelta * 0.1 // 10% adjustment per unit delta

        return max(0.1, min(0.9, baseProb + deltaAdjustment))
    }

    private func calculateExpectedValue(payoffProfile: PayoffProfile, probability: Double) -> Double {
        // Simplified expected value calculation
        let avgPayoff = payoffProfile.payoffs.reduce(0) { $0 + $1.payoff } / Double(payoffProfile.payoffs.count)
        return avgPayoff * probability - avgPayoff * (1 - probability)
    }
}

// MARK: - Supporting Structures

struct StrategyModel {
    let strategy: OptionsStrategy
    let legs: [StrategyLegModel]
    let netPremium: Double
    let payoffProfile: PayoffProfile
    let greeks: StrategyGreeks
    let riskMetrics: StrategyRiskMetrics
    let breakevenPoints: [Double]
    let maxProfit: Double?
    let maxLoss: Double?
}

struct StrategyLegModel {
    let leg: OptionsLeg
    let greeks: OptionGreeks
    let intrinsicValue: Double
    let timeValue: Double
    let delta: Double
    let gamma: Double
    let theta: Double
    let vega: Double
    let rho: Double
}

struct PayoffProfile {
    let payoffs: [PayoffPoint]
    let maxProfit: Double
    let maxLoss: Double
    let breakevenPoints: [Double]
}

struct PayoffPoint {
    let price: Double
    let payoff: Double
}

struct StrategyGreeks {
    let netDelta: Double
    let netGamma: Double
    let netTheta: Double
    let netVega: Double
    let netRho: Double
}

struct StrategyRiskMetrics {
    let maxProfit: Double
    let maxLoss: Double
    let riskRewardRatio: Double
    let probabilityOfProfit: Double
    let expectedValue: Double
    let marginRequired: Double
}

// MARK: - Extensions

extension OptionsStrategy {
    func model(underlyingPrice: Double) -> StrategyModel {
        return OptionsStrategyModeler.shared.modelStrategy(self, underlyingPrice: underlyingPrice)
    }
}
