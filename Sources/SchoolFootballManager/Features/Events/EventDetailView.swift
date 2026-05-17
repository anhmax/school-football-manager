import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var eventStore:  EventStore
    @EnvironmentObject var playerStore: PlayerStore
    @EnvironmentObject var settings:    AppSettings

    @StateObject private var sheets = SheetsService()

    let event: Event

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var syncError: String?
    @Environment(\.dismiss) var dismiss

    private var eventId: String { event.id ?? "" }

    private var currentEvent: Event {
        eventStore.events.first { $0.id == event.id } ?? event
    }

    private var registrations: [EventRegistration] {
        eventStore.registrations(for: eventId)
    }

    private var summary: EventAttendanceSummary {
        eventStore.summary(for: eventId)
    }

    private var allPlayerRows: [(player: Player, registration: EventRegistration?)] {
        playerStore.players.map { player in
            let reg = registrations.first { $0.playerName == player.name || $0.playerId == player.id }
            return (player, reg)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                scheduleCard
                if !currentEvent.checklist.isEmpty { checklistCard }
                if let notes = currentEvent.notes, !notes.isEmpty { notesCard(notes) }
                attendanceCard
                if let err = syncError {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundColor(.statusError)
                        .padding(.horizontal, 16)
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGrouped)
        .navigationTitle(currentEvent.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            eventStore.initRegistrationsIfNeeded(eventId: eventId, players: playerStore.players)
            if settings.isSheetsConfigured { Task { await pullFromSheets() } }
        }
        .toolbar {
            // Sheets sync button
            ToolbarItem(placement: .navigationBarLeading) {
                if settings.isSheetsConfigured {
                    Button { Task { await pullFromSheets() } } label: {
                        if sheets.isSyncing {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDeleteAlert = true } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditEventView(mode: .edit(currentEvent))
        }
        .alert("イベントを削除しますか？", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                eventStore.delete(currentEvent)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - Sheets sync

    private func pullFromSheets() async {
        guard let month = currentEvent.sheetMonth,
              let sheetDate = currentEvent.sheetDate else { return }
        syncError = nil
        do {
            let rows = try await sheets.fetchEvents(month: month, scriptURL: settings.sheetsScriptURL)
            if let row = rows.first(where: { $0.sheetDate == sheetDate }) {
                for name in row.attendingPlayers {
                    eventStore.setStatus(.attending, playerName: name, playerId: nil, eventId: eventId)
                }
                for name in row.absentPlayers {
                    eventStore.setStatus(.absent, playerName: name, playerId: nil, eventId: eventId)
                }
            }
        } catch {
            syncError = "Sheets同期エラー: \(error.localizedDescription)"
        }
    }

    private func pushToSheets(playerName: String, status: AttendanceStatus) {
        guard settings.isSheetsConfigured,
              let month = currentEvent.sheetMonth,
              let sheetDate = currentEvent.sheetDate else { return }
        Task {
            do {
                try await sheets.updateAttendance(
                    month: month,
                    sheetDate: sheetDate,
                    playerName: playerName,
                    status: status,
                    scriptURL: settings.sheetsScriptURL
                )
            } catch {
                syncError = "Sheets書き込みエラー: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Header Card

    var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                EventTypeBadge(type: currentEvent.type)
                Spacer()
                Text(currentEvent.displayDate)
                    .font(.subheadline).foregroundColor(.textSecondary)
            }

            Text(currentEvent.title)
                .font(.title3).fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            attendanceSummaryRow
        }
        .padding(18)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
    }

    var attendanceSummaryRow: some View {
        HStack(spacing: 0) {
            AttendanceStat(count: summary.attendingCount,     label: "参加",   color: .statusSuccess)
            Divider().frame(height: 32)
            AttendanceStat(count: summary.absentCount,       label: "欠席",   color: .statusError)
            Divider().frame(height: 32)
            AttendanceStat(count: summary.notConfirmedCount, label: "未確認", color: .statusWarning)
        }
    }

    // MARK: - Schedule Card

    var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("スケジュール", systemImage: "clock").font(.headline)

            VStack(spacing: 0) {
                if let dep = currentEvent.departureTime {
                    ScheduleRow(label: "出発時間", value: dep.formatted(date: .omitted, time: .shortened), icon: "arrow.right.circle")
                    Divider().padding(.leading, 36)
                }
                if let arr = currentEvent.estimatedArrivalTime {
                    ScheduleRow(label: "到着予定", value: arr.formatted(date: .omitted, time: .shortened), icon: "flag.checkered")
                    Divider().padding(.leading, 36)
                }
                if let meeting = currentEvent.meetingPoint {
                    ScheduleRow(label: "集合場所", value: meeting, icon: "mappin.circle")
                    Divider().padding(.leading, 36)
                }
                ScheduleRow(label: "会場", value: currentEvent.venue, icon: "sportscourt")
            }
        }
        .padding(18)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
    }

    // MARK: - Checklist Card

    var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("持ち物チェックリスト", systemImage: "checklist").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(currentEvent.checklist, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.footballGreen)
                        Text(item)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
    }

    // MARK: - Notes Card

    func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("メモ", systemImage: "note.text").font(.headline)
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .padding(18)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
    }

    // MARK: - Attendance Card

    var attendanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("参加登録", systemImage: "person.badge.clock").font(.headline)
                Spacer()
                if let time = sheets.lastSyncTime {
                    Text("同期: \(time.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            VStack(spacing: 0) {
                ForEach(allPlayerRows, id: \.player.id) { row in
                    AttendanceRow(
                        player: row.player,
                        status: row.registration?.status ?? .notConfirmed
                    ) { newStatus in
                        eventStore.setStatus(
                            newStatus,
                            playerName: row.player.name,
                            playerId: row.player.id,
                            eventId: eventId
                        )
                        pushToSheets(playerName: row.player.name, status: newStatus)
                    }
                    Divider().padding(.leading, 58)
                }
            }
        }
        .padding(18)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct AttendanceStat: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text("\(count)")
                .font(.title2).fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ScheduleRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            Text(label)
                .font(.subheadline).foregroundColor(.textSecondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.subheadline).fontWeight(.medium)
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

struct AttendanceRow: View {
    let player: Player
    let status: AttendanceStatus
    let onTap: (AttendanceStatus) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Position circle
            ZStack {
                Circle()
                    .fill(Color.positionColor(for: player.position).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(player.jerseyNumber)")
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(Color.positionColor(for: player.position))
            }

            Text(player.name)
                .font(.subheadline).fontWeight(.medium)

            Spacer()

            // Status toggle buttons
            HStack(spacing: 6) {
                AttendanceButton(label: "参加", icon: "checkmark", status: .attending, current: status) {
                    onTap(.attending)
                }
                AttendanceButton(label: "欠席", icon: "xmark", status: .absent, current: status) {
                    onTap(.absent)
                }
                AttendanceButton(label: "未", icon: "questionmark", status: .notConfirmed, current: status) {
                    onTap(.notConfirmed)
                }
            }
        }
        .padding(.vertical, 10)
    }
}

struct AttendanceButton: View {
    let label: String
    let icon: String
    let status: AttendanceStatus
    let current: AttendanceStatus
    let action: () -> Void

    var isSelected: Bool { current == status }

    var color: Color {
        switch status {
        case .attending:    return .statusSuccess
        case .absent:       return .statusError
        case .notConfirmed: return .statusWarning
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? "\(icon).circle.fill" : "\(icon).circle")
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 9))
            }
            .foregroundColor(isSelected ? color : .textTertiary)
            .frame(width: 38)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
