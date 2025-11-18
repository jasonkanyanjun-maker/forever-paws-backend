import Foundation
import UserNotifications
import SwiftUI
import Combine

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var hasUnreadNotifications = false
    @Published var notifications: [AppNotification] = []
    
    private init() {
        requestNotificationPermission()
        loadNotifications()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleNotification(for ticket: SupportTicket, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Support Ticket Update"
        content.body = "Ticket #\(String(ticket.id.uuidString.prefix(8))): \(message)"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "support_ticket_\(ticket.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
        
        // Add to in-app notifications
        let notification = AppNotification(
            id: UUID(),
            title: "Support Ticket Update",
            message: message,
            type: .supportUpdate,
            relatedId: ticket.id.uuidString,
            isRead: false,
            createdAt: Date()
        )
        
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            self.hasUnreadNotifications = true
        }
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadStatus()
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        hasUnreadNotifications = false
    }
    
    private func updateUnreadStatus() {
        hasUnreadNotifications = notifications.contains { !$0.isRead }
    }
    
    private func loadNotifications() {
        // TODO: Load from persistent storage or API
        // For now, using mock data
        notifications = []
    }
}

struct AppNotification: Identifiable, Codable {
    let id: UUID
    let title: String
    let message: String
    let type: NotificationType
    let relatedId: String?
    var isRead: Bool
    let createdAt: Date
    
    enum NotificationType: String, Codable {
        case supportUpdate = "support_update"
        case systemUpdate = "system_update"
        case videoReady = "video_ready"
        
        var icon: String {
            switch self {
            case .supportUpdate:
                return "questionmark.circle.fill"
            case .systemUpdate:
                return "gear.circle.fill"
            case .videoReady:
                return "play.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .supportUpdate:
                return .blue
            case .systemUpdate:
                return .orange
            case .videoReady:
                return .green
            }
        }
    }
}