import Foundation
import UIKit
import Combine
import os.log

class AlertEngine: ObservableObject {
    // MARK: - Published Properties
    
    @Published var activeAlerts: [PriceAlert] = []
    
    // MARK: - Private Properties
    
    private let persistenceKey = "com.trading.app.priceAlerts"
    private var alertTimers: [UUID: Timer] = [:]
    private var dataProvider = NIFTYOptionsDataProvider()
    private let logger = Logger(subsystem: "com.trading.app", category: "AlertEngine")
    
    // MARK: - Initialization
    
    init() {
        loadSavedAlerts()
        setupAlertTimers()
    }
    
    // MARK: - Public Methods
    
    func addAlert(symbol: String, price: Double, direction: PriceAlertDirection, type: PriceAlertType) {
        let newAlert = PriceAlert(
            id: UUID(),
            symbol: symbol,
            targetPrice: price,
            direction: direction,
            type: type,
            createdAt: Date(),
            isActive: true
        )
        
        activeAlerts.append(newAlert)
        saveAlerts()
        setupTimerForAlert(newAlert)
        
        logger.info("Added new \(direction.rawValue) alert for \(symbol) at \(price)")
    }
    
    func removeAlert(withID id: UUID) {
        if let index = activeAlerts.firstIndex(where: { $0.id == id }) {
            let alert = activeAlerts[index]
            activeAlerts.remove(at: index)
            
            // Remove timer if exists
            if let timer = alertTimers[id] {
                timer.invalidate()
                alertTimers.removeValue(forKey: id)
            }
            
            saveAlerts()
            logger.info("Removed alert for \(alert.symbol)")
        }
    }
    
    func toggleAlert(withID id: UUID) {
        if let index = activeAlerts.firstIndex(where: { $0.id == id }) {
            activeAlerts[index].isActive.toggle()
            
            if activeAlerts[index].isActive {
                setupTimerForAlert(activeAlerts[index])
            } else if let timer = alertTimers[id] {
                timer.invalidate()
                alertTimers.removeValue(forKey: id)
            }
            
            saveAlerts()
            logger.info("Toggled alert for \(self.activeAlerts[index].symbol) to \(self.activeAlerts[index].isActive ? "active" : "inactive")")
        }
    }
    
    func clearAllAlerts() {
        // Invalidate all timers
        for (_, timer) in alertTimers {
            timer.invalidate()
        }
        alertTimers.removeAll()
        
        activeAlerts.removeAll()
        saveAlerts()
        logger.info("Cleared all alerts")
    }
    
    // MARK: - Private Methods
    
    private func setupAlertTimers() {
        for alert in activeAlerts where alert.isActive {
            setupTimerForAlert(alert)
        }
    }
    
    private func setupTimerForAlert(_ alert: PriceAlert) {
        // Cancel existing timer if any
        if let existingTimer = alertTimers[alert.id] {
            existingTimer.invalidate()
        }
        
        // Create a new timer that checks every 30 seconds
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkAlert(alert)
        }
        
        alertTimers[alert.id] = timer
    }
    
    private func checkAlert(_ alert: PriceAlert) {
        guard alert.isActive else { return }
        
        getCurrentValue(for: alert.symbol) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let currentPrice):
                let alertTriggered = self.isAlertTriggered(alert: alert, currentPrice: currentPrice)
                
                if alertTriggered {
                    self.triggerAlert(alert, currentPrice: currentPrice)
                    
                    // If it's a one-time alert, deactivate it
                    if alert.type == .oneTime {
                        DispatchQueue.main.async {
                            if let index = self.activeAlerts.firstIndex(where: { $0.id == alert.id }) {
                                self.activeAlerts[index].isActive = false
                                self.saveAlerts()
                                
                                if let timer = self.alertTimers[alert.id] {
                                    timer.invalidate()
                                    self.alertTimers.removeValue(forKey: alert.id)
                                }
                            }
                        }
                    }
                }
                
            case .failure(let error):
                self.logger.error("Failed to get current price for \(alert.symbol): \(error.localizedDescription)")
            }
        }
    }
    
    private func isAlertTriggered(alert: PriceAlert, currentPrice: Double) -> Bool {
        switch alert.direction {
        case .above:
            return currentPrice >= alert.targetPrice
        case .below:
            return currentPrice <= alert.targetPrice
        }
    }
    
    private func triggerAlert(_ alert: PriceAlert, currentPrice: Double) {
        // Create notification content
        let directionText = alert.direction == .above ? "risen above" : "fallen below"
        let title = "\(alert.symbol) Price Alert"
        let body = "\(alert.symbol) has \(directionText) ₹\(alert.targetPrice). Current price: ₹\(String(format: "%.2f", currentPrice))"
        
        // Post local notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
        
        // Provide haptic feedback if app is in foreground
        provideFeedback(for: alert.type)
        
        logger.info("Alert triggered for \(alert.symbol) at price \(currentPrice)")
    }
    
    private func provideFeedback(for alertType: PriceAlertType) {
        var generator: UIFeedbackGenerator
        
        switch alertType {
        case .oneTime:
            generator = UIImpactFeedbackGenerator(style: .medium)
            (generator as? UIImpactFeedbackGenerator)?.impactOccurred()
        case .persistent:
            generator = UIImpactFeedbackGenerator(style: .heavy)
            (generator as? UIImpactFeedbackGenerator)?.impactOccurred()
        case .critical:
            generator = UINotificationFeedbackGenerator()
            (generator as? UINotificationFeedbackGenerator)?.notificationOccurred(.error)
        }
    }
    
    // MARK: - Data Access
    
    private func getCurrentValue(for symbol: String, completion: @escaping (Result<Double, Error>) -> Void) {
        // Use the data provider to get real-time price data
        Task {
            do {
                let marketData = try await dataProvider.fetchLatestPrice(for: symbol)
                DispatchQueue.main.async {
                    completion(.success(marketData.close))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveAlerts() {
        do {
            let data = try JSONEncoder().encode(activeAlerts)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            logger.error("Failed to save alerts: \(error.localizedDescription)")
        }
    }
    
    private func loadSavedAlerts() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            return
        }
        
        do {
            activeAlerts = try JSONDecoder().decode([PriceAlert].self, from: data)
        } catch {
            logger.error("Failed to load saved alerts: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

struct PriceAlert: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let targetPrice: Double
    let direction: PriceAlertDirection
    let type: PriceAlertType
    let createdAt: Date
    var isActive: Bool
}

enum PriceAlertDirection: String, Codable {
    case above = "Above"
    case below = "Below"
}

enum PriceAlertType: String, Codable {
    case oneTime = "One-time"
    case persistent = "Persistent"
    case critical = "Critical"
}
