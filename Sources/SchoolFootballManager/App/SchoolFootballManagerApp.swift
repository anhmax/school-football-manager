import SwiftUI

@main
struct SchoolFootballManagerApp: App {
    @StateObject private var playerStore = PlayerStore()
    @StateObject private var eventStore  = EventStore()

    var body: some Scene {
        WindowGroup {
            ManagerDashboardView()
                .environmentObject(playerStore)
                .environmentObject(eventStore)
        }
    }
}
