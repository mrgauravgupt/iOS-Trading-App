import Foundation

// MARK: - Options Greeks Calculator

class OptionsGreeksCalculator {
    static let shared = OptionsGreeksCalculator()

    // MARK: - Black-Scholes Model Constants
    private let sqrt2Pi = sqrt(2 * Double.pi)

    // MARK: - Core Greeks Calculations

    /// Calculate all Greeks for an option contract
    func calculateGreeks(for contract: NIFTYOptionContract, underlyingPrice: Double, riskFreeRate: Double = 0.06, dividendYield: Double = 0.0) -> OptionGreeks {
        let S = underlyingPrice
        let K = contract.strikePrice
        let T = timeToExpiry(from: contract.expiryDate)
        let r = riskFreeRate
        let q = dividendYield
        let sigma = contract.impliedVolatility

        // Avoid division by zero or invalid calculations
        guard T > 0, sigma > 0, S > 0, K > 0 else {
            return OptionGreeks(delta: 0, gamma: 0, theta: 0, vega: 0, rho: 0, lambda: 0)
        }

        let d1 = calculateD1(S: S, K: K, T: T, r: r, q: q, sigma: sigma)
        let d2 = d1 - sigma * sqrt(T)

        let delta = calculateDelta(d1: d1, isCall: contract.optionType == .call)
        let gamma = calculateGamma(d1: d1, S: S, sigma: sigma, T: T)
        let theta = calculateTheta(d1: d1, d2: d2, S: S, K: K, T: T, r: r, sigma: sigma, isCall: contract.optionType == .call)
        let vega = calculateVega(d1: d1, S: S, T: T)
        let rho = calculateRho(d2: d2, K: K, T: T, r: r, isCall: contract.optionType == .call)
        let lambda = calculateLambda(delta: delta, price: contract.currentPrice, S: S)

        return OptionGreeks(delta: delta, gamma: gamma, theta: theta, vega: vega, rho: rho, lambda: lambda)
    }

    /// Calculate Delta (rate of change of option price with respect to underlying price)
    private func calculateDelta(d1: Double, isCall: Bool) -> Double {
        if isCall {
            return normalCDF(d1)
        } else {
            return normalCDF(d1) - 1
        }
    }

    /// Calculate Gamma (rate of change of delta with respect to underlying price)
    private func calculateGamma(d1: Double, S: Double, sigma: Double, T: Double) -> Double {
        let normalDensity = normalDensity(d1)
        return normalDensity / (S * sigma * sqrt(T))
    }

    /// Calculate Theta (time decay of option price)
    private func calculateTheta(d1: Double, d2: Double, S: Double, K: Double, T: Double, r: Double, sigma: Double, isCall: Bool) -> Double {
        let normalDensity = normalDensity(d1)

        let term1 = -(S * sigma * normalDensity) / (2 * sqrt(T))
        let term2 = r * K * exp(-r * T) * (isCall ? normalCDF(d2) : -normalCDF(-d2))

        if isCall {
            return term1 - term2
        } else {
            return term1 + term2
        }
    }

    /// Calculate Vega (sensitivity to volatility)
    private func calculateVega(d1: Double, S: Double, T: Double) -> Double {
        return S * sqrt(T) * normalDensity(d1) * 0.01 // Vega per 1% change in volatility
    }

    /// Calculate Rho (sensitivity to interest rate)
    private func calculateRho(d2: Double, K: Double, T: Double, r: Double, isCall: Bool) -> Double {
        if isCall {
            return K * T * exp(-r * T) * normalCDF(d2) * 0.01 // Rho per 1% change in rate
        } else {
            return -K * T * exp(-r * T) * normalCDF(-d2) * 0.01
        }
    }

    /// Calculate Lambda (leverage/elasticity)
    private func calculateLambda(delta: Double, price: Double, S: Double) -> Double {
        guard price > 0 else { return 0 }
        return delta * (S / price)
    }

    // MARK: - Helper Calculations

    private func calculateD1(S: Double, K: Double, T: Double, r: Double, q: Double, sigma: Double) -> Double {
        return (log(S / K) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * sqrt(T))
    }

    private func timeToExpiry(from expiryDate: Date) -> Double {
        let now = Date()
        let timeInterval = expiryDate.timeIntervalSince(now)
        return max(timeInterval / (365 * 24 * 3600), 0) // Convert to years
    }

    // MARK: - Statistical Functions

    /// Normal cumulative distribution function
    private func normalCDF(_ x: Double) -> Double {
        return 0.5 * (1 + erf(x / sqrt(2)))
    }

    /// Normal probability density function
    private func normalDensity(_ x: Double) -> Double {
        return exp(-0.5 * x * x) / sqrt2Pi
    }

    /// Error function approximation
    private func erf(_ x: Double) -> Double {
        let a1 =  0.254829592
        let a2 = -0.284496736
        let a3 =  1.421413741
        let a4 = -1.453152027
        let a5 =  1.061405429
        let p  =  0.3275911

        let sign = x < 0 ? -1.0 : 1.0
        let absX = abs(x)

        let t = 1.0 / (1.0 + p * absX)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX)

        return sign * y
    }

    // MARK: - Implied Volatility Calculation

    /// Calculate implied volatility using Newton-Raphson method
    func calculateImpliedVolatility(optionPrice: Double, S: Double, K: Double, T: Double, r: Double = 0.06, q: Double = 0.0, isCall: Bool, tolerance: Double = 1e-5, maxIterations: Int = 100) -> Double? {
        var sigma = 0.2 // Initial guess
        var iteration = 0

        while iteration < maxIterations {
            let price = blackScholesPrice(S: S, K: K, T: T, r: r, q: q, sigma: sigma, isCall: isCall)
            let vega = calculateVega(d1: calculateD1(S: S, K: K, T: T, r: r, q: q, sigma: sigma), S: S, T: T)

            guard vega != 0 else { break }

            let diff = price - optionPrice
            let newSigma = sigma - diff / vega

            if abs(newSigma - sigma) < tolerance {
                return max(0.001, newSigma) // Ensure positive volatility
            }

            sigma = newSigma
            iteration += 1
        }

        return nil // Could not converge
    }

    /// Black-Scholes price calculation
    private func blackScholesPrice(S: Double, K: Double, T: Double, r: Double, q: Double, sigma: Double, isCall: Bool) -> Double {
        let d1 = calculateD1(S: S, K: K, T: T, r: r, q: q, sigma: sigma)
        let d2 = d1 - sigma * sqrt(T)

        if isCall {
            return S * exp(-q * T) * normalCDF(d1) - K * exp(-r * T) * normalCDF(d2)
        } else {
            return K * exp(-r * T) * normalCDF(-d2) - S * exp(-q * T) * normalCDF(-d1)
        }
    }

    // MARK: - Options Chain Analysis

    /// Calculate Put-Call Ratio
    func calculatePCR(callVolume: Int, putVolume: Int) -> Double {
        guard putVolume > 0 else { return 0 }
        return Double(putVolume) / Double(callVolume)
    }

    /// Calculate Open Interest PCR
    func calculateOIPCR(callOI: Int, putOI: Int) -> Double {
        guard putOI > 0 else { return 0 }
        return Double(putOI) / Double(callOI)
    }

    /// Find Maximum Pain strike price
    func calculateMaxPain(optionsChain: NIFTYOptionsChain) -> Double {
        var maxPain = 0.0
        var minTotalValue = Double.infinity

        // Get unique strike prices
        let strikes = Set(optionsChain.callOptions.map { $0.strikePrice } + optionsChain.putOptions.map { $0.strikePrice }).sorted()

        for strike in strikes {
            let callOI = optionsChain.callOptions.filter { $0.strikePrice == strike }.reduce(0) { $0 + $1.openInterest }
            let putOI = optionsChain.putOptions.filter { $0.strikePrice == strike }.reduce(0) { $0 + $1.openInterest }

            let totalValue = Double(callOI + putOI) * strike
            if totalValue < minTotalValue {
                minTotalValue = totalValue
                maxPain = strike
            }
        }

        return maxPain
    }

    /// Calculate Option Chain Skew
    func calculateSkew(optionsChain: NIFTYOptionsChain) -> Double {
        let atmStrike = optionsChain.getATMStrike()

        guard let atmCall = optionsChain.callOptions.first(where: { $0.strikePrice == atmStrike }),
              let atmPut = optionsChain.putOptions.first(where: { $0.strikePrice == atmStrike }) else {
            return 0
        }

        let callIV = atmCall.impliedVolatility
        let putIV = atmPut.impliedVolatility

        return (callIV - putIV) / ((callIV + putIV) / 2) // Normalized skew
    }

    // MARK: - Risk Metrics

    /// Calculate Option Delta Exposure
    func calculateDeltaExposure(positions: [OptionsPosition]) -> Double {
        return positions.reduce(0) { $0 + ($1.quantity > 0 ? $1.currentPrice : -$1.currentPrice) }
    }

    /// Calculate Gamma Exposure
    func calculateGammaExposure(positions: [OptionsPosition]) -> Double {
        return positions.reduce(0) { $0 + abs($1.currentPrice) * Double(abs($1.quantity)) }
    }

    /// Calculate Theta Decay
    func calculateThetaDecay(positions: [OptionsPosition]) -> Double {
        // Simplified calculation - in a real app, you'd use the actual theta value
        return positions.reduce(0) { $0 + Double($1.quantity) * 0.01 }
    }

    /// Calculate Vega Risk
    func calculateVegaRisk(positions: [OptionsPosition]) -> Double {
        // Simplified calculation - in a real app, you'd use the actual vega value
        return positions.reduce(0) { $0 + Double(abs($1.quantity)) * 0.02 }
    }

    /// Calculate portfolio Greeks
    func calculatePortfolioGreeks(positions: [OptionsPosition]) -> PortfolioGreeks {
        let delta = calculateDeltaExposure(positions: positions)
        let gamma = calculateGammaExposure(positions: positions)
        let theta = calculateThetaDecay(positions: positions)
        let vega = calculateVegaRisk(positions: positions)

        return PortfolioGreeks(
            delta: delta,
            gamma: gamma,
            theta: theta,
            vega: vega
        )
    }
}

// MARK: - Supporting Structures

struct OptionGreeks {
    let delta: Double
    let gamma: Double
    let theta: Double
    let vega: Double
    let rho: Double
    let lambda: Double

    var description: String {
        return String(format: "Δ: %.3f, Γ: %.3f, Θ: %.3f, V: %.3f, Ρ: %.3f, Λ: %.3f",
                      delta, gamma, theta, vega, rho, lambda)
    }
}

struct PortfolioGreeks {
    let delta: Double
    let gamma: Double
    let theta: Double
    let vega: Double

    var description: String {
        return String(format: "Δ: %.3f, Γ: %.3f, Θ: %.3f, V: %.3f",
                      delta, gamma, theta, vega)
    }
}

// MARK: - Helper Extensions

extension Array where Element == NIFTYOptionContract {
    func filterByStrikeRange(min: Double, max: Double) -> [NIFTYOptionContract] {
        return filter { $0.strikePrice >= min && $0.strikePrice <= max }
    }
    
    func filterByExpiryRange(min: Date, max: Date) -> [NIFTYOptionContract] {
        return filter { $0.expiryDate >= min && $0.expiryDate <= max }
    }
}

extension NIFTYOptionsChain {
    func calculateMetrics() -> OptionsChainMetrics {
        let totalCallOI = callOptions.reduce(0) { $0 + $1.openInterest }
        let totalPutOI = putOptions.reduce(0) { $0 + $1.openInterest }
        let totalCallVolume = callOptions.reduce(0) { $0 + $1.volume }
        let totalPutVolume = putOptions.reduce(0) { $0 + $1.volume }

        let pcr = OptionsGreeksCalculator.shared.calculatePCR(callVolume: totalCallVolume, putVolume: totalPutVolume)
        let oiPcr = OptionsGreeksCalculator.shared.calculateOIPCR(callOI: totalCallOI, putOI: totalPutOI)
        let maxPain = OptionsGreeksCalculator.shared.calculateMaxPain(optionsChain: self)
        let skew = OptionsGreeksCalculator.shared.calculateSkew(optionsChain: self)

        return OptionsChainMetrics(
            pcr: pcr,
            oiPcr: oiPcr,
            maxPain: maxPain,
            skew: skew,
            totalCallOI: totalCallOI,
            totalPutOI: totalPutOI,
            totalCallVolume: totalCallVolume,
            totalPutVolume: totalPutVolume
        )
    }
}

extension NIFTYOptionContract {
    func calculateGreeks(underlyingPrice: Double, riskFreeRate: Double = 0.06) -> OptionGreeks {
        return OptionsGreeksCalculator.shared.calculateGreeks(for: self, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate)
    }
}
