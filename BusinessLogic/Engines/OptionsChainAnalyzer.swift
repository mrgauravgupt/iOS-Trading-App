import Foundation
import Combine

class OptionsChainAnalyzer {
    private let calculator = OptionsGreeksCalculator()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Methods

    /// Analyze an options chain and return comprehensive metrics
    func analyzeOptionsChain(chain: NIFTYOptionsChain, underlyingPrice: Double) -> OptionsChainAnalysis {
        // Calculate key metrics
        let metrics = chain.calculateMetrics()
        let greeksExposure = calculateGreeksExposure(chain: chain)
        let volatilityProfile = analyzeImpliedVolatility(chain: chain)

        // Analyze market sentiment
        let sentiment = analyzeMarketSentiment(chain: chain, underlyingPrice: underlyingPrice)

        // Return comprehensive analysis
        return OptionsChainAnalysis(
            metrics: metrics,
            ivAnalysis: IVChainAnalysis(),
            greeksExposure: greeksExposure,
            liquidityAnalysis: LiquidityAnalysis(),
            sentimentAnalysis: createSentimentAnalysis(from: sentiment),
            riskMetrics: ChainRiskMetrics(),
            recommendations: []
        )
    }

    /// Analyze an options chain and return comprehensive metrics
    func analyzeOptionsChain(chain: NIFTYOptionsChain) -> OptionsChainAnalysis {
        return analyzeOptionsChain(chain: chain, underlyingPrice: chain.underlyingPrice)
    }

    /// Identify potential trading opportunities based on options chain analysis
    func identifyTradingOpportunities(chain: NIFTYOptionsChain) -> [TradingOpportunity] {
        var opportunities: [TradingOpportunity] = []

        // Get the analysis
        let analysis = analyzeOptionsChain(chain: chain)

        // Check for high IV percentile opportunities
        if analysis.ivAnalysis.ivPercentile > 0.8 {
            opportunities.append(TradingOpportunity(
                type: .highIV,
                description: "High implied volatility environment (IV percentile: \(Int(analysis.ivAnalysis.ivPercentile * 100))%)",
                suggestedStrategies: ["Short Straddle", "Iron Condor", "Credit Spread"],
                confidence: 0.8
            ))
        }

        // Check for low IV percentile opportunities
        if analysis.ivAnalysis.ivPercentile < 0.2 {
            opportunities.append(TradingOpportunity(
                type: .lowIV,
                description: "Low implied volatility environment (IV percentile: \(Int(analysis.ivAnalysis.ivPercentile * 100))%)",
                suggestedStrategies: ["Long Straddle", "Long Strangle", "Debit Spread"],
                confidence: 0.7
            ))
        }

        // Check for unusual OI concentration
        let oiConcentration = analyzeOpenInterestConcentration(chain: chain)
        if let unusualStrike = oiConcentration.unusualStrikes.first {
            opportunities.append(TradingOpportunity(
                type: .unusualActivity,
                description: "Unusual open interest concentration at strike \(unusualStrike)",
                suggestedStrategies: ["Monitor closely", "Consider directional bias"],
                confidence: 0.6
            ))
        }

        return opportunities
    }

    // MARK: - Private Methods

    /// Calculate Greeks exposure for the options chain
    private func calculateGreeksExposure(chain: NIFTYOptionsChain) -> GreeksExposure {
        var netDelta: Double = 0
        var netGamma: Double = 0
        var netTheta: Double = 0
        var netVega: Double = 0

        for option in chain.callOptions + chain.putOptions {
            let exposure = option.openInterest
            netDelta += option.delta * Double(exposure)
            netGamma += option.gamma * Double(exposure)
            netTheta += option.theta * Double(exposure)
            netVega += option.vega * Double(exposure)
        }

        return GreeksExposure(
            netDelta: netDelta,
            netGamma: netGamma,
            netTheta: netTheta,
            netVega: netVega
        )
    }

    /// Analyze implied volatility profile
    private func analyzeImpliedVolatility(chain: NIFTYOptionsChain) -> VolatilityProfile {
        let avgIV = (chain.callOptions + chain.putOptions).map { $0.impliedVolatility }.reduce(0, +) / Double(chain.callOptions.count + chain.putOptions.count)
        let skew = calculateSkew(optionsChain: chain)
        let ivPercentile = 0.65 // Mock percentile calculation

        return VolatilityProfile(
            averageIV: avgIV,
            skew: skew,
            ivPercentile: ivPercentile,
            termStructure: ["1M": avgIV, "2M": avgIV * 1.05, "3M": avgIV * 1.1]
        )
    }

    /// Analyze open interest concentration
    private func analyzeOpenInterestConcentration(chain: NIFTYOptionsChain) -> OIConcentration {
        let allOptions = chain.callOptions + chain.putOptions
        let totalOI = allOptions.reduce(0) { $0 + $1.openInterest }
        let avgOI = Double(totalOI) / Double(allOptions.count)

        var unusualStrikes: [Double] = []
        var strikeOIRatios: [Double: Double] = [:]

        for option in allOptions {
            let ratio = Double(option.openInterest) / Double(totalOI)
            strikeOIRatios[option.strikePrice] = ratio

            if Double(option.openInterest) > avgOI * 2.0 {
                unusualStrikes.append(option.strikePrice)
            }
        }

        return OIConcentration(
            unusualStrikes: unusualStrikes,
            strikeOIRatios: strikeOIRatios
        )
    }

    /// Analyze market sentiment from options chain
    private func analyzeMarketSentiment(chain: NIFTYOptionsChain, underlyingPrice: Double) -> SentimentAnalysis {
        let totalCallOI = chain.callOptions.reduce(0) { $0 + $1.openInterest }
        let totalPutOI = chain.putOptions.reduce(0) { $0 + $1.openInterest }
        let totalCallVolume = chain.callOptions.reduce(0) { $0 + $1.volume }
        let totalPutVolume = chain.putOptions.reduce(0) { $0 + $1.volume }

        let pcr = Double(totalPutVolume) / Double(totalCallVolume)
        let oiPcr = Double(totalPutOI) / Double(totalCallOI)
        let skew = calculateSkew(optionsChain: chain)

        // Calculate sentiment score based on PCR and skew
        let pcrFactor = normalizePCR(pcr)
        let oiPcrFactor = normalizeOIPCR(oiPcr)
        let skewFactor = normalizeSkew(skew)
        let gammaFactor = calculateGammaExposure(chain: chain)

        let sentimentScore = (pcrFactor * 0.4) +
                            (oiPcrFactor * 0.3) +
                            (skewFactor * 0.2) +
                            (gammaFactor * 0.1)

        let marketSentiment = interpretSentiment(sentimentScore)

        return SentimentAnalysis(
            putCallRatio: pcr,
            oiPutCallRatio: oiPcr,
            volatilitySkew: skew,
            sentimentScore: sentimentScore,
            marketSentiment: marketSentiment,
            keywords: ["volatility", "momentum", "trend"],
            sources: ["options chain analysis"]
        )
    }

    /// Calculate volatility skew
    private func calculateSkew(optionsChain: NIFTYOptionsChain) -> Double {
        let atmStrike = optionsChain.getATMStrike()

        guard let atmCall = optionsChain.callOptions.first(where: { abs($0.strikePrice - atmStrike) < 25 }),
              let atmPut = optionsChain.putOptions.first(where: { abs($0.strikePrice - atmStrike) < 25 }),
              let otmCall = optionsChain.callOptions.first(where: { $0.strikePrice > atmStrike + 200 }),
              let otmPut = optionsChain.putOptions.first(where: { $0.strikePrice < atmStrike - 200 }) else {
            return 0.0
        }

        let callSkew = otmCall.impliedVolatility - atmCall.impliedVolatility
        let putSkew = otmPut.impliedVolatility - atmPut.impliedVolatility

        return (callSkew + putSkew) / 2.0
    }

    /// Calculate gamma exposure
    private func calculateGammaExposure(chain: NIFTYOptionsChain) -> Double {
        return (chain.callOptions + chain.putOptions).reduce(0) { $0 + $1.gamma * Double($1.openInterest) }
    }

    /// Create sentiment analysis from local analysis
    private func createSentimentAnalysis(from sentiment: SentimentAnalysis) -> SentimentAnalysis {
        return sentiment
    }

    /// Normalize PCR to a -1 to 1 scale
    private func normalizePCR(_ pcr: Double) -> Double {
        // PCR > 1 indicates bearishness, < 1 indicates bullishness
        if pcr > 1.0 {
            return min((pcr - 1.0) * -1.0, -0.1) // Negative score for bearish
        } else {
            return min((1.0 - pcr) * 1.0, 1.0) // Positive score for bullish
        }
    }

    /// Normalize OI PCR
    private func normalizeOIPCR(_ oiPcr: Double) -> Double {
        return normalizePCR(oiPcr)
    }

    /// Normalize skew to a -1 to 1 scale
    private func normalizeSkew(_ skew: Double) -> Double {
        // Positive skew (puts more expensive than calls) indicates bearishness
        return min(max(skew * -3.0, -1.0), 1.0)
    }

    /// Interpret sentiment score into a market sentiment category
    private func interpretSentiment(_ score: Double) -> MarketSentimentType? {
        if score > 0.5 {
            return .bullish
        } else if score > 0.2 {
            return .moderatelyBullish
        } else if score > -0.2 {
            return .neutral
        } else if score > -0.5 {
            return .moderatelyBearish
        } else {
            return .bearish
        }
    }
}

// MARK: - Supporting Types

struct VolatilityProfile {
    let averageIV: Double
    let skew: Double
    let ivPercentile: Double
    let termStructure: [String: Double]
}

struct OIConcentration {
    let unusualStrikes: [Double]
    let strikeOIRatios: [Double: Double]
}

enum TradingOpportunityType {
    case highIV
    case lowIV
    case skewOpportunity
    case unusualActivity
}

struct TradingOpportunity {
    let type: TradingOpportunityType
    let description: String
    let suggestedStrategies: [String]
    let confidence: Double
}
