import UserNotifications
import Foundation
import SwiftUI

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestPermission()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    func scheduleNotification(title: String, body: String, delay: TimeInterval = 0, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "TRADE_SUGGESTION"
        
        // Add actions for trade suggestions
        let executeAction = UNNotificationAction(
            identifier: "EXECUTE_TRADE",
            title: "Execute Trade",
            options: .foreground
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "TRADE_SUGGESTION",
            actions: [executeAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])

        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil
        }
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification action response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier
        let notificationIdentifier = response.notification.request.identifier
        
        if identifier == "EXECUTE_TRADE" {
            // Temporarily comment out until TradeSuggestionManager is properly imported
            // Find the suggestion by ID and execute it
            // if let suggestion = TradeSuggestionManager.shared.currentSuggestions.first(where: { $0.id.uuidString == notificationIdentifier }) {
            //     _ = TradeSuggestionManager.shared.executeSuggestion(suggestion)
            // }
            print("Trade execution from notification requested for ID: \(notificationIdentifier)")
        } else if identifier == "VIEW_DETAILS" {
            // Show the trade suggestions view
            DispatchQueue.main.async {
                // This is a simplified approach - in a real app, you'd use a more robust navigation method
                NotificationCenter.default.post(name: NSNotification.Name("ShowTradeSuggestions"), object: nil)
            }
        }
        
        completionHandler()
    }
}
