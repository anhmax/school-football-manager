import SwiftUI

struct ManagerDashboardView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ManagerOverviewView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(0)

            PlayersView()
                .tabItem {
                    Label("選手", systemImage: "person.3")
                }
                .tag(1)

            EventsView()
                .tabItem {
                    Label("イベント", systemImage: "calendar")
                }
                .tag(2)

            StatsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar")
                }
                .tag(3)

            ManagerSettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(4)
        }
    }
}

struct ManagerOverviewView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("監督ダッシュボード")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let teamId = authService.currentUser?.teamId,
                       let grade = Grade(rawValue: teamId) {
                        Text("管理チーム: \(grade.displayName)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    // Quick actions and overview content would go here
                    Text("チーム管理機能はここに表示されます")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
        }
    }
}

struct ManagerSettingsView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("ログアウト") {
                        Task {
                            try await authService.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    ManagerDashboardView()
        .environmentObject(AuthService())
        .environmentObject(AppState())
}