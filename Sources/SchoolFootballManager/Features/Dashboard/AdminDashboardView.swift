import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var eventService: EventService
    @EnvironmentObject private var playerService: PlayerService

    @State private var selectedTab: Int = 0
    @State private var pendingUsersCount: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            AdminOverviewView()
                .tabItem {
                    Label("ダッシュボード", systemImage: "house")
                }
                .tag(0)

            // Teams
            AdminTeamsView()
                .tabItem {
                    Label("チーム", systemImage: "person.3.sequence")
                }
                .tag(1)

            // Events
            AdminEventsView()
                .tabItem {
                    Label("イベント", systemImage: "calendar")
                }
                .tag(2)

            // User Management
            UserApprovalView()
                .tabItem {
                    Label("ユーザー管理", systemImage: "person.badge.key")
                }
                .badge(pendingUsersCount)
                .tag(3)

            // Settings
            AdminSettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(4)
        }
        .onAppear {
            loadPendingUsersCount()
        }
    }

    private func loadPendingUsersCount() {
        // This would typically load from Firestore
        // For now, we'll use a placeholder
        pendingUsersCount = 0
    }
}

struct AdminOverviewView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var teamStats: [TeamOverviewStats] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome section
                    welcomeSection

                    // Quick stats
                    quickStatsSection

                    // Teams overview
                    teamsOverviewSection

                    // Recent activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("管理者ダッシュボード")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ログアウト") {
                        Task {
                            try await authService.signOut()
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadTeamStats()
        }
    }

    @ViewBuilder
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("おかえりなさい！")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let userName = authService.currentUser?.name {
                        Text("\(userName) さん")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                UserAvatarView(
                    userName: authService.currentUser?.name ?? "",
                    role: .admin,
                    size: .large,
                    showBorder: true
                )
            }

            Text("全チームの状況を確認し、管理業務を行えます。")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .cardStyle()
    }

    @ViewBuilder
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "総チーム数",
                value: "\(Grade.allCases.count)",
                icon: "person.3.sequence",
                color: .blue
            )

            StatCard(
                title: "総選手数",
                value: "\(teamStats.reduce(0) { $0 + $1.playerCount })",
                icon: "person.2.soccer.ball",
                color: .green
            )

            StatCard(
                title: "今月のイベント",
                value: "12", // Placeholder
                icon: "calendar",
                color: .orange
            )

            StatCard(
                title: "承認待ち",
                value: "3", // Placeholder
                icon: "person.badge.clock",
                color: .red
            )
        }
    }

    @ViewBuilder
    private var teamsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "チーム一覧")

            LazyVStack(spacing: 12) {
                ForEach(Grade.allCases, id: \.self) { grade in
                    TeamOverviewRow(grade: grade)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "最近のアクティビティ")

            VStack(spacing: 12) {
                ActivityRow(
                    icon: "person.badge.plus",
                    title: "新しいユーザー登録",
                    subtitle: "田中さん (4年生チーム監督)",
                    time: "2時間前",
                    color: .blue
                )

                ActivityRow(
                    icon: "calendar.badge.plus",
                    title: "新しいイベント",
                    subtitle: "春季大会 1回戦",
                    time: "5時間前",
                    color: .green
                )

                ActivityRow(
                    icon: "sportscourt",
                    title: "試合結果更新",
                    subtitle: "3年生チーム vs 桜小学校",
                    time: "1日前",
                    color: .orange
                )
            }
        }
        .padding()
        .cardStyle()
    }

    private func loadTeamStats() {
        // Load team statistics
        teamStats = Grade.allCases.map { grade in
            TeamOverviewStats(
                grade: grade,
                playerCount: Int.random(in: 15...25),
                upcomingEvents: Int.random(in: 2...8),
                lastActivity: Date().addingTimeInterval(-Double.random(in: 3600...86400))
            )
        }
    }
}

struct TeamOverviewStats {
    let grade: Grade
    let playerCount: Int
    let upcomingEvents: Int
    let lastActivity: Date
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .cardStyle()
    }
}

struct TeamOverviewRow: View {
    let grade: Grade

    var body: some View {
        HStack(spacing: 12) {
            TeamAvatarView(grade: grade, size: .medium, showBorder: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(grade.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("選手 23名 • イベント 5件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("最終更新")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("2時間前")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to team detail
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Placeholder views for other admin tabs
struct AdminTeamsView: View {
    var body: some View {
        NavigationView {
            Text("チーム管理画面")
                .navigationTitle("チーム管理")
        }
    }
}

struct AdminEventsView: View {
    var body: some View {
        NavigationView {
            Text("イベント管理画面")
                .navigationTitle("イベント管理")
        }
    }
}

struct AdminSettingsView: View {
    var body: some View {
        NavigationView {
            Text("設定画面")
                .navigationTitle("設定")
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
        .environmentObject(EventService())
        .environmentObject(PlayerService())
}