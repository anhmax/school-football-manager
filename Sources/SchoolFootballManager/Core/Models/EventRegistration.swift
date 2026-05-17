import Foundation
import FirebaseFirestoreSwift

enum AttendanceStatus: String, CaseIterable, Codable {
    case attending = "attending"
    case absent = "absent"
    case notConfirmed = "not_confirmed"

    var displayName: String {
        switch self {
        case .attending:
            return "参加"
        case .absent:
            return "欠席"
        case .notConfirmed:
            return "未確認"
        }
    }

    var emoji: String {
        switch self {
        case .attending:
            return "✅"
        case .absent:
            return "❌"
        case .notConfirmed:
            return "❓"
        }
    }

    var color: String {
        switch self {
        case .attending:
            return "green"
        case .absent:
            return "red"
        case .notConfirmed:
            return "yellow"
        }
    }
}

struct EventRegistration: Codable, Identifiable {
    @DocumentID var id: String?
    var eventId: String
    var userId: String
    var userName: String
    var playerId: String?
    var playerName: String?
    var status: AttendanceStatus
    var notes: String?
    var registeredAt: Date
    var updatedAt: Date

    init(eventId: String, userId: String, userName: String,
         playerId: String? = nil, playerName: String? = nil,
         status: AttendanceStatus = .notConfirmed, notes: String? = nil) {
        self.eventId = eventId
        self.userId = userId
        self.userName = userName
        self.playerId = playerId
        self.playerName = playerName
        self.status = status
        self.notes = notes
        self.registeredAt = Date()
        self.updatedAt = Date()
    }

    var displayName: String {
        if let playerName = playerName {
            return "\(playerName) (\(userName))"
        } else {
            return userName
        }
    }

    var isConfirmed: Bool {
        status != .notConfirmed
    }

    var isAttending: Bool {
        status == .attending
    }

    mutating func updateStatus(_ newStatus: AttendanceStatus, notes: String? = nil) {
        self.status = newStatus
        if let notes = notes {
            self.notes = notes
        }
        self.updatedAt = Date()
    }
}

struct EventAttendanceSummary {
    let eventId: String
    let totalRegistrations: Int
    let attendingCount: Int
    let absentCount: Int
    let notConfirmedCount: Int
    let registrations: [EventRegistration]

    var attendanceRate: Double {
        let confirmedCount = attendingCount + absentCount
        guard confirmedCount > 0 else { return 0 }
        return Double(attendingCount) / Double(confirmedCount) * 100
    }

    var confirmationRate: Double {
        guard totalRegistrations > 0 else { return 0 }
        let confirmedCount = attendingCount + absentCount
        return Double(confirmedCount) / Double(totalRegistrations) * 100
    }

    static func from(registrations: [EventRegistration]) -> EventAttendanceSummary {
        let eventId = registrations.first?.eventId ?? ""
        let attending = registrations.filter { $0.status == .attending }
        let absent = registrations.filter { $0.status == .absent }
        let notConfirmed = registrations.filter { $0.status == .notConfirmed }

        return EventAttendanceSummary(
            eventId: eventId,
            totalRegistrations: registrations.count,
            attendingCount: attending.count,
            absentCount: absent.count,
            notConfirmedCount: notConfirmed.count,
            registrations: registrations
        )
    }
}