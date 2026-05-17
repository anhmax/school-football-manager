import SwiftUI

struct EventRowView: View {
    let event: Event
    let attendanceStatus: AttendanceStatus?
    let showTeamName: Bool
    let onTap: () -> Void

    init(
        event: Event,
        attendanceStatus: AttendanceStatus? = nil,
        showTeamName: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.event = event
        self.attendanceStatus = attendanceStatus
        self.showTeamName = showTeamName
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Event type icon
                eventTypeIcon

                // Event content
                VStack(alignment: .leading, spacing: 4) {
                    // Title and team
                    HStack {
                        Text(event.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        if showTeamName, let grade = Grade(rawValue: event.teamId) {
                            Text(grade.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.teamColor(for: grade).opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    // Date and time
                    HStack(spacing: 8) {
                        Label(event.displayDate, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let departureTime = event.departureTime {
                            Label(formatTime(departureTime), systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Venue
                    if !event.venue.isEmpty {
                        Label(event.venue, systemImage: "location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Status row
                    HStack(spacing: 8) {
                        // Event status
                        eventStatusBadge

                        Spacer()

                        // Attendance status
                        if let status = attendanceStatus {
                            AttendanceBadgeView(status: status, style: .compact)
                        }
                    }
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(EventRowButtonStyle())
    }

    @ViewBuilder
    private var eventTypeIcon: some View {
        ZStack {
            Circle()
                .fill(eventTypeColor.opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: event.type.icon)
                .font(.headline)
                .foregroundColor(eventTypeColor)
        }
    }

    private var eventTypeColor: Color {
        switch event.type {
        case .match:
            return .red
        case .practice:
            return .blue
        }
    }

    @ViewBuilder
    private var eventStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(event.statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        if event.isPast {
            return .gray
        } else if event.isRegistrationClosed {
            return .red
        } else {
            return .green
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct EventRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Event Row

struct CompactEventRowView: View {
    let event: Event
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Type indicator
                Rectangle()
                    .fill(eventTypeColor)
                    .frame(width: 4)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(event.displayDateOnly)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(event.displayTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var eventTypeColor: Color {
        switch event.type {
        case .match: return .red
        case .practice: return .blue
        }
    }
}

// MARK: - Event List Section

struct EventListSection: View {
    let title: String
    let events: [Event]
    let attendanceStatuses: [String: AttendanceStatus]
    let showTeamName: Bool
    let onEventTap: (Event) -> Void

    var body: some View {
        if !events.isEmpty {
            Section {
                LazyVStack(spacing: 8) {
                    ForEach(events) { event in
                        EventRowView(
                            event: event,
                            attendanceStatus: attendanceStatuses[event.id ?? ""],
                            showTeamName: showTeamName
                        ) {
                            onEventTap(event)
                        }
                    }
                }
            } header: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("(\(events.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ScrollView {
            VStack(spacing: 16) {
                EventRowView(
                    event: Event(
                        teamId: "3nensei",
                        type: .match,
                        title: "春季大会 1回戦",
                        eventDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                        venue: "市民運動公園",
                        createdBy: "manager1"
                    ),
                    attendanceStatus: .attending
                ) {
                    print("Event tapped")
                }

                EventRowView(
                    event: Event(
                        teamId: "4nensei",
                        type: .practice,
                        title: "通常練習",
                        eventDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                        venue: "学校グラウンド",
                        createdBy: "manager2"
                    ),
                    attendanceStatus: .notConfirmed,
                    showTeamName: true
                ) {
                    print("Practice tapped")
                }

                Divider()

                VStack(spacing: 8) {
                    Text("Compact Style")
                        .font(.headline)

                    CompactEventRowView(
                        event: Event(
                            teamId: "5nensei",
                            type: .match,
                            title: "練習試合",
                            eventDate: Date(),
                            venue: "他校",
                            createdBy: "manager3"
                        )
                    ) {
                        print("Compact event tapped")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Events")
    }
}