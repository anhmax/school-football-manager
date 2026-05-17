import Foundation
import FirebaseFirestoreSwift

enum EventType: String, CaseIterable, Codable {
    case match = "match"
    case practice = "practice"

    var displayName: String {
        switch self {
        case .match:
            return "試合"
        case .practice:
            return "練習"
        }
    }

    var icon: String {
        switch self {
        case .match:
            return "figure.soccer"
        case .practice:
            return "sportscourt"
        }
    }
}

struct Event: Codable, Identifiable {
    @DocumentID var id: String?
    var teamId: String
    var type: EventType
    var title: String
    var eventDate: Date
    var departureTime: Date?
    var estimatedArrivalTime: Date?
    var meetingPoint: String?
    var venue: String
    var checklist: [String]
    var notes: String?
    var isRegistrationOpen: Bool
    var registrationDeadline: Date?
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date
    var sheetDate: String?   // "5/2" — links back to Google Sheet row
    var sheetMonth: String?  // "5月" — sheet tab name

    init(teamId: String, type: EventType, title: String, eventDate: Date,
         venue: String, checklist: [String] = [], createdBy: String) {
        self.teamId = teamId
        self.type = type
        self.title = title
        self.eventDate = eventDate
        self.venue = venue
        self.checklist = checklist
        self.isRegistrationOpen = true
        self.createdBy = createdBy
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isUpcoming: Bool {
        eventDate > Date()
    }

    var isPast: Bool {
        eventDate < Date()
    }

    var isRegistrationClosed: Bool {
        if let deadline = registrationDeadline {
            return Date() > deadline
        }
        return !isRegistrationOpen
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E) HH:mm"
        return formatter.string(from: eventDate)
    }

    var displayDateOnly: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: eventDate)
    }

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: eventDate)
    }

    var defaultChecklist: [String] {
        switch type {
        case .match:
            return [
                "ユニフォーム",
                "サッカーシューズ",
                "すねあて",
                "着替え",
                "タオル",
                "水筒",
                "ボール（個人練習用）"
            ]
        case .practice:
            return [
                "練習着",
                "サッカーシューズ",
                "すねあて",
                "着替え",
                "タオル",
                "水筒"
            ]
        }
    }

    var statusText: String {
        if isPast {
            return "終了"
        } else if isRegistrationClosed {
            return "受付終了"
        } else {
            return "受付中"
        }
    }

    var statusColor: String {
        if isPast {
            return "gray"
        } else if isRegistrationClosed {
            return "red"
        } else {
            return "green"
        }
    }
}