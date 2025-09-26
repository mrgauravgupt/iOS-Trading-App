import Foundation

// MARK: - Options Chain Analyzer

class OptionsChainAnalyzer {
    static let shared = OptionsChainAnalyzer()

    private let greeksCalculator = OptionsGreeksCalculator.shared
    private let ivAnalyzer = ImpliedVolatilityAnalyzer.shared

    // MARK: - Core Analysis Methods

    /// Comprehensive analysis of options chain
    func analyzeChain(_ chain: NIFTYOptionsChain, underlyingPrice: Double) -> OptionsChainAnalysis {
        let metrics = chain.calculateMetrics()
        let ivAnalysis = ivAnalyzer.calculateIVForChain(chain, underlyingPrice: underlyingPrice)
        let greeksExposure = calculateGreeksExposure(chain: chain)
        let liquidityAnalysis = analyzeLiquidity(chain: chain)
        let sentimentAnalysis = analyzeMarketSentiment(chain: chain, underlyingPrice: underlyingPrice)
        let riskMetrics = calculateRiskMetrics(chain: chain, underlyingPrice: underlyingPrice)

        return OptionsChainAnalysis(
            metrics: metrics,
            ivAnalysis: ivAnalysis,
            greeksExposure: greeksExposure,
            liquidityAnalysis: liquidityAnalysis,
            sentimentAnalysis: sentimentAnalysis,
            riskMetrics: riskMetrics,
            recommendations: generateRecommendations(analysis: OptionsChainAnalysis(
                metrics: metrics,
                ivAnalysis: ivAnalysis,
                greeksExposure: greeksExposure,
                liquidityAnalysis: liquidityAnalysis,
                sentimentAnalysis: sentimentAnalysis,
                riskMetrics: riskMetrics,
                recommendations: []
            ))
        )
    }

    /// Calculate Greeks exposure for the entire chain
    private func calculateGreeksExposure(chain: NIFTYOptionsChain) -> GreeksExposure {
        var totalDelta: Double = 0
        var totalGamma: Double = 0
        var totalTheta: Double = 0
        var totalVega: Double = 0
        var totalRho: Double = 0

        let allOptions = chain.callOptions + chain.putOptions

        for option in allOptions {
            let greeks = greeksCalculator.calculateGreeks(for: option, underlyingPrice: chain.underlyingPrice)
            totalDelta += greeks.delta * Double(option.openInterest)
            totalGamma += greeks.gamma * Double(option.openInterest)
            totalTheta += greeks.theta * Double(option.openInterest)
            totalVega += greeks.vega * Double(option.openInterest)
            totalRho += greeks.rho * Double(option.openInterest)
        }

        return GreeksExposure(
            netDelta: totalDelta,
            netGamma: totalGamma,
            netTheta: totalTheta,
            netVega: totalVega,
            netRho: totalRho
        )
    }

    /// Analyze liquidity across the chain
    private func analyzeLiquidity(chain: NIFTYOptionsChain) -> LiquidityAnalysis {
        let allOptions = chain.callOptions + chain.putOptions

        let avgSpread = allOptions.map { ($0.ask - $0.bid) / $0.currentPrice }.reduce(0, +) / Double(allOptions.count)
        let totalVolume = allOptions.reduce(0) { $0 + $1.volume }
        let totalOI = allOptions.reduce(0) { $0 + $1.openInterest }

        // Calculate volume concentration
        let highVolumeStrikes = allOptions.filter { $0.volume > totalVolume / 20 } // Top 5%
        let volumeConcentration = Double(highVolumeStrikes.count) / Double(allOptions.count)

        // Calculate OI concentration
        let highOIStrikes = allOptions.filter { $0.openInterest > totalOI / 20 } // Top 5%
        let oiConcentration = Double(highOIStrikes.count) / Double(allOptions.count)

        return LiquidityAnalysis(
            averageSpread: avgSpread,
            totalVolume: totalVolume,
            totalOpenInterest: totalOI,
            volumeConcentration: volumeConcentration,
            oiConcentration: oiConcentration
        )
    }

    /// Analyze market sentiment from options data
    private func analyzeMarketSentiment(chain: NIFTYOptionsChain, underlyingPrice: Double) -> SentimentAnalysis {
        let atmStrike = chain.getATMStrike()

        // Calculate put/call ratio
        let pcr = chain.calculateMetrics().pcr

        // Calculate open interest ratio
        let oiPcr = chain.calculateMetrics().oiPcr

        // Analyze skew
        let skew = greeksCalculator.calculateSkew(optionsChain: chain)

        // Calculate gamma exposure
        let greeksExp = calculateGreeksExposure(chain: chain)

        // Determine sentiment based on multiple factors
        let sentimentScore = calculateSentimentScore(pcr: pcr, oiPcr: oiPcr, skew: skew, gamma: greeksExp.netGamma)

        return SentimentAnalysis(
            putCallRatio: pcr,
            oiPutCallRatio: oiPcr,
            volatilitySkew: skew,
            sentimentScore: sentimentScore,
            marketSentiment: interpretSentiment(sentimentScore),
            confidenceLevel: calculateSentimentConfidence(pcr: pcr, oiPcr: oiPcr, skew: skew)
        )
    }

    /// Calculate risk metrics for the options chain
    private func calculateRiskMetrics(chain: NIFTYOptionsChain, underlyingPrice: Double) -> ChainRiskMetrics {
        let greeksExp = calculateGreeksExposure(chain: chain)
        let ivAnalysis = ivAnalyzer.calculateIVForChain(chain, underlyingPrice: underlyingPrice)

        // Calculate Value at Risk (simplified)
        let var95 = calculateVaR(chain: chain, underlyingPrice: underlyingPrice, confidence: 0.95)

        // Calculate stress test results
        let stressTests = performStressTests(chain: chain, underlyingPrice: underlyingPrice)

        return ChainRiskMetrics(
            valueAtRisk: var95,
            gammaRisk: abs(greeksExp.netGamma),
            thetaDecay: abs(greeksExp.netTheta),
            vegaRisk: abs(greeksExp.netVega),
            stressTestResults: convertStressTestResults(stressTests),
            riskScore: calculateRiskScore(var95: var95, gamma: greeksExp.netGamma, iv: ivAnalysis.averageIV)
        )
    }

    // MARK: - Advanced Analysis Methods

    /// Find optimal strikes for different strategies
    func findOptimalStrikes(chain: NIFTYOptionsChain, strategy: OptionsStrategyType, underlyingPrice: Double) -> [OptimalStrike] {
        let atmStrike = chain.getATMStrike()

        switch strategy {
        case .longCall, .longPut:
            return findSingleLegStrikes(chain: chain, atmStrike: atmStrike, underlyingPrice: underlyingPrice)
        case .longStraddle, .shortStraddle:
            return findStraddleStrikes(chain: chain, atmStrike: atmStrike, underlyingPrice: underlyingPrice)
        case .bullCallSpread, .bearPutSpread:
            return findSpreadStrikes(chain: chain, atmStrike: atmStrike, underlyingPrice: underlyingPrice, isBullish: strategy == .bullCallSpread)
        case .ironCondor:
            return findIronCondorStrikes(chain: chain, atmStrike: atmStrike, underlyingPrice: underlyingPrice)
        default:
            return []
        }
    }

    /// Analyze expiration effects
    func analyzeExpirationEffects(chain: NIFTYOptionsChain, daysToExpiry: Int) -> ExpirationAnalysis {
        let timeDecay = calculateTimeDecay(chain: chain, daysToExpiry: daysToExpiry)
        let pinRisk = calculatePinRisk(chain: chain)
        let gammaScalping = analyzeGammaScalping(chain: chain)

        // Create expiration metrics for different time periods
        let nearTerm = ExpirationMetrics(
            daysToExpiry: min(daysToExpiry, 30),
            openInterest: 0,
            volume: 0,
            putCallRatio: 0.0,
            avgImpliedVolatility: 0.0
        )
        
        let mediumTerm = ExpirationMetrics(
            daysToExpiry: min(max(daysToExpiry, 30), 90),
            openInterest: 0,
            volume: 0,
            putCallRatio: 0.0,
            avgImpliedVolatility: 0.0
        )
        
        let longTerm = ExpirationMetrics(
            daysToExpiry: max(daysToExpiry, 90),
            openInterest: 0,
            volume: 0,
            putCallRatio: 0.0,
            avgImpliedVolatility: 0.0
        )

        return ExpirationAnalysis(
            nearTerm: nearTerm,
            mediumTerm: mediumTerm,
            longTerm: longTerm,
            termStructure: [nearTerm, mediumTerm, longTerm]
        )
    }

    /// Analyze volatility events
    func analyzeVolatilityEvents(chain: NIFTYOptionsChain, historicalData: [HistoricalVolatility]) -> VolatilityAnalysis {
        let currentIV = ivAnalyzer.calculateIVForChain(chain, underlyingPrice: chain.underlyingPrice).averageIV
        let ivPercentile = ivAnalyzer.calculateIVPercentile(currentIV: currentIV, historicalIVs: historicalData.map { $0.impliedVol })

        let volatilityRegime = determineVolatilityRegime(currentIV: currentIV, percentile: ivPercentile)
        let expectedMove = calculateExpectedMove(underlyingPrice: chain.underlyingPrice, iv: currentIV, daysToExpiry: 1)

        return VolatilityAnalysis(
            currentIV: currentIV,
            historicalVolatility: 0.0,
            ivPercentile: ivPercentile,
            volRiskPremium: 0.0,
            regime: volatilityRegime,
            expectedMove: expectedMove
        )
    }

    // MARK: - Helper Methods

    private func calculateLiquidityScore(avgSpread: Double, totalVolume: Int, totalOI: Int) -> Double {
        // Normalize to 0-1 scale
        let spreadScore = max(0, 1 - avgSpread * 10) // Lower spread = higher score
        let volumeScore = min(1, Double(totalVolume) / 100000) // Higher volume = higher score
        let oiScore = min(1, Double(totalOI) / 500000) // Higher OI = higher score

        return (spreadScore + volumeScore + oiScore) / 3
    }

    private func calculateSentimentScore(pcr: Double, oiPcr: Double, skew: Double, gamma: Double) -> Double {
        // Normalize to -1 (bearish) to 1 (bullish)
        let pcrScore = (pcr - 1) / 0.5 // PCR > 1 is bearish, < 1 is bullish
        let oiPcrScore = (oiPcr - 1) / 0.5
        let skewScore = skew / 0.1 // Positive skew is bullish
        let gammaScore = gamma / 10000 // Positive gamma exposure

        return (pcrScore + oiPcrScore + skewScore + gammaScore) / 4
    }

    private func interpretSentiment(_ score: Double) -> MarketSentiment {
        switch score {
        case let x where x > 0.3: return .bullish
        case let x where x < -0.3: return .bearish
        default: return .neutral
        }
    }

    private func calculateSentimentConfidence(pcr: Double, oiPcr: Double, skew: Double) -> Double {
        // Calculate confidence based on data consistency
        let pcrOiDiff = abs(pcr - oiPcr) / max(pcr, oiPcr)
        let consistency = 1 - pcrOiDiff

        return min(consistency, 0.9) // Cap at 90%
    }

    private func calculateVaR(chain: NIFTYOptionsChain, underlyingPrice: Double, confidence: Double) -> Double {
        // Simplified VaR calculation using delta approximation
        let greeksExp = calculateGreeksExposure(chain: chain)
        let ivAnalysis = ivAnalyzer.calculateIVForChain(chain, underlyingPrice: underlyingPrice)

        // Assume 1-day, 1 standard deviation move
        let dailyMove = underlyingPrice * ivAnalysis.averageIV / sqrt(365)
        let deltaVaR = abs(greeksExp.netDelta) * dailyMove

        // Adjust for confidence level (simplified)
        let zScore = confidence == 0.95 ? 1.645 : 1.96
        return deltaVaR * zScore
    }

    private func performStressTests(chain: NIFTYOptionsChain, underlyingPrice: Double) -> [StressTestResult] {
        // Define scenarios with name, price multiplier, and IV multiplier
        let scenarios: [(String, Double, Double)] = [
            ("+5% Move", 1.05, 1.0),
            ("-5% Move", 0.95, 1.0),
            ("+10% Move", 1.10, 1.0),
            ("-10% Move", 0.90, 1.0),
            ("IV +20%", 1.0, 1.2),
            ("IV -20%", 1.0, 0.8)
        ]

        return scenarios.map { scenario in
            let (name, priceMultiplier, ivMultiplier) = scenario
            let stressedPrice = underlyingPrice * priceMultiplier
            let stressedIV = 0.2 * ivMultiplier

            // Calculate P&L impact
            let basePnL = 0.0 // Simplified for this example
            let stressedPnL = 0.0 // Would be calculated based on stressed parameters

            return StressTestResult(
                scenario: name,
                priceImpact: stressedPnL - basePnL,
                riskLevel: .medium
            )
        }
    }

    private func calculateStressImpact(chain: NIFTYOptionsChain, stressedPrice: Double, stressedIV: Double) -> Double {
        // Simplified impact calculation
        let greeksExp = calculateGreeksExposure(chain: chain)
        let priceChange = stressedPrice - chain.underlyingPrice
        let ivChange = stressedIV - 1.0

        return greeksExp.netDelta * priceChange + greeksExp.netVega * ivChange
    }

    /// Calculate risk score based on multiple factors
    private func calculateRiskScore(var95: Double, gamma: Double, iv: Double) -> Double {
        // Simple weighted risk score calculation
        let varWeight: Double = 0.4
        let gammaWeight: Double = 0.3
        let ivWeight: Double = 0.3
        
        // Normalize values (this is a simplified approach)
        let normalizedVar = min(var95 / 10000, 1.0)
        let normalizedGamma = min(abs(gamma) / 1000, 1.0)
        let normalizedIV = min(iv / 0.5, 1.0)
        
        return (normalizedVar * varWeight) + (normalizedGamma * gammaWeight) + (normalizedIV * ivWeight)
    }
    
    /// Convert stress test results to dictionary
    private func convertStressTestResults(_ results: [StressTestResult]) -> [String: Double] {
        var dict: [String: Double] = [:]
        for result in results {
            dict[result.scenario] = result.priceImpact
        }
        return dict
    }
    
    private func generateRecommendations(analysis: OptionsChainAnalysis) -> [String] {
        var recommendations: [String] = []

        // Sentiment-based recommendations
        switch analysis.sentimentAnalysis.marketSentiment {
        case .bullish:
            recommendations.append("Consider bullish strategies like Long Calls or Bull Call Spreads")
        case .bearish:
            recommendations.append("Consider bearish strategies like Long Puts or Bear Put Spreads")
        case .neutral:
            recommendations.append("Consider neutral strategies like Iron Condors or Straddles")
        }

        // Volatility-based recommendations
        if analysis.ivAnalysis.averageIV > 0.3 {
            recommendations.append("High volatility environment - consider selling options premium")
        } else {
            recommendations.append("Low volatility environment - consider buying options for cheap premium")
        }

        // Risk-based recommendations
        if analysis.riskMetrics.riskScore > 0.7 {
            recommendations.append("High risk environment - reduce position sizes and use protective stops")
        }

        return recommendations
    }

    // Additional helper methods would go here...
    private func findSingleLegStrikes(chain: NIFTYOptionsChain, atmStrike: Double, underlyingPrice: Double) -> [OptimalStrike] {
        // Implementation for finding optimal strikes for single leg strategies
        return []
    }

    private func findStraddleStrikes(chain: NIFTYOptionsChain, atmStrike: Double, underlyingPrice: Double) -> [OptimalStrike] {
        // Implementation for straddle strikes
        return []
    }

    private func findSpreadStrikes(chain: NIFTYOptionsChain, atmStrike: Double, underlyingPrice: Double, isBullish: Bool) -> [OptimalStrike] {
        // Implementation for spread strikes
        return []
    }

    private func findIronCondorStrikes(chain: NIFTYOptionsChain, atmStrike: Double, underlyingPrice: Double) -> [OptimalStrike] {
        // Implementation for iron condor strikes
        return []
    }

    private func calculateTimeDecay(chain: NIFTYOptionsChain, daysToExpiry: Int) -> Double {
        // Calculate theta decay
        return 0.0
    }

    private func calculatePinRisk(chain: NIFTYOptionsChain) -> Double {
        // Calculate pin risk
        return 0.0
    }

    private func analyzeGammaScalping(chain: NIFTYOptionsChain) -> Double {
        // Analyze gamma scalping opportunities
        return 0.0
    }

    private func recommendExpiryStrategy(daysToExpiry: Int, pinRisk: Double, gammaScalping: Double) -> String {
        return "Hold positions"
    }

    private func determineVolatilityRegime(currentIV: Double, percentile: Double) -> VolatilityRegime {
        if percentile > 0.8 { return .high }
        else if percentile < 0.2 { return .low }
        else { return .normal }
    }

    private func calculateExpectedMove(underlyingPrice: Double, iv: Double, daysToExpiry: Int) -> Double {
        return underlyingPrice * iv * sqrt(Double(daysToExpiry) / 365)
    }

    private func detectVolatilityEvents(historicalData: [HistoricalVolatility]) -> [VolatilityEvent] {
        return []
    }

    private func interpretRiskLevel(_ impact: Double) -> RiskLevel {
        if impact > 10000 { return .high }
        else if impact > 5000 { return .medium }
        else { return .low }
    }
}

// MARK: - Supporting Structures

struct OptimalStrike {
    let strike: Double
    let optionType: OptionType
    let reasoning: String
    let expectedReturn: Double
    let riskLevel: RiskLevel
}

// MARK: - Extensions and Helpers

extension NIFTYOptionsChain {
    func getATMStrike(currentPrice: Double) -> Double {
        let strikes = callOptions.map { $0.strikePrice } + putOptions.map { $0.strikePrice }
        return strikes.min(by: { abs($0 - currentPrice) < abs($1 - currentPrice) }) ?? currentPrice
    }
}

extension NIFTYOptionsChain {
    func performAnalysis(underlyingPrice: Double) -> OptionsChainAnalysis {
        return OptionsChainAnalyzer.shared.analyzeChain(self, underlyingPrice: underlyingPrice)
    }
}
