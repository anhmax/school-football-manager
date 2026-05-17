import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ParentOverviewView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(0)

            ChildInfoView()
                .tabItem {
                    Label("子供の情報", systemImage: "person")
                }
                .tag(1)

            EventsView()
                .tabItem {
                    Label("イベント", systemImage: "calendar")
                }
                .tag(2)

            CarpoolView()
                .tabItem {
                    Label("相乗り", systemImage: "car.2")
                }
                .tag(3)

            ParentSettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(4)
        }
    }
}

struct ParentOverviewView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("保護者ダッシュボード")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let teamId = authService.currentUser?.teamId,
                       let grade = Grade(rawValue: teamId) {
                        Text("所属チーム: \(grade.displayName)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    // Child info and upcoming events would go here
                    Text("子供の情報とイベント情報はここに表示されます")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
        }
    }
}

struct ChildInfoView: View {
    var body: some View {
        NavigationView {
            Text("子供の情報画面")
                .navigationTitle("子供の情報")
        }
    }
}

struct ParentSettingsView: View {
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
    ParentDashboardView()
        .environmentObject(AuthService())
}