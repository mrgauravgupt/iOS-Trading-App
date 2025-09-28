import Foundation

/// Configuration for analytics and risk management values
public struct AnalyticsConfig {
    /// Risk analytics configuration
    public static let risk = RiskConfig()
    
    /// AI insights configuration
    public static let ai = AIConfig()
    
    public struct RiskConfig {
        /// Value at Risk levels (in INR)
        public let var95: Double = 25000.0
        public let var99: Double = 45000.0
        public let var999: Double = 75000.0
        public let expectedShortfall: Double = 55000.0
        
        /// Stress test losses (in INR)
        public let crisis2008Loss: Double = 85000.0
        public let crisis2008Probability: Double = 0.05
        public let covidCrashLoss: Double = 65000.0
        public let covidCrashProbability: Double = 0.08
        public let techBubbleLoss: Double = 55000.0
        public let techBubbleProbability: Double = 0.03
        public let rateShockLoss: Double = 35000.0
        public let rateShockProbability: Double = 0.12
        
        /// Drawdown statistics
        public let maxDrawdown: Double = 0.12
        public let averageDrawdown: Double = 0.045
        public let averageRecoveryDays: Int = 18
        
        /// Risk limits
        public let dailyLossLimit: Double = 15000.0
        public let portfolioVarLimit: Double = 35000.0
        public let maxPositionLimit: Double = 15.0
        public let maxSectorLimit: Double = 30.0
        
        /// Correlation matrix sample data
        let correlationMatrix: [CorrelationData] = [
            CorrelationData(asset1: "NIFTY", asset2: "NIFTY", value: 1.0),
            CorrelationData(asset1: "NIFTY", asset2: "BANKNIFTY", value: 0.75),
            CorrelationData(asset1: "NIFTY", asset2: "TECH", value: 0.82),
            CorrelationData(asset1: "NIFTY", asset2: "FINANCE", value: 0.68),
            CorrelationData(asset1: "BANKNIFTY", asset2: "NIFTY", value: 0.75),
            CorrelationData(asset1: "BANKNIFTY", asset2: "BANKNIFTY", value: 1.0),
            CorrelationData(asset1: "BANKNIFTY", asset2: "TECH", value: 0.45),
            CorrelationData(asset1: "BANKNIFTY", asset2: "FINANCE", value: 0.89),
            CorrelationData(asset1: "TECH", asset2: "NIFTY", value: 0.82),
            CorrelationData(asset1: "TECH", asset2: "BANKNIFTY", value: 0.45),
            CorrelationData(asset1: "TECH", asset2: "TECH", value: 1.0),
            CorrelationData(asset1: "TECH", asset2: "FINANCE", value: 0.52),
            CorrelationData(asset1: "FINANCE", asset2: "NIFTY", value: 0.68),
            CorrelationData(asset1: "FINANCE", asset2: "BANKNIFTY", value: 0.89),
            CorrelationData(asset1: "FINANCE", asset2: "TECH", value: 0.52),
            CorrelationData(asset1: "FINANCE", asset2: "FINANCE", value: 1.0)
        ]
        
        /// Drawdown history generator
        func generateDrawdownHistory(startDate: Date, endDate: Date) -> [DrawdownData] {
            let calendar = Calendar.current
            var currentDate = startDate
            var drawdowns: [DrawdownData] = []
            
            while currentDate <= endDate {
                let drawdown = Double.random(in: -0.15...0.0)
                drawdowns.append(DrawdownData(date: currentDate, percentage: drawdown))
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            return drawdowns
        }
    }
    
    public struct AIConfig {
        /// Pattern recognition accuracies
        public let bullishEngulfingAccuracy: Double = 0.68
        public let bearishEngulfingAccuracy: Double = 0.72
        public let doubleBottomAccuracy: Double = 0.61
        public let headShouldersAccuracy: Double = 0.75
        
        /// Pattern signal counts
        public let bullishEngulfingSignals: Int = 45
        public let bearishEngulfingSignals: Int = 38
        public let doubleBottomSignals: Int = 23
        public let headShouldersSignals: Int = 16
        
        /// Model metrics
        public let modelPrecision: Double = 0.69
        public let modelRecall: Double = 0.65
        public let modelF1Score: Double = 0.67
        public let modelAUC: Double = 0.734
        
        /// Overall accuracies
        public let overallAccuracy: Double = 0.67
        public let bullPredictionAccuracy: Double = 0.71
        public let bearPredictionAccuracy: Double = 0.63
        
        /// Trends
        public let accuracyTrend: Double = 2.3
        public let bullAccuracyTrend: Double = 1.8
        public let bearAccuracyTrend: Double = -0.5
        
        /// Learning progress generator
        func generatePredictionAccuracyHistory(startDate: Date, endDate: Date) -> [PredictionAccuracyData] {
            let calendar = Calendar.current
            var currentDate = startDate
            var accuracies: [PredictionAccuracyData] = []
            
            while currentDate <= endDate {
                let accuracy = Double.random(in: 0.55...0.75)
                accuracies.append(PredictionAccuracyData(date: currentDate, accuracy: accuracy))
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            return accuracies
        }
        
        func generateLearningProgress(startDate: Date, endDate: Date) -> [LearningProgressData] {
            let calendar = Calendar.current
            var currentDate = startDate
            var progress: [LearningProgressData] = []
            
            while currentDate <= endDate {
                let accuracy = Double.random(in: 0.60...0.75)
                let f1Score = Double.random(in: 0.62...0.72)
                progress.append(LearningProgressData(date: currentDate, accuracy: accuracy, f1Score: f1Score))
                currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
            }
            
            return progress
        }
        
        /// Recent improvements
        public let recentImprovements: [String] = [
            "Improved pattern recognition accuracy by 3.2%",
            "Enhanced feature engineering for better signal quality",
            "Optimized model hyperparameters for reduced overfitting",
            "Added sentiment analysis integration for market context"
        ]
        
        /// Recommendations
        public let portfolioRecommendation: String = "Consider increasing allocation to Technology sector based on momentum analysis and reduce exposure to cyclical sectors."
        public let portfolioConfidence: Double = 0.82
        public let riskRecommendation: String = "Current portfolio volatility is within acceptable limits. Consider implementing trailing stop losses for large positions."
        public let riskConfidence: Double = 0.78
        public let strategyRecommendation: String = "Switch to momentum-based strategies during high volatility periods. Current mean-reversion approach showing reduced effectiveness."
        public let strategyConfidence: Double = 0.71
    }
}
