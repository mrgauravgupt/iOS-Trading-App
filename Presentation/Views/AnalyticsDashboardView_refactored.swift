// This is a partial refactoring to replace the mock data generation methods
// with real data fetching methods

// Replace the mock risk data generation with real data fetching
func loadRiskData(for timeframe: AnalyticsTimeframe) {
    Task {
        do {
            // Use the analytics service to fetch real risk data
            let riskData = try await analyticsService.fetchRiskMetrics(for: timeframe)
            
            // Update the UI with real data
            DispatchQueue.main.async {
                self.var95 = riskData.var95
                self.var99 = riskData.var99
                self.var999 = riskData.var999
                self.expectedShortfall = riskData.expectedShortfall
                
                self.crisis2008Loss = riskData.scenarioAnalysis.crisis2008Loss
                self.crisis2008Probability = riskData.scenarioAnalysis.crisis2008Probability
                self.covidCrashLoss = riskData.scenarioAnalysis.covidCrashLoss
                self.covidCrashProbability = riskData.scenarioAnalysis.covidCrashProbability
                self.techBubbleLoss = riskData.scenarioAnalysis.techBubbleLoss
                self.techBubbleProbability = riskData.scenarioAnalysis.techBubbleProbability
                self.rateShockLoss = riskData.scenarioAnalysis.rateShockLoss
                self.rateShockProbability = riskData.scenarioAnalysis.rateShockProbability
                
                self.correlationMatrix = riskData.correlationMatrix
                
                // Update other risk metrics
                self.drawdownHistory = riskData.drawdownHistory
                self.maxDrawdown = riskData.maxDrawdown
                self.averageDrawdown = riskData.averageDrawdown
                self.averageRecoveryDays = riskData.averageRecoveryDays
                
                self.dailyLoss = riskData.riskLimits.dailyLoss
                self.dailyLossLimit = riskData.riskLimits.dailyLossLimit
                self.portfolioVar = riskData.riskLimits.portfolioVar
                self.portfolioVarLimit = riskData.riskLimits.portfolioVarLimit
                self.maxPositionSize = riskData.riskLimits.maxPositionSize
                self.maxPositionLimit = riskData.riskLimits.maxPositionLimit
                self.maxSectorExposure = riskData.riskLimits.maxSectorExposure
                self.maxSectorLimit = riskData.riskLimits.maxSectorLimit
            }
        } catch {
            logger.error("Failed to load risk data: \(error.localizedDescription)")
            // Handle error - perhaps show an error message to the user
            DispatchQueue.main.async {
                self.showErrorAlert(message: "Failed to load risk data: \(error.localizedDescription)")
            }
        }
    }
}

// Replace the mock insights data generation with real data fetching
func loadInsightsData(for timeframe: AnalyticsTimeframe) {
    Task {
        do {
            // Use the analytics service to fetch real insights data
            let insightsData = try await analyticsService.fetchTradingInsights(for: timeframe)
            
            // Update the UI with real data
            DispatchQueue.main.async {
                // Pattern performance metrics
                self.bullishEngulfingAccuracy = insightsData.patternPerformance.bullishEngulfing.accuracy
                self.bullishEngulfingSignals = insightsData.patternPerformance.bullishEngulfing.signals
                self.bullishEngulfingProfitable = insightsData.patternPerformance.bullishEngulfing.profitable
                
                self.bearishEngulfingAccuracy = insightsData.patternPerformance.bearishEngulfing.accuracy
                self.bearishEngulfingSignals = insightsData.patternPerformance.bearishEngulfing.signals
                self.bearishEngulfingProfitable = insightsData.patternPerformance.bearishEngulfing.profitable
                
                self.doubleBottomAccuracy = insightsData.patternPerformance.doubleBottom.accuracy
                self.doubleBottomSignals = insightsData.patternPerformance.doubleBottom.signals
                self.doubleBottomProfitable = insightsData.patternPerformance.doubleBottom.profitable
                
                self.headShouldersAccuracy = insightsData.patternPerformance.headShoulders.accuracy
                self.headShouldersSignals = insightsData.patternPerformance.headShoulders.signals
                self.headShouldersProfitable = insightsData.patternPerformance.headShoulders.profitable
                
                // Model performance metrics
                self.modelAccuracy = insightsData.modelPerformance.accuracy
                self.modelPrecision = insightsData.modelPerformance.precision
                self.modelRecall = insightsData.modelPerformance.recall
                self.modelF1Score = insightsData.modelPerformance.f1Score
                self.modelAUC = insightsData.modelPerformance.auc
                
                // Learning progress and recommendations
                self.learningProgress = insightsData.learningProgress
                self.recentImprovements = insightsData.recentImprovements
                
                self.portfolioRecommendation = insightsData.recommendations.portfolio.text
                self.portfolioConfidence = insightsData.recommendations.portfolio.confidence
                self.riskRecommendation = insightsData.recommendations.risk.text
                self.riskConfidence = insightsData.recommendations.risk.confidence
                self.strategyRecommendation = insightsData.recommendations.strategy.text
                self.strategyConfidence = insightsData.recommendations.strategy.confidence
            }
        } catch {
            logger.error("Failed to load insights data: \(error.localizedDescription)")
            // Handle error - perhaps show an error message to the user
            DispatchQueue.main.async {
                self.showErrorAlert(message: "Failed to load insights data: \(error.localizedDescription)")
            }
        }
    }
}
