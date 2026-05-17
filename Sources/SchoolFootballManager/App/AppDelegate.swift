import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Set messaging delegate
        Messaging.messaging().delegate = self

        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("APNs token retrieved: \(deviceToken)")

        // With swizzling disabled, you must set the APNs token here.
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        print("Notification received: \(userInfo)")

        // Handle the notification payload
        handleRemoteNotification(userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }

    private func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        // Extract notification data
        guard let data = userInfo["data"] as? [String: Any] else { return }

        if let eventId = data["eventId"] as? String {
            // Navigate to event details
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToEvent"),
                object: nil,
                userInfo: ["eventId": eventId]
            )
        } else if let teamId = data["teamId"] as? String {
            // Navigate to team details
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToTeam"),
                object: nil,
                userInfo: ["teamId": teamId]
            )
        }
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")

        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        print("Will present notification: \(userInfo)")

        // Change this to your preferred presentation option
        completionHandler([[.banner, .badge, .sound]])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        print("Did receive notification response: \(userInfo)")

        // Handle notification tap
        handleNotificationTap(userInfo)

        completionHandler()
    }

    private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // Extract custom data from the notification
        if let data = userInfo["data"] as? [String: Any] {
            if let eventId = data["eventId"] as? String {
                // Navigate to specific event
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToEvent"),
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            } else if let teamId = data["teamId"] as? String {
                // Navigate to specific team
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTeam"),
                    object: nil,
                    userInfo: ["teamId": teamId]
                )
            } else if let notificationType = data["type"] as? String {
                switch notificationType {
                case "approval_request":
                    // Navigate to admin approval screen
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToApprovals"),
                        object: nil
                    )
                case "carpool_update":
                    // Navigate to carpool screen
                    if let eventId = data["eventId"] as? String {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NavigateToCarpool"),
                            object: nil,
                            userInfo: ["eventId": eventId]
                        )
                    }
                case "match_result":
                    // Navigate to match stats
                    if let matchId = data["matchId"] as? String {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NavigateToMatch"),
                            object: nil,
                            userInfo: ["matchId": matchId]
                        )
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Scene Configuration

extension AppDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Called when the user discards a scene session.
    }
}