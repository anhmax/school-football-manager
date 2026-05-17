import Foundation
import FirebaseFirestoreSwift

enum BookingStatus: String, CaseIterable, Codable {
    case confirmed = "confirmed"
    case cancelled = "cancelled"
    case pending = "pending"

    var displayName: String {
        switch self {
        case .confirmed:
            return "確定"
        case .cancelled:
            return "キャンセル"
        case .pending:
            return "保留中"
        }
    }

    var color: String {
        switch self {
        case .confirmed:
            return "green"
        case .cancelled:
            return "red"
        case .pending:
            return "yellow"
        }
    }
}

struct CarpoolBooking: Codable, Identifiable {
    @DocumentID var id: String?
    var carpoolId: String
    var eventId: String
    var parentId: String
    var parentName: String
    var playerId: String?
    var playerName: String?
    var parentPhone: String?
    var emergencyContact: String?
    var seatNumber: Int?
    var specialRequests: String?
    var status: BookingStatus
    var bookedAt: Date
    var updatedAt: Date

    init(carpoolId: String, eventId: String, parentId: String, parentName: String,
         playerId: String? = nil, playerName: String? = nil,
         parentPhone: String? = nil, emergencyContact: String? = nil,
         specialRequests: String? = nil, status: BookingStatus = .confirmed) {
        self.carpoolId = carpoolId
        self.eventId = eventId
        self.parentId = parentId
        self.parentName = parentName
        self.playerId = playerId
        self.playerName = playerName
        self.parentPhone = parentPhone
        self.emergencyContact = emergencyContact
        self.specialRequests = specialRequests
        self.status = status
        self.bookedAt = Date()
        self.updatedAt = Date()
    }

    var displayName: String {
        if let playerName = playerName {
            return "\(playerName) (\(parentName))"
        } else {
            return parentName
        }
    }

    var isActive: Bool {
        status == .confirmed || status == .pending
    }

    var displaySeatInfo: String {
        if let seatNumber = seatNumber {
            return "座席 \(seatNumber)"
        } else {
            return "座席未指定"
        }
    }

    var contactInfo: String {
        var info = parentName
        if let phone = parentPhone {
            info += " (\(phone))"
        }
        return info
    }

    mutating func confirm(seatNumber: Int? = nil) {
        self.status = .confirmed
        if let seat = seatNumber {
            self.seatNumber = seat
        }
        self.updatedAt = Date()
    }

    mutating func cancel() {
        self.status = .cancelled
        self.updatedAt = Date()
    }

    mutating func updateSpecialRequests(_ requests: String?) {
        self.specialRequests = requests
        self.updatedAt = Date()
    }
}

struct CarpoolSummary {
    let carpool: Carpool
    let bookings: [CarpoolBooking]

    var confirmedBookings: [CarpoolBooking] {
        bookings.filter { $0.status == .confirmed }
    }

    var pendingBookings: [CarpoolBooking] {
        bookings.filter { $0.status == .pending }
    }

    var activeBookingsCount: Int {
        bookings.filter { $0.isActive }.count
    }

    var hasSpecialRequests: Bool {
        bookings.contains { $0.specialRequests?.isEmpty == false }
    }

    var allPassengers: String {
        let names = confirmedBookings.compactMap { $0.playerName ?? $0.parentName }
        return names.joined(separator: ", ")
    }

    static func from(carpool: Carpool, bookings: [CarpoolBooking]) -> CarpoolSummary {
        return CarpoolSummary(carpool: carpool, bookings: bookings)
    }
}