import Foundation

// MARK: - Implied Volatility Analyzer

class ImpliedVolatilityAnalyzer {
    static let shared = ImpliedVolatilityAnalyzer()

    private let greeksCalculator = OptionsGreeksCalculator.shared

    // MARK: - IV Calculation Methods

    /// Calculate implied volatility for a single option
    func calculateIV(for contract: NIFTYOptionContract, underlyingPrice: Double, riskFreeRate: Double = 0.06, dividendYield: Double = 0.0) -> Double? {
        return greeksCalculator.calculateImpliedVolatility(
            optionPrice: contract.currentPrice,
            S: underlyingPrice,
            K: contract.strikePrice,
            T: timeToExpiry(from: contract.expiryDate),
            r: riskFreeRate,
            q: dividendYield,
            isCall: contract.optionType == .call
        )
    }

    /// Calculate IV for entire options chain
    func calculateIVForChain(_ chain: NIFTYOptionsChain, underlyingPrice: Double, riskFreeRate: Double = 0.06) -> IVChainAnalysis {
        var callIVs: [Double] = []
        var putIVs: [Double] = []
        var strikes: [Double] = []

        // Calculate IV for calls
        for call in chain.callOptions {
            if let iv = calculateIV(for: call, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate) {
                callIVs.append(iv)
                if !strikes.contains(call.strikePrice) {
                    strikes.append(call.strikePrice)
                }
            }
        }

        // Calculate IV for puts
        for put in chain.putOptions {
            if let iv = calculateIV(for: put, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate) {
                putIVs.append(iv)
                if !strikes.contains(put.strikePrice) {
                    strikes.append(put.strikePrice)
                }
            }
        }

        strikes.sort()

        let avgCallIV = callIVs.isEmpty ? 0 : callIVs.reduce(0, +) / Double(callIVs.count)
        let avgPutIV = putIVs.isEmpty ? 0 : putIVs.reduce(0, +) / Double(putIVs.count)
        let avgIV = (avgCallIV + avgPutIV) / 2

        let atmIV = calculateATMIV(chain: chain, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate)
        let ivSkew = calculateIVSkew(callIVs: callIVs, putIVs: putIVs, strikes: strikes, atmStrike: chain.getATMStrike())
        let ivTermStructure = calculateIVTermStructure(chain: chain, underlyingPrice: underlyingPrice)
        let ivSurface = calculateIVSurface(chain: chain, underlyingPrice: underlyingPrice)

        return IVChainAnalysis(
            averageIV: avgIV,
            atmIV: atmIV,
            callIV: avgCallIV,
            putIV: avgPutIV,
            ivSkew: ivSkew,
            termStructure: ivTermStructure,
            volatilitySurface: ivSurface,
            strikes: strikes.sorted(),
            callIVs: callIVs,
            putIVs: putIVs
        )
    }

    /// Calculate ATM implied volatility
    private func calculateATMIV(chain: NIFTYOptionsChain, underlyingPrice: Double, riskFreeRate: Double) -> Double {
        let atmStrike = chain.getATMStrike()

        guard let atmCall = chain.callOptions.first(where: { $0.strikePrice == atmStrike }),
              let atmPut = chain.putOptions.first(where: { $0.strikePrice == atmStrike }) else {
            return 0
        }

        let callIV = calculateIV(for: atmCall, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate) ?? 0
        let putIV = calculateIV(for: atmPut, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate) ?? 0

        return (callIV + putIV) / 2
    }

    /// Calculate IV skew (difference between call and put IVs)
    private func calculateIVSkew(callIVs: [Double], putIVs: [Double], strikes: [Double], atmStrike: Double) -> Double {
        guard !callIVs.isEmpty && !putIVs.isEmpty else { return 0 }

        let avgCallIV = callIVs.reduce(0, +) / Double(callIVs.count)
        let avgPutIV = putIVs.reduce(0, +) / Double(putIVs.count)

        return avgCallIV - avgPutIV
    }

    /// Calculate IV term structure across different expiries
    private func calculateIVTermStructure(chain: NIFTYOptionsChain, underlyingPrice: Double) -> [IVTermPoint] {
        let expiries = Set(chain.callOptions.map { $0.expiryDate }).sorted()

        return expiries.compactMap { expiry in
            let calls = chain.callOptions.filter { $0.expiryDate == expiry }
            let puts = chain.putOptions.filter { $0.expiryDate == expiry }

            let atmStrike = chain.getATMStrike()
            guard let atmCall = calls.first(where: { $0.strikePrice == atmStrike }),
                  let atmPut = puts.first(where: { $0.strikePrice == atmStrike }) else {
                return nil
            }

            let callIV = calculateIV(for: atmCall, underlyingPrice: underlyingPrice) ?? 0
            let putIV = calculateIV(for: atmPut, underlyingPrice: underlyingPrice) ?? 0
            let avgIV = (callIV + putIV) / 2

            return IVTermPoint(
                expiryDate: expiry,
                daysToExpiry: Int(expiry.timeIntervalSince(Date()) / (24 * 3600)),
                impliedVolatility: avgIV
            )
        }
    }

    /// Calculate volatility surface (IV vs strike vs time)
    private func calculateIVSurface(chain: NIFTYOptionsChain, underlyingPrice: Double) -> IVSurface {
        let expiries = Set(chain.callOptions.map { $0.expiryDate }).sorted()
        var surfacePoints: [IVSurfacePoint] = []

        for expiry in expiries {
            let calls = chain.callOptions.filter { $0.expiryDate == expiry }
            let puts = chain.putOptions.filter { $0.expiryDate == expiry }

            for call in calls {
                if let iv = calculateIV(for: call, underlyingPrice: underlyingPrice) {
                    surfacePoints.append(IVSurfacePoint(
                        strike: call.strikePrice,
                        timeToExpiry: timeToExpiry(from: expiry),
                        impliedVolatility: iv,
                        optionType: .call
                    ))
                }
            }

            for put in puts {
                if let iv = calculateIV(for: put, underlyingPrice: underlyingPrice) {
                    surfacePoints.append(IVSurfacePoint(
                        strike: put.strikePrice,
                        timeToExpiry: timeToExpiry(from: expiry),
                        impliedVolatility: iv,
                        optionType: .put
                    ))
                }
            }
        }

        return IVSurface(points: surfacePoints)
    }

    // MARK: - IV Analysis Methods

    /// Analyze IV percentile (how high/low current IV is historically)
    func calculateIVPercentile(currentIV: Double, historicalIVs: [Double]) -> Double {
        guard !historicalIVs.isEmpty else { return 0 }

        let sortedIVs = historicalIVs.sorted()
        let count = sortedIVs.count

        // Find how many historical IVs are below current IV
        var belowCount = 0
        for iv in sortedIVs {
            if iv < currentIV {
                belowCount += 1
            } else {
                break
            }
        }

        return Double(belowCount) / Double(count)
    }

    /// Calculate IV Rank (simplified version)
    func calculateIVRank(currentIV: Double, historicalIVs: [Double], lookbackDays: Int = 30) -> Double {
        guard historicalIVs.count >= lookbackDays else {
            return calculateIVPercentile(currentIV: currentIV, historicalIVs: historicalIVs)
        }

        let recentIVs = Array(historicalIVs.suffix(lookbackDays))
        return calculateIVPercentile(currentIV: currentIV, historicalIVs: recentIVs)
    }

    /// Detect IV spikes or drops
    func detectIVChanges(currentIV: Double, previousIV: Double, threshold: Double = 0.05) -> IVChangeType {
        let change = (currentIV - previousIV) / previousIV

        if change > threshold {
            return .spike
        } else if change < -threshold {
            return .drop
        } else {
            return .stable
        }
    }

    /// Calculate IV Crush potential
    func calculateIVCrushPotential(chain: NIFTYOptionsChain, underlyingPrice: Double) -> Double {
        let analysis = calculateIVForChain(chain, underlyingPrice: underlyingPrice)

        // IV crush potential is higher when:
        // 1. Current IV is high
        // 2. Time to expiry is short
        // 3. Options are near expiration

        let avgIV = analysis.averageIV
        let daysToExpiry = chain.expiryDate.timeIntervalSince(Date()) / (24 * 3600)

        // Simple crush potential score (0-1)
        let ivComponent = min(avgIV / 0.8, 1.0) // Normalize high IV
        let timeComponent = 1.0 - min(daysToExpiry / 30.0, 1.0) // Closer to expiry = higher risk

        return (ivComponent + timeComponent) / 2
    }

    // MARK: - Helper Methods

    private func timeToExpiry(from expiryDate: Date) -> Double {
        let now = Date()
        let timeInterval = expiryDate.timeIntervalSince(now)
        return max(timeInterval / (365 * 24 * 3600), 0) // Convert to years
    }
}

// MARK: - Supporting Structures

struct IVChainAnalysis {
    let averageIV: Double
    let atmIV: Double
    let callIV: Double
    let putIV: Double
    let ivSkew: Double
    let termStructure: [IVTermPoint]
    let volatilitySurface: IVSurface
    let strikes: [Double]
    let callIVs: [Double]
    let putIVs: [Double]

    var description: String {
        return String(format: "Avg IV: %.1f%%, ATM IV: %.1f%%, Skew: %.1f%%",
                      averageIV * 100, atmIV * 100, ivSkew * 100)
    }
}

struct IVTermPoint {
    let expiryDate: Date
    let daysToExpiry: Int
    let impliedVolatility: Double
}

struct IVSurface {
    let points: [IVSurfacePoint]

    func getIVForStrike(_ strike: Double, timeToExpiry: Double) -> Double? {
        // Simple interpolation - in production, use bilinear interpolation
        let nearbyPoints = points.filter {
            abs($0.strike - strike) < 100 && abs($0.timeToExpiry - timeToExpiry) < 0.1
        }

        guard !nearbyPoints.isEmpty else { return nil }

        return nearbyPoints.map { $0.impliedVolatility }.reduce(0, +) / Double(nearbyPoints.count)
    }
}

struct IVSurfacePoint {
    let strike: Double
    let timeToExpiry: Double
    let impliedVolatility: Double
    let optionType: OptionType
}

enum IVChangeType {
    case spike
    case drop
    case stable

    var description: String {
        switch self {
        case .spike: return "IV Spike"
        case .drop: return "IV Drop"
        case .stable: return "Stable"
        }
    }
}

struct IVAnalytics {
    let currentIV: Double
    let percentile: Double
    let rank: Double
    let changeType: IVChangeType
    let crushPotential: Double
    let skew: Double
    let termStructureSlope: Double

    var marketCondition: String {
        if percentile > 0.8 {
            return "High Volatility"
        } else if percentile < 0.2 {
            return "Low Volatility"
        } else {
            return "Normal Volatility"
        }
    }
}

// MARK: - Extensions

extension NIFTYOptionsChain {
    func analyzeIV(underlyingPrice: Double) -> IVChainAnalysis {
        return ImpliedVolatilityAnalyzer.shared.calculateIVForChain(self, underlyingPrice: underlyingPrice)
    }
}

extension NIFTYOptionContract {
    func calculateIV(underlyingPrice: Double, riskFreeRate: Double = 0.06) -> Double? {
        return ImpliedVolatilityAnalyzer.shared.calculateIV(for: self, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate)
    }
}
