import Foundation
import Combine

// MARK: - Alert Engine

class AlertEngine: ObservableObject {
    static let shared = AlertEngine()

    @Published var activeAlerts: [AlertConfiguration] = []
    @Published var alertHistory: [AlertHistory] = []
    @Published var isMonitoring = false

    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var debounceTimers: [UUID: Timer] = [:]
    private var lastTriggerTimes: [UUID: Date] = [:]

    private let config: AlertManagerConfig
    private let persistenceKey = "alertConfigurations"
    private let historyKey = "alertHistory"

    private init() {
        self.config = AlertManagerConfig()
        loadAlerts()
        loadHistory()
    }

    // MARK: - Alert Management

    func addAlert(_ alert: AlertConfiguration) {
        activeAlerts.append(alert)
        saveAlerts()
    }

    func updateAlert(_ alert: AlertConfiguration) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alert.id }) {
            activeAlerts[index] = alert
            saveAlerts()
        }
    }

    func removeAlert(_ alert: AlertConfiguration) {
        activeAlerts.removeAll { $0.id == alert.id }
        saveAlerts()
    }

    func enableAlert(_ alert: AlertConfiguration) {
        updateAlert(alert.with(\.isEnabled, true))
    }

    func disableAlert(_ alert: AlertConfiguration) {
        updateAlert(alert.with(\.isEnabled, false))
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAlerts()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        debounceTimers.values.forEach { $0.invalidate() }
        debounceTimers.removeAll()
    }

    private func checkAlerts() {
        let activeAlerts = self.activeAlerts.filter { $0.isActive }

        for alert in activeAlerts {
            checkAlert(alert)
        }
    }

    private func checkAlert(_ alert: AlertConfiguration) {
        // Debounce check
        let alertId = alert.id
        if let lastCheck = lastTriggerTimes[alertId],
           Date().timeIntervalSince(lastCheck) < config.cooldownPeriod {
            return
        }

        // Get current market data for the symbol
        // This would typically come from a data provider
        getCurrentValue(for: alert.symbol) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let currentValue):
                if self.evaluateCondition(alert.condition, currentValue: currentValue, threshold: alert.threshold) {
                    self.triggerAlert(alert, value: currentValue)
                }
            case .failure(let error):
                print("Failed to get value for \(alert.symbol): \(error.localizedDescription)")
            }
        }
    }

    private func evaluateCondition(_ condition: AlertCondition, currentValue: Double, threshold: Double) -> Bool {
        switch condition {
        case .above:
            return currentValue > threshold
        case .below:
            return currentValue < threshold
        case .equals:
            return abs(currentValue - threshold) < 0.01 // Small tolerance
        case .crossesAbove:
            // Would need previous value to detect crossing
            return currentValue > threshold
        case .crossesBelow:
            return currentValue < threshold
        case .percentageChange:
            // Would need previous value for percentage calculation
            return abs(currentValue - threshold) / threshold > 0.01 // 1% change
        case .volumeSpike:
            // Volume-specific logic
            return currentValue > threshold * 2 // Simple spike detection
        case .patternDetected:
            // Pattern detection logic would go here
            return false // Placeholder
        case .newsSentiment:
            // News sentiment analysis
            return currentValue > threshold
        case .riskThreshold:
            // Risk calculation
            return currentValue > threshold
        case .custom:
            // Custom evaluation logic
            return evaluateCustomCondition(currentValue: currentValue, threshold: threshold)
        }
    }

    private func evaluateCustomCondition(currentValue: Double, threshold: Double) -> Bool {
        // Placeholder for custom logic
        return currentValue > threshold
    }

    private func triggerAlert(_ alert: AlertConfiguration, value: Double) {
        let alertId = alert.id

        // Debounce triggering
        if let timer = debounceTimers[alertId] {
            timer.invalidate()
        }

        debounceTimers[alertId] = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.debounceTimers[alertId] = nil
            self.lastTriggerTimes[alertId] = Date()

            // Create history entry
            let history = AlertHistory(
                alertId: alert.id,
                triggeredAt: Date(),
                message: "\(alert.name) triggered: \(alert.symbol) \(alert.condition.displayName.lowercased()) \(alert.threshold)",
                symbol: alert.symbol,
                value: value,
                threshold: alert.threshold,
                condition: alert.condition,
                priority: alert.priority
            )

            self.alertHistory.insert(history, at: 0)
            self.saveHistory()

            // Update alert last triggered
            var updatedAlert = alert
            updatedAlert.lastTriggered = Date()
            self.updateAlert(updatedAlert)

            // Send notifications
            self.sendNotification(for: alert, history: history)

            // Limit history size
            if self.alertHistory.count > 1000 {
                self.alertHistory = Array(self.alertHistory.prefix(1000))
                self.saveHistory()
            }
        }
    }

    // MARK: - Notifications

    private func sendNotification(for alert: AlertConfiguration, history: AlertHistory) {
        guard alert.notificationEnabled else { return }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "\(alert.priority.displayName.capitalized) Alert"
        content.body = history.message
        content.sound = alert.soundEnabled ? .default : nil
        content.userInfo = ["alertId": alert.id.uuidString]

        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // Create request
        let request = UNNotificationRequest(identifier: history.id.uuidString, content: content, trigger: trigger)

        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }

        // Haptic feedback
        if alert.vibrationEnabled {
            triggerHapticFeedback(for: alert.priority)
        }
    }

    private func triggerHapticFeedback(for priority: AlertPriority) {
        let generator: UINotificationFeedbackGenerator
        switch priority {
        case .low, .medium:
            generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .high:
            generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .critical:
            generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    // MARK: - Data Access

    private func getCurrentValue(for symbol: String, completion: @escaping (Result<Double, Error>) -> Void) {
        // This would integrate with your data providers
        // For now, return a mock value
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            // Mock implementation - replace with actual data provider call
            let mockValue = Double.random(in: 18000...20000) // Mock NIFTY value
            completion(.success(mockValue))
        }
    }

    // MARK: - Persistence

    private func saveAlerts() {
        do {
            let data = try JSONEncoder().encode(activeAlerts)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("Failed to save alerts: \(error.localizedDescription)")
        }
    }

    private func loadAlerts() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            activeAlerts = try JSONDecoder().decode([AlertConfiguration].self, from: data)
        } catch {
            print("Failed to load alerts: \(error.localizedDescription)")
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(alertHistory)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save alert history: \(error.localizedDescription)")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        do {
            alertHistory = try JSONDecoder().decode([AlertHistory].self, from: data)
        } catch {
            print("Failed to load alert history: \(error.localizedDescription)")
        }
    }

    // MARK: - Cleanup

    func clearHistory() {
        alertHistory.removeAll()
        saveHistory()
    }

    func clearOldHistory(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        alertHistory.removeAll { $0.triggeredAt < cutoffDate }
        saveHistory()
    }
}

// MARK: - Helper Extensions

extension AlertConfiguration {
    func with<T>(_ keyPath: WritableKeyPath<AlertConfiguration, T>, _ value: T) -> AlertConfiguration {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}
