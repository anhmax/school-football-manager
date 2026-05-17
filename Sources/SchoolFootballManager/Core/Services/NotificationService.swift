import Foundation
import Firebase
import FirebaseMessaging
import UserNotifications
import UIKit

@MainActor
class NotificationService: NSObject, ObservableObject {
    @Published var hasPermission = false
    @Published var fcmToken: String?

    private let messaging = Messaging.messaging()

    override init() {
        super.init()
        messaging.delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            hasPermission = granted

            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }

    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }

    func getFCMToken() async -> String? {
        do {
            let token = try await messaging.token()
            fcmToken = token
            return token
        } catch {
            print("Error getting FCM token: \(error)")
            return nil
        }
    }

    // MARK: - Local Notifications

    func scheduleEventReminder(for event: Event, hoursBefor: Int = 2) async {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(event.type.displayName)のリマインダー"
        content.body = "\(event.title)が\(hoursBefor)時間後に開始されます。"
        content.sound = .default
        content.badge = 1

        let triggerDate = event.eventDate.addingTimeInterval(-Double(hoursBefor * 3600))
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )

        let identifier = "event_reminder_\(event.id ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Event reminder scheduled for: \(triggerDate)")
        } catch {
            print("Error scheduling event reminder: \(error)")
        }
    }

    func scheduleRegistrationDeadlineReminder(for event: Event, hoursBefor: Int = 24) async {
        guard hasPermission,
              let deadline = event.registrationDeadline else { return }

        let content = UNMutableNotificationContent()
        content.title = "登録締切のリマインダー"
        content.body = "\(event.title)の登録締切まで\(hoursBefor)時間です。"
        content.sound = .default
        content.badge = 1

        let triggerDate = deadline.addingTimeInterval(-Double(hoursBefor * 3600))
        guard triggerDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )

        let identifier = "registration_deadline_\(event.id ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Registration deadline reminder scheduled for: \(triggerDate)")
        } catch {
            print("Error scheduling registration deadline reminder: \(error)")
        }
    }

    func cancelNotification(identifier: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllEventNotifications(for eventId: String) async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        let identifiersToCancel = pendingRequests
            .filter { $0.identifier.contains(eventId) }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
    }

    // MARK: - Push Notification Topics

    func subscribeToTeamTopic(_ teamId: String) async {
        do { try await messaging.subscribe(toTopic: "team_\(teamId)") }
        catch { print("Topic subscribe error: \(error)") }
    }

    func unsubscribeFromTeamTopic(_ teamId: String) async {
        do { try await messaging.unsubscribe(fromTopic: "team_\(teamId)") }
        catch { print("Topic unsubscribe error: \(error)") }
    }

    func subscribeToRoleTopic(_ role: UserRole) async {
        do { try await messaging.subscribe(toTopic: "role_\(role.rawValue)") }
        catch { print("Topic subscribe error: \(error)") }
    }

    func unsubscribeFromRoleTopic(_ role: UserRole) async {
        do { try await messaging.unsubscribe(fromTopic: "role_\(role.rawValue)") }
        catch { print("Topic unsubscribe error: \(error)") }
    }

    func subscribeToGeneralTopic() async {
        do { try await messaging.subscribe(toTopic: "general") }
        catch { print("Topic subscribe error: \(error)") }
    }

    // MARK: - Utility Methods

    func checkNotificationSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        hasPermission = settings.authorizationStatus == .authorized
    }

    func clearAllBadges() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func incrementBadge() {
        let currentBadge = UIApplication.shared.applicationIconBadgeNumber
        UIApplication.shared.applicationIconBadgeNumber = currentBadge + 1
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        Task { @MainActor in
            self.fcmToken = fcmToken
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.badge, .sound, .banner])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        print("Notification tapped with identifier: \(identifier)")

        // Handle different notification types
        if identifier.contains("event_reminder") {
            // Navigate to event details
            handleEventNotificationTap(identifier: identifier)
        } else if identifier.contains("registration_deadline") {
            // Navigate to event registration
            handleRegistrationNotificationTap(identifier: identifier)
        }

        completionHandler()
    }

    private func handleEventNotificationTap(identifier: String) {
        // Extract event ID from identifier and navigate to event details
        // This would typically post a notification that the app can observe
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToEvent"),
            object: nil,
            userInfo: ["identifier": identifier]
        )
    }

    private func handleRegistrationNotificationTap(identifier: String) {
        // Extract event ID from identifier and navigate to registration
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToEventRegistration"),
            object: nil,
            userInfo: ["identifier": identifier]
        )
    }
}