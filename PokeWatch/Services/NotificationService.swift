import Foundation
import UserNotifications
import UIKit

protocol NotificationServiceProtocol {
    func configure()
    func registerForPushNotifications()
    func updateDeviceToken(_ data: Data)
    func handleRegistrationError(_ error: Error)
    func postStockAvailableNotification(for entry: StockEntry)
}

final class NotificationService: NSObject, NotificationServiceProtocol {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private(set) var deviceToken: String?

    private override init() {}

    func configure() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            if !granted {
                print("User declined notification permissions.")
            }
        }
    }

    func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func updateDeviceToken(_ data: Data) {
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        print("APNs device token: \(token)")
    }

    func handleRegistrationError(_ error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func postStockAvailableNotification(for entry: StockEntry) {
        let content = UNMutableNotificationContent()
        content.title = "\(entry.store) has stock!"
        content.body = "Tap to view the product page."
        content.sound = .default

        if let url = entry.productURL {
            content.userInfo = ["productURL": url.absoluteString]
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        notificationCenter.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
