import SwiftUI

struct ParentHomeView: View {
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var playerStore:  PlayerStore
    @EnvironmentObject var eventStore:   EventStore

    @State private var selectedTab = 0

    var linkedPlayers: [Player] {
        accountStore.linkedPlayers(from: playerStore.players)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ParentChildTab(players: linkedPlayers)
                .tabItem { Label("子供", systemImage: "figure.and.child.holdinghands") }
                .tag(0)

            ParentEventsTab()
                .tabItem { Label("イベント", systemImage: "calendar") }
                .tag(1)

            ParentSettingsTab()
                .tabItem { Label("設定", systemImage: "gear") }
                .tag(2)
        }
        .tint(.footballGreen)
    }
}

// MARK: - Child Tab

struct ParentChildTab: View {
    @EnvironmentObject var playerStore: PlayerStore
    let players: [Player]

    var body: some View {
        NavigationStack {
            Group {
                if players.isEmpty {
                    noChildView
                } else {
                    List {
                        ForEach(players) { player in
                            NavigationLink {
                                PlayerDetailView(player: player)
                            } label: {
                                PlayerRowView(player: player)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("子供の情報")
        }
    }

    var noChildView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 52)).foregroundColor(.secondary)
            Text("担当の選手が設定されていません")
                .font(.headline).foregroundColor(.secondary)
            Text("監督に確認してください")
                .font(.subheadline).foregroundColor(.secondary)
        }
    }
}

// MARK: - Events Tab (parent view)

struct ParentEventsTab: View {
    @EnvironmentObject var eventStore:   EventStore
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var playerStore:  PlayerStore

    var body: some View {
        NavigationStack {
            Group {
                if eventStore.events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 52)).foregroundColor(.secondary)
                        Text("イベントがありません")
                            .font(.headline).foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(eventStore.events.filter { $0.isUpcoming }) { event in
                            NavigationLink {
                                ParentEventDetailView(event: event)
                            } label: {
                                EventListRow(event: event, summary: eventStore.summary(for: event.id ?? ""))
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("イベント")
        }
    }
}

// MARK: - Parent Event Detail (simplified — only their child's RSVP)

struct ParentEventDetailView: View {
    @EnvironmentObject var eventStore:   EventStore
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var playerStore:  PlayerStore
    @EnvironmentObject var settings:     AppSettings

    @StateObject private var sheets = SheetsService()

    let event: Event

    private var eventId: String { event.id ?? "" }

    private var currentEvent: Event {
        eventStore.events.first { $0.id == event.id } ?? event
    }

    private var myPlayers: [Player] {
        accountStore.linkedPlayers(from: playerStore.players)
    }

    private func myStatus(for player: Player) -> AttendanceStatus {
        eventStore.registrations(for: eventId)
            .first { $0.playerName == player.name || $0.playerId == player.id }?
            .status ?? .notConfirmed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        EventTypeBadge(type: currentEvent.type)
                        Spacer()
                        Text(currentEvent.displayDate)
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Text(currentEvent.title)
                        .font(.title3).fontWeight(.bold)
                    Label(currentEvent.venue, systemImage: "mappin.circle")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(18)
                .background(Color(.systemBackground))
                .cornerRadius(16)

                // Schedule
                if currentEvent.departureTime != nil || currentEvent.meetingPoint != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("スケジュール", systemImage: "clock").font(.headline)
                        if let dep = currentEvent.departureTime {
                            ScheduleRow(label: "出発時間", value: dep.formatted(date: .omitted, time: .shortened), icon: "arrow.right.circle")
                        }
                        if let mp = currentEvent.meetingPoint {
                            ScheduleRow(label: "集合場所", value: mp, icon: "mappin.circle")
                        }
                    }
                    .padding(18)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }

                // Checklist
                if !currentEvent.checklist.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("持ち物", systemImage: "checklist").font(.headline)
                        ForEach(currentEvent.checklist, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.square").foregroundColor(.footballGreen)
                                Text(item).font(.subheadline)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }

                // My child's RSVP
                VStack(alignment: .leading, spacing: 12) {
                    Label("参加登録", systemImage: "person.badge.clock").font(.headline)

                    if myPlayers.isEmpty {
                        Text("担当の選手が設定されていません")
                            .font(.subheadline).foregroundColor(.secondary)
                    } else {
                        ForEach(myPlayers) { player in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    PlayerMiniRow(player: player)
                                    Spacer()
                                }
                                // Large RSVP buttons
                                HStack(spacing: 10) {
                                    RSVPButton(label: "参加する", icon: "checkmark.circle.fill",
                                               color: .statusSuccess,
                                               isSelected: myStatus(for: player) == .attending) {
                                        rsvp(.attending, player: player)
                                    }
                                    RSVPButton(label: "欠席する", icon: "xmark.circle.fill",
                                               color: .statusError,
                                               isSelected: myStatus(for: player) == .absent) {
                                        rsvp(.absent, player: player)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(18)
                .background(Color(.systemBackground))
                .cornerRadius(16)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentEvent.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            eventStore.initRegistrationsIfNeeded(eventId: eventId, players: playerStore.players)
        }
    }

    private func rsvp(_ status: AttendanceStatus, player: Player) {
        eventStore.setStatus(status, playerName: player.name, playerId: player.id, eventId: eventId)
        guard settings.isSheetsConfigured else { return }
        Task {
            try? await sheets.update(eventTitle: currentEvent.title,
                                     playerName: player.name,
                                     status: status,
                                     scriptURL: settings.sheetsScriptURL)
        }
    }
}

struct RSVPButton: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.subheadline).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Settings Tab

struct ParentSettingsTab: View {
    @EnvironmentObject var accountStore: AccountStore

    var body: some View {
        NavigationStack {
            List {
                if let account = accountStore.currentAccount {
                    Section("アカウント情報") {
                        LabeledContent("表示名", value: account.displayName)
                        LabeledContent("ユーザー名", value: "@\(account.username)")
                        LabeledContent("権限", value: account.role.displayName)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        accountStore.logout()
                    } label: {
                        Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}
