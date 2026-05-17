import SwiftUI

struct ManagerDashboardView: View {
    @EnvironmentObject var playerStore: PlayerStore
    @EnvironmentObject var eventStore:  EventStore

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewTab()
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(0)

            PlayersView()
                .tabItem { Label("選手", systemImage: "person.3.fill") }
                .tag(1)

            EventsView()
                .tabItem { Label("イベント", systemImage: "calendar") }
                .tag(2)

            StatsView()
                .tabItem { Label("統計", systemImage: "chart.bar.fill") }
                .tag(3)
        }
        .tint(.footballGreen)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @EnvironmentObject var playerStore: PlayerStore
    @EnvironmentObject var eventStore:  EventStore

    var nextEvent: Event? {
        eventStore.events.first { $0.eventDate > Date() }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    teamHeaderCard
                    statsRow
                    if let event = nextEvent { nextEventCard(event) }
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .background(Color.backgroundGrouped)
            .navigationTitle("3年生チーム")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var teamHeaderCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.footballGreen, .footballBlue],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                Image(systemName: "figure.soccer")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("3年生チーム")
                    .font(.title2).fontWeight(.bold)
                Text("シーズン 2026")
                    .font(.subheadline).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    var statsRow: some View {
        HStack(spacing: 12) {
            QuickStatCard(value: "\(playerStore.players.count)", label: "選手数", icon: "person.3.fill", color: .footballBlue)
            QuickStatCard(value: "\(eventStore.events.filter { $0.isUpcoming }.count)", label: "予定", icon: "calendar", color: .footballGreen)
            QuickStatCard(value: "\(eventStore.events.filter { $0.type == .match }.count)", label: "試合", icon: "figure.soccer", color: .footballRed)
        }
    }

    func nextEventCard(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("次のイベント")
                    .font(.headline)
                Spacer()
                EventTypeBadge(type: event.type)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.title3).fontWeight(.semibold)

                Label(event.displayDate, systemImage: "calendar")
                    .font(.subheadline).foregroundColor(.textSecondary)

                Label(event.venue, systemImage: "mappin.circle")
                    .font(.subheadline).foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

struct QuickStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.title2).fontWeight(.bold)
            Text(label)
                .font(.caption).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
