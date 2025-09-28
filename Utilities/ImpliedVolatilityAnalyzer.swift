import Foundation
import SharedCoreModels

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
            termStructure: ivTermStructure.map { $0.atmIV },
            volatilitySurface: ivSurface.points.map { [$0.strike, $0.timeToExpiry, $0.impliedVolatility] },
            strikes: strikes.sorted(),
            callIVs: callIVs,
            putIVs: putIVs
        )
    }

    /// Calculate ATM implied volatility
    private func calculateATMIV(chain: NIFTYOptionsChain, underlyingPrice: Double, riskFreeRate: Double) -> Double {
        let atmStrike = chain.getATMStrike()

        if let atmCall = chain.callOptions.first(where: { $0.strikePrice == atmStrike }),
           let atmCallIV = calculateIV(for: atmCall, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate) {
            return atmCallIV
        } else if let atmPut = chain.putOptions.first(where: { $0.strikePrice == atmStrike }),
                  let atmPutIV = calculateIV(for: atmPut, underlyingPrice: underlyingPrice, riskFreeRate: riskFreeRate) {
            return atmPutIV
        } else {
            return 0
        }
    }

    /// Calculate IV skew
    private func calculateIVSkew(callIVs: [Double], putIVs: [Double], strikes: [Double], atmStrike: Double) -> Double {
        guard !callIVs.isEmpty, !putIVs.isEmpty else { return 0 }

        let atmIndex = strikes.firstIndex(of: atmStrike) ?? strikes.count / 2
        let atmCallIV = callIVs[atmIndex]
        let atmPutIV = putIVs[atmIndex]

        return atmCallIV - atmPutIV
    }

    /// Calculate IV term structure
    private func calculateIVTermStructure(chain: NIFTYOptionsChain, underlyingPrice: Double) -> [IVTermPoint] {
        // Get unique expiry dates from both call and put options
        let callExpiries = Set(chain.callOptions.map { $0.expiryDate })
        let putExpiries = Set(chain.putOptions.map { $0.expiryDate })
        let allExpiries = callExpiries.union(putExpiries).sorted()
        
        var termStructurePoints: [IVTermPoint] = []

        for expiry in allExpiries {
            let calls = chain.callOptions.filter { $0.expiryDate == expiry }
            let puts = chain.putOptions.filter { $0.expiryDate == expiry }

            var atmIV: Double = 0
            
            // Calculate ATM IV for this expiry
            let atmStrike = chain.getATMStrike()
            if let atmCall = calls.first(where: { $0.strikePrice == atmStrike }),
               let atmPut = puts.first(where: { $0.strikePrice == atmStrike }),
               let atmCallIV = calculateIV(for: atmCall, underlyingPrice: underlyingPrice),
               let atmPutIV = calculateIV(for: atmPut, underlyingPrice: underlyingPrice) {
                atmIV = (atmCallIV + atmPutIV) / 2
            } else if let atmCall = calls.first(where: { $0.strikePrice == atmStrike }),
                      let atmCallIV = calculateIV(for: atmCall, underlyingPrice: underlyingPrice) {
                atmIV = atmCallIV
            } else if let atmPut = puts.first(where: { $0.strikePrice == atmStrike }),
                      let atmPutIV = calculateIV(for: atmPut, underlyingPrice: underlyingPrice) {
                atmIV = atmPutIV
            }

            termStructurePoints.append(IVTermPoint(
                expiryDate: expiry,
                daysToExpiry: Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0,
                atmIV: atmIV
            ))
        }

        return termStructurePoints
    }

    /// Calculate volatility surface for options analysis
    func calculateVolatilitySurface(chain: NIFTYOptionsChain, underlyingPrice: Double) -> VolatilitySurface {
        let ivSurface = calculateIVSurface(chain: chain, underlyingPrice: underlyingPrice)
        let volatilityPoints = ivSurface.points.map { point in
            VolatilitySurfacePoint(
                strike: point.strike,
                timeToExpiry: point.timeToExpiry,
                impliedVolatility: point.impliedVolatility,
                optionType: point.optionType
            )
        }
        return VolatilitySurface(points: volatilityPoints)
    }

    /// Calculate IV surface
    private func calculateIVSurface(chain: NIFTYOptionsChain, underlyingPrice: Double) -> IVSurface {
        var surfacePoints: [IVSurfacePoint] = []
        
        // Get unique expiry dates from both call and put options
        let callExpiries = Set(chain.callOptions.map { $0.expiryDate })
        let putExpiries = Set(chain.putOptions.map { $0.expiryDate })
        let allExpiries = callExpiries.union(putExpiries).sorted()

        for expiry in allExpiries {
            let calls = chain.callOptions.filter { $0.expiryDate == expiry }
            let puts = chain.putOptions.filter { $0.expiryDate == expiry }

            for call in calls {
                if let iv = calculateIV(for: call, underlyingPrice: underlyingPrice) {
                    surfacePoints.append(IVSurfacePoint(
                        strike: call.strikePrice,
                        timeToExpiry: timeToExpiry(from: expiry),
                        impliedVolatility: iv,
                        optionType: OptionType.call
                    ))
                }
            }

            for put in puts {
                if let iv = calculateIV(for: put, underlyingPrice: underlyingPrice) {
                    surfacePoints.append(IVSurfacePoint(
                        strike: put.strikePrice,
                        timeToExpiry: timeToExpiry(from: expiry),
                        impliedVolatility: iv,
                        optionType: OptionType.put
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

// Removed duplicate struct definitions - now in SharedModels.swift

// MARK: - Helper Extensions

extension Array where Element == IVPoint {
    func interpolated(at strike: Double) -> Double? {
        guard !isEmpty else { return nil }
        
        // Find the two nearest strikes
        let sortedByStrike = sorted { $0.strike < $1.strike }
        
        // If strike is outside range, return nil
        guard strike >= sortedByStrike.first?.strike ?? 0,
              strike <= sortedByStrike.last?.strike ?? 0 else {
            return nil
        }
        
        // Find exact match or interpolate
        if let exactMatch = first(where: { $0.strike == strike }) {
            return exactMatch.iv
        }
        
        // Interpolate between two nearest points
        guard let (lower, upper) = findBoundingPoints(for: strike) else {
            return nil
        }
        
        let ratio = (strike - lower.strike) / (upper.strike - lower.strike)
        return lower.iv + (upper.iv - lower.iv) * ratio
    }
    
    private func findBoundingPoints(for strike: Double) -> (IVPoint, IVPoint)? {
        let sortedByStrike = sorted { $0.strike < $1.strike }
        
        for i in 0..<sortedByStrike.count - 1 {
            let lower = sortedByStrike[i]
            let upper = sortedByStrike[i + 1]
            
            if strike >= lower.strike && strike <= upper.strike {
                return (lower, upper)
            }
        }
        
        return nil
    }
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
