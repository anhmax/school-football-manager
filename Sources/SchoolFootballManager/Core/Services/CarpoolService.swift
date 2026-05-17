import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class CarpoolService: ObservableObject {
    @Published var carpools: [String: [Carpool]] = [:] // eventId -> carpools
    @Published var bookings: [String: [CarpoolBooking]] = [:] // carpoolId -> bookings
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()

    // MARK: - Carpool CRUD Operations

    func loadCarpools(for eventId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("events")
                .document(eventId)
                .collection("carpools")
                .whereField("isActive", isEqualTo: true)
                .order(by: "createdAt")
                .getDocuments()

            let eventCarpools = snapshot.documents.compactMap { document in
                try? document.data(as: Carpool.self)
            }

            carpools[eventId] = eventCarpools
        } catch {
            self.error = error.localizedDescription
            print("Error loading carpools: \(error)")
        }
    }

    func addCarpool(_ carpool: Carpool) async throws -> String {
        var carpoolToSave = carpool
        carpoolToSave.updatedAt = Date()

        let docRef = try await db.collection("events")
            .document(carpool.eventId)
            .collection("carpools")
            .addDocument(from: carpoolToSave)

        await loadCarpools(for: carpool.eventId)
        return docRef.documentID
    }

    func updateCarpool(_ carpool: Carpool) async throws {
        guard let carpoolId = carpool.id else {
            throw CarpoolError.invalidCarpoolId
        }

        var carpoolToUpdate = carpool
        carpoolToUpdate.updatedAt = Date()

        try await db.collection("events")
            .document(carpool.eventId)
            .collection("carpools")
            .document(carpoolId)
            .setData(from: carpoolToUpdate)

        await loadCarpools(for: carpool.eventId)
    }

    func deleteCarpool(_ carpool: Carpool) async throws {
        guard let carpoolId = carpool.id else {
            throw CarpoolError.invalidCarpoolId
        }

        // Cancel all bookings for this carpool first
        if let carpoolBookings = bookings[carpoolId] {
            for booking in carpoolBookings {
                try await cancelBooking(booking)
            }
        }

        // Delete the carpool
        try await db.collection("events")
            .document(carpool.eventId)
            .collection("carpools")
            .document(carpoolId)
            .delete()

        await loadCarpools(for: carpool.eventId)
    }

    // MARK: - Booking Management

    func loadBookings(for carpoolId: String, eventId: String) async {
        do {
            let snapshot = try await db.collection("events")
                .document(eventId)
                .collection("carpools")
                .document(carpoolId)
                .collection("bookings")
                .order(by: "bookedAt")
                .getDocuments()

            let carpoolBookings = snapshot.documents.compactMap { document in
                try? document.data(as: CarpoolBooking.self)
            }

            bookings[carpoolId] = carpoolBookings
        } catch {
            print("Error loading bookings: \(error)")
        }
    }

    func bookSeat(
        carpoolId: String,
        eventId: String,
        parentId: String,
        parentName: String,
        playerId: String? = nil,
        playerName: String? = nil,
        parentPhone: String? = nil,
        emergencyContact: String? = nil,
        specialRequests: String? = nil
    ) async throws {
        // Check if carpool has available seats
        guard var carpool = await getCarpool(id: carpoolId, eventId: eventId),
              carpool.availableSeats > 0 else {
            throw CarpoolError.noAvailableSeats
        }

        // Check if user already has a booking for this carpool
        let existingBooking = await getUserBooking(carpoolId: carpoolId, eventId: eventId, userId: parentId)
        if existingBooking?.isActive == true {
            throw CarpoolError.alreadyBooked
        }

        let booking = CarpoolBooking(
            carpoolId: carpoolId,
            eventId: eventId,
            parentId: parentId,
            parentName: parentName,
            playerId: playerId,
            playerName: playerName,
            parentPhone: parentPhone,
            emergencyContact: emergencyContact,
            specialRequests: specialRequests
        )

        // Use a transaction to ensure atomicity
        try await db.runTransaction { transaction, errorPointer in
            let carpoolRef = self.db.collection("events")
                .document(eventId)
                .collection("carpools")
                .document(carpoolId)

            let bookingRef = carpoolRef
                .collection("bookings")
                .document(parentId)

            do {
                let carpoolSnapshot = try transaction.getDocument(carpoolRef)
                guard var currentCarpool = try? carpoolSnapshot.data(as: Carpool.self),
                      currentCarpool.availableSeats > 0 else {
                    throw CarpoolError.noAvailableSeats
                }

                // Update carpool available seats
                currentCarpool.availableSeats -= 1
                currentCarpool.updatedAt = Date()

                try transaction.setData(from: currentCarpool, forDocument: carpoolRef)
                try transaction.setData(from: booking, forDocument: bookingRef)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        await loadCarpools(for: eventId)
        await loadBookings(for: carpoolId, eventId: eventId)
    }

    func cancelBooking(_ booking: CarpoolBooking) async throws {
        guard let bookingId = booking.id else {
            throw CarpoolError.invalidBookingId
        }

        // Use a transaction to ensure atomicity
        try await db.runTransaction { transaction, errorPointer in
            let carpoolRef = self.db.collection("events")
                .document(booking.eventId)
                .collection("carpools")
                .document(booking.carpoolId)

            let bookingRef = carpoolRef
                .collection("bookings")
                .document(booking.parentId)

            do {
                let carpoolSnapshot = try transaction.getDocument(carpoolRef)
                guard var currentCarpool = try? carpoolSnapshot.data(as: Carpool.self) else {
                    throw CarpoolError.carpoolNotFound
                }

                // Update booking status to cancelled
                var updatedBooking = booking
                updatedBooking.status = .cancelled
                updatedBooking.updatedAt = Date()

                // Return seat to carpool if booking was confirmed
                if booking.status == .confirmed {
                    currentCarpool.availableSeats += 1
                    currentCarpool.updatedAt = Date()
                }

                try transaction.setData(from: currentCarpool, forDocument: carpoolRef)
                try transaction.setData(from: updatedBooking, forDocument: bookingRef)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        await loadCarpools(for: booking.eventId)
        await loadBookings(for: booking.carpoolId, eventId: booking.eventId)
    }

    // MARK: - Query Methods

    func getCarpool(id: String, eventId: String) async -> Carpool? {
        do {
            let document = try await db.collection("events")
                .document(eventId)
                .collection("carpools")
                .document(id)
                .getDocument()

            return try? document.data(as: Carpool.self)
        } catch {
            print("Error getting carpool: \(error)")
            return nil
        }
    }

    func getUserBooking(carpoolId: String, eventId: String, userId: String) async -> CarpoolBooking? {
        do {
            let document = try await db.collection("events")
                .document(eventId)
                .collection("carpools")
                .document(carpoolId)
                .collection("bookings")
                .document(userId)
                .getDocument()

            return try? document.data(as: CarpoolBooking.self)
        } catch {
            print("Error getting user booking: \(error)")
            return nil
        }
    }

    func getUserBookingsForEvent(eventId: String, userId: String) async -> [CarpoolBooking] {
        guard let eventCarpools = carpools[eventId] else { return [] }

        var userBookings: [CarpoolBooking] = []

        for carpool in eventCarpools {
            guard let carpoolId = carpool.id else { continue }

            if let booking = await getUserBooking(carpoolId: carpoolId, eventId: eventId, userId: userId) {
                userBookings.append(booking)
            }
        }

        return userBookings.filter { $0.isActive }
    }

    func getCarpoolSummaries(for eventId: String) async -> [CarpoolSummary] {
        guard let eventCarpools = carpools[eventId] else { return [] }

        var summaries: [CarpoolSummary] = []

        for carpool in eventCarpools {
            guard let carpoolId = carpool.id else { continue }

            await loadBookings(for: carpoolId, eventId: eventId)
            let carpoolBookings = bookings[carpoolId] ?? []

            summaries.append(CarpoolSummary.from(carpool: carpool, bookings: carpoolBookings))
        }

        return summaries
    }

    // MARK: - Utility Methods

    func getAvailableCarpools(for eventId: String) -> [Carpool] {
        guard let eventCarpools = carpools[eventId] else { return [] }
        return eventCarpools.filter { $0.availableSeats > 0 && $0.isActive }
    }

    func getTotalAvailableSeats(for eventId: String) -> Int {
        let available = getAvailableCarpools(for: eventId)
        return available.reduce(0) { $0 + $1.availableSeats }
    }

    func canUserDriveCarpool(userId: String, eventId: String) async -> Bool {
        guard let eventCarpools = carpools[eventId] else { return true }

        // Check if user already registered as driver for this event
        return !eventCarpools.contains { $0.driverId == userId }
    }
}

enum CarpoolError: LocalizedError {
    case invalidCarpoolId
    case invalidBookingId
    case noAvailableSeats
    case alreadyBooked
    case carpoolNotFound
    case bookingNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCarpoolId:
            return "無効な相乗りIDです。"
        case .invalidBookingId:
            return "無効な予約IDです。"
        case .noAvailableSeats:
            return "空席がありません。"
        case .alreadyBooked:
            return "既に予約済みです。"
        case .carpoolNotFound:
            return "相乗りが見つかりません。"
        case .bookingNotFound:
            return "予約が見つかりません。"
        }
    }
}