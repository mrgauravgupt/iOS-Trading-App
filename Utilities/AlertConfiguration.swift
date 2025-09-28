import Foundation
import SharedCoreModels

// MARK: - Alert Types and Conditions

enum AlertType: String, Codable, CaseIterable {
    case price = "price"
    case volume = "volume"
    case pattern = "pattern"
    case news = "news"
    case risk = "risk"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .price: return "Price Alert"
        case .volume: return "Volume Alert"
        case .pattern: return "Pattern Alert"
        case .news: return "News Alert"
        case .risk: return "Risk Alert"
        case .custom: return "Custom Alert"
        }
    }
}

enum AlertCondition: String, Codable, CaseIterable {
    case above = "above"
    case below = "below"
    case equals = "equals"
    case crossesAbove = "crosses_above"
    case crossesBelow = "crosses_below"
    case percentageChange = "percentage_change"
    case volumeSpike = "volume_spike"
    case patternDetected = "pattern_detected"
    case newsSentiment = "news_sentiment"
    case riskThreshold = "risk_threshold"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .above: return "Above"
        case .below: return "Below"
        case .equals: return "Equals"
        case .crossesAbove: return "Crosses Above"
        case .crossesBelow: return "Crosses Below"
        case .percentageChange: return "Percentage Change"
        case .volumeSpike: return "Volume Spike"
        case .patternDetected: return "Pattern Detected"
        case .newsSentiment: return "News Sentiment"
        case .riskThreshold: return "Risk Threshold"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Alert Configuration Model

struct AlertConfiguration: Codable, Identifiable {
    var id = UUID()
    var name: String
    var type: AlertType
    var condition: AlertCondition
    var symbol: String
    var threshold: Double
    var priority: AlertPriority
    var isEnabled: Bool = true
    var notificationEnabled: Bool = true
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var createdAt: Date = Date()
    var lastTriggered: Date?

    // Custom parameters for specific alert types
    var customParameters: [String: AnyCodable] = [:]

    // Computed properties
    var isActive: Bool {
        isEnabled && (lastTriggered == nil || Date().timeIntervalSince(lastTriggered!) > 300) // 5 min cooldown
    }

    var description: String {
        "\(type.displayName): \(condition.displayName) \(threshold) for \(symbol)"
    }
}

// MARK: - Helper Types

struct AnyCodable: Codable {
    private let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary
        } else {
            self.value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [AnyCodable]:
            try container.encode(array)
        case let dictionary as [String: AnyCodable]:
            try container.encode(dictionary)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Alert History

struct AlertHistory: Codable, Identifiable {
    var id = UUID()
    var alertId: UUID
    var triggeredAt: Date
    var message: String
    var symbol: String
    var value: Double
    var threshold: Double
    var condition: AlertCondition
    var priority: AlertPriority
    var wasAcknowledged: Bool = false
    var acknowledgedAt: Date?
}

// MARK: - Alert Manager Configuration

struct AlertManagerConfig: Codable {
    var maxAlertsPerDay: Int = 50
    var cooldownPeriod: TimeInterval = 300 // 5 minutes
    var enableGrouping: Bool = true
    var groupTimeWindow: TimeInterval = 60 // 1 minute
    var enableSmartFiltering: Bool = true
    var noiseThreshold: Double = 0.1 // Filter alerts with <10% significance
}
