import Foundation
import FirebaseFirestoreSwift

struct Carpool: Codable, Identifiable {
    @DocumentID var id: String?
    var eventId: String
    var driverId: String
    var driverName: String
    var driverPhone: String?
    var carModel: String
    var carColor: String?
    var totalSeats: Int
    var availableSeats: Int
    var pickupPoint: String
    var pickupTime: Date?
    var notes: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(eventId: String, driverId: String, driverName: String,
         carModel: String, totalSeats: Int, pickupPoint: String,
         driverPhone: String? = nil, carColor: String? = nil,
         pickupTime: Date? = nil, notes: String? = nil) {
        self.eventId = eventId
        self.driverId = driverId
        self.driverName = driverName
        self.driverPhone = driverPhone
        self.carModel = carModel
        self.carColor = carColor
        self.totalSeats = totalSeats
        self.availableSeats = totalSeats
        self.pickupPoint = pickupPoint
        self.pickupTime = pickupTime
        self.notes = notes
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isFull: Bool {
        availableSeats <= 0
    }

    var occupiedSeats: Int {
        totalSeats - availableSeats
    }

    var displayCarInfo: String {
        if let color = carColor {
            return "\(color) \(carModel)"
        } else {
            return carModel
        }
    }

    var displaySeats: String {
        return "\(occupiedSeats)/\(totalSeats)席"
    }

    var displayPickupTime: String? {
        guard let pickupTime = pickupTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: pickupTime)
    }

    mutating func bookSeat() -> Bool {
        guard availableSeats > 0 else { return false }
        availableSeats -= 1
        updatedAt = Date()
        return true
    }

    mutating func cancelBooking() {
        if availableSeats < totalSeats {
            availableSeats += 1
            updatedAt = Date()
        }
    }

    var statusText: String {
        if !isActive {
            return "無効"
        } else if isFull {
            return "満席"
        } else {
            return "空きあり"
        }
    }

    var statusColor: String {
        if !isActive {
            return "gray"
        } else if isFull {
            return "red"
        } else {
            return "green"
        }
    }
}