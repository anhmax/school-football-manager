import Foundation

@MainActor
class EventStore: ObservableObject {
    @Published var events: [Event] = []
    @Published var registrationsByEvent: [String: [EventRegistration]] = [:]

    static let teamId   = "3nensei"
    static let managerId   = "manager-001"
    static let managerName = "田中 監督"

    init() {
        setupMockData()
    }

    // MARK: - Mock Data

    private func setupMockData() {
        let e1 = makeEvent(
            id: "event-001",
            type: .match,
            title: "春季大会 第1試合",
            date: dt(2026, 5, 24, 10, 0),
            venue: "緑ヶ丘グラウンド",
            checklist: ["ユニフォーム", "スパイク", "弁当", "水筒"],
            departureTime: dt(2026, 5, 24, 8, 30),
            arrivalTime: dt(2026, 5, 24, 9, 30),
            meetingPoint: "学校正門前",
            notes: "保護者の応援よろしくお願いします！",
            deadline: dt(2026, 5, 22, 20, 0)
        )

        let e2 = makeEvent(
            id: "event-002",
            type: .practice,
            title: "通常練習",
            date: dt(2026, 5, 25, 9, 0),
            venue: "学校グラウンド",
            checklist: ["練習着", "スパイク", "水筒"],
            notes: "雨天中止の場合はアプリでお知らせします"
        )

        let e3 = makeEvent(
            id: "event-003",
            type: .match,
            title: "交流戦 vs 桜小学校",
            date: dt(2026, 6, 7, 13, 0),
            venue: "桜小学校グラウンド",
            checklist: ["ユニフォーム", "スパイク", "弁当", "水筒", "着替え"],
            departureTime: dt(2026, 6, 7, 11, 30),
            meetingPoint: "学校正門前"
        )

        events = [e1, e2, e3]

    }

    private func makeEvent(id: String, type: EventType, title: String, date: Date,
                           venue: String, checklist: [String] = [],
                           departureTime: Date? = nil, arrivalTime: Date? = nil,
                           meetingPoint: String? = nil, notes: String? = nil,
                           deadline: Date? = nil) -> Event {
        var e = Event(teamId: Self.teamId, type: type, title: title, eventDate: date,
                      venue: venue, checklist: checklist, createdBy: Self.managerId)
        e.id = id
        e.departureTime = departureTime
        e.estimatedArrivalTime = arrivalTime
        e.meetingPoint = meetingPoint
        e.notes = notes
        e.registrationDeadline = deadline
        return e
    }

    private func dt(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9, _ min: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min)) ?? Date()
    }

    // MARK: - Event CRUD

    func add(_ event: Event) {
        var e = event
        if e.id == nil { e.id = UUID().uuidString }
        events.append(e)
        events.sort { $0.eventDate < $1.eventDate }
    }

    func update(_ event: Event) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
        events.sort { $0.eventDate < $1.eventDate }
    }

    func delete(_ event: Event) {
        events.removeAll { $0.id == event.id }
        if let id = event.id { registrationsByEvent.removeValue(forKey: id) }
    }

    // MARK: - Registrations

    func registrations(for eventId: String) -> [EventRegistration] {
        registrationsByEvent[eventId] ?? []
    }

    func summary(for eventId: String) -> EventAttendanceSummary {
        EventAttendanceSummary.from(registrations: registrations(for: eventId))
    }

    func setStatus(_ status: AttendanceStatus, playerName: String, playerId: String?, eventId: String) {
        var regs = registrationsByEvent[eventId] ?? []

        if let idx = regs.firstIndex(where: { $0.playerName == playerName }) {
            regs[idx].status = status
            regs[idx].updatedAt = Date()
        } else {
            var reg = EventRegistration(
                eventId: eventId,
                userId: "parent-\(playerName)",
                userName: "\(playerName)の保護者",
                playerId: playerId,
                playerName: playerName,
                status: status
            )
            reg.id = UUID().uuidString
            regs.append(reg)
        }
        registrationsByEvent[eventId] = regs
    }

    func initRegistrationsIfNeeded(eventId: String, players: [Player]) {
        guard registrationsByEvent[eventId] == nil else { return }
        registrationsByEvent[eventId] = players.map { player in
            var reg = EventRegistration(
                eventId: eventId,
                userId: "parent-\(player.id ?? UUID().uuidString)",
                userName: "\(player.name)の保護者",
                playerId: player.id,
                playerName: player.name,
                status: .notConfirmed
            )
            reg.id = UUID().uuidString
            return reg
        }
    }
}
