import SwiftUI

@main
struct SchoolFootballManagerApp: App {
    @StateObject private var accountStore = AccountStore()
    @StateObject private var playerStore  = PlayerStore()
    @StateObject private var eventStore   = EventStore()
    @StateObject private var settings     = AppSettings()

    var body: some Scene {
        WindowGroup {
            if accountStore.currentAccount == nil {
                SimpleLoginView()
                    .environmentObject(accountStore)
            } else if accountStore.isManager {
                ManagerDashboardView()
                    .environmentObject(accountStore)
                    .environmentObject(playerStore)
                    .environmentObject(eventStore)
                    .environmentObject(settings)
            } else {
                ParentHomeView()
                    .environmentObject(accountStore)
                    .environmentObject(playerStore)
                    .environmentObject(eventStore)
                    .environmentObject(settings)
            }
        }
    }
}
