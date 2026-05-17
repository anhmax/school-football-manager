import SwiftUI

struct EventsView: View {
    @EnvironmentObject var eventStore: EventStore

    @State private var selectedType: EventType? = nil
    @State private var showingAdd = false

    var filtered: [Event] {
        eventStore.events.filter { event in
            selectedType == nil || event.type == selectedType
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                typeFilter
                Divider()

                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { event in
                            NavigationLink {
                                EventDetailView(event: event)
                            } label: {
                                EventListRow(event: event, summary: eventStore.summary(for: event.id ?? ""))
                            }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { filtered[$0] }
                            toDelete.forEach { eventStore.delete($0) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("イベント")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditEventView(mode: .add)
            }
        }
    }

    var typeFilter: some View {
        HStack(spacing: 8) {
            FilterChip(title: "全て", isSelected: selectedType == nil, color: .accentColor) {
                selectedType = nil
            }
            ForEach(EventType.allCases, id: \.rawValue) { type in
                FilterChip(
                    title: type.displayName,
                    isSelected: selectedType == type,
                    color: type == .match ? .footballRed : .footballBlue
                ) {
                    selectedType = selectedType == type ? nil : type
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 52))
                .foregroundColor(.textTertiary)
            Text("イベントがありません")
                .font(.headline).foregroundColor(.textSecondary)
            Text("右上の「+」からイベントを追加できます")
                .font(.subheadline).foregroundColor(.textTertiary)
            Spacer()
        }
    }
}

// MARK: - Event List Row

struct EventListRow: View {
    let event: Event
    let summary: EventAttendanceSummary

    var body: some View {
        HStack(spacing: 14) {
            dateBadge
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    EventTypeBadge(type: event.type)
                    Spacer()
                    attendanceSummary
                }
                Text(event.title)
                    .font(.headline).lineLimit(1)
                Label(event.venue, systemImage: "mappin")
                    .font(.caption).foregroundColor(.textSecondary).lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }

    var dateBadge: some View {
        VStack(spacing: 2) {
            Text(monthStr)
                .font(.caption2).fontWeight(.semibold)
                .foregroundColor(.white)
            Text(dayStr)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(weekdayStr)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(width: 50, height: 64)
        .background(event.type == .match ? Color.footballRed : Color.footballBlue)
        .cornerRadius(12)
    }

    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    var monthStr: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "M月"
        return f.string(from: event.eventDate)
    }
    var dayStr: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: event.eventDate)
    }
    var weekdayStr: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "E"
        return f.string(from: event.eventDate)
    }

    @ViewBuilder
    var attendanceSummary: some View {
        if summary.totalRegistrations > 0 {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.statusSuccess)
                Text("\(summary.attendingCount)")
                Text("/")
                Text("\(summary.totalRegistrations)")
            }
            .font(.caption).foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Event Type Badge

struct EventTypeBadge: View {
    let type: EventType

    var body: some View {
        Label(type.displayName, systemImage: type.icon)
            .font(.caption).fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(type == .match ? Color.footballRed.opacity(0.12) : Color.footballBlue.opacity(0.12))
            .foregroundColor(type == .match ? .footballRed : .footballBlue)
            .cornerRadius(6)
    }
}

#Preview {
    EventsView()
        .environmentObject(EventStore())
}
