import SwiftUI
import Firebase

@main
struct SchoolFootballManagerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService()
    @StateObject private var playerService = PlayerService()
    @StateObject private var eventService = EventService()
    @StateObject private var carpoolService = CarpoolService()
    @StateObject private var statsService = StatsService()
    @StateObject private var notificationService = NotificationService()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        configureFirebase()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appState.navigationPath) {
                Group {
                    if authService.isLoggedIn && authService.currentUser?.isApproved == true {
                        RootView()
                    } else {
                        LoginView()
                    }
                }
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(playerService)
                .environmentObject(eventService)
                .environmentObject(carpoolService)
                .environmentObject(statsService)
                .environmentObject(notificationService)
                .onReceive(authService.$currentUser) { user in
                    appState.updateUser(user)
                }
                .onReceive(authService.$isLoggedIn) { isLoggedIn in
                    if !isLoggedIn {
                        appState.reset()
                    }
                }
                .errorAlert($appState.error)
                .onAppear {
                    setupNotifications()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    notificationService.clearAllBadges()
                }
            }
        }
    }

    private func configureFirebase() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("Warning: GoogleService-Info.plist not found")
            return
        }
        FirebaseApp.configure()
    }

    private func setupNotifications() {
        Task {
            await notificationService.requestPermission()

            if let token = await notificationService.getFCMToken() {
                await authService.updateFCMToken(token)
            }

            // Subscribe to general notifications
            await notificationService.subscribeToGeneralTopic()

            // Subscribe to role-based notifications
            if let role = authService.currentUser?.role {
                await notificationService.subscribeToRoleTopic(role)
            }

            // Subscribe to team-based notifications
            if let teamId = authService.currentUser?.teamId {
                await notificationService.subscribeToTeamTopic(teamId)
            }
        }
    }
}