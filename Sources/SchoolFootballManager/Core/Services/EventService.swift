import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class EventService: ObservableObject {
    @Published var events: [Event] = []
    @Published var registrations: [String: [EventRegistration]] = [:] // eventId -> registrations
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()

    // MARK: - Event CRUD Operations

    func loadEvents(for teamId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            var query = db.collection("events").order(by: "eventDate", descending: false)

            if let teamId = teamId {
                query = query.whereField("teamId", isEqualTo: teamId)
            }

            let snapshot = try await query.getDocuments()
            events = snapshot.documents.compactMap { document in
                try? document.data(as: Event.self)
            }
        } catch {
            self.error = error.localizedDescription
            print("Error loading events: \(error)")
        }
    }

    func loadUpcomingEvents(for teamId: String? = nil, limit: Int = 10) async {
        isLoading = true
        defer { isLoading = false }

        do {
            var query = db.collection("events")
                .whereField("eventDate", isGreaterThan: Date())
                .order(by: "eventDate", descending: false)
                .limit(to: limit)

            if let teamId = teamId {
                query = query.whereField("teamId", isEqualTo: teamId)
            }

            let snapshot = try await query.getDocuments()
            events = snapshot.documents.compactMap { document in
                try? document.data(as: Event.self)
            }
        } catch {
            self.error = error.localizedDescription
            print("Error loading upcoming events: \(error)")
        }
    }

    func addEvent(_ event: Event) async throws -> String {
        var eventToSave = event
        eventToSave.updatedAt = Date()

        let docRef = try await db.collection("events").addDocument(from: eventToSave)
        await loadEvents(for: event.teamId)
        return docRef.documentID
    }

    func updateEvent(_ event: Event) async throws {
        guard let eventId = event.id else {
            throw EventError.invalidEventId
        }

        var eventToUpdate = event
        eventToUpdate.updatedAt = Date()

        try await db.collection("events").document(eventId).setData(from: eventToUpdate)
        await loadEvents(for: event.teamId)
    }

    func deleteEvent(_ event: Event) async throws {
        guard let eventId = event.id else {
            throw EventError.invalidEventId
        }

        // Delete all registrations for this event
        let registrationsSnapshot = try await db.collection("events")
            .document(eventId)
            .collection("registrations")
            .getDocuments()

        let batch = db.batch()
        for document in registrationsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }

        // Delete all carpools for this event
        let carpoolsSnapshot = try await db.collection("events")
            .document(eventId)
            .collection("carpools")
            .getDocuments()

        for carpoolDoc in carpoolsSnapshot.documents {
            // Delete all bookings for each carpool
            let bookingsSnapshot = try await carpoolDoc.reference
                .collection("bookings")
                .getDocuments()

            for bookingDoc in bookingsSnapshot.documents {
                batch.deleteDocument(bookingDoc.reference)
            }

            batch.deleteDocument(carpoolDoc.reference)
        }

        // Delete the event itself
        batch.deleteDocument(db.collection("events").document(eventId))

        try await batch.commit()
        await loadEvents(for: event.teamId)
    }

    // MARK: - Registration Management

    func loadRegistrations(for eventId: String) async {
        do {
            let snapshot = try await db.collection("events")
                .document(eventId)
                .collection("registrations")
                .order(by: "registeredAt")
                .getDocuments()

            let eventRegistrations = snapshot.documents.compactMap { document in
                try? document.data(as: EventRegistration.self)
            }

            registrations[eventId] = eventRegistrations
        } catch {
            print("Error loading registrations: \(error)")
        }
    }

    func registerForEvent(
        eventId: String,
        userId: String,
        userName: String,
        playerId: String? = nil,
        playerName: String? = nil,
        status: AttendanceStatus = .notConfirmed
    ) async throws {
        let registration = EventRegistration(
            eventId: eventId,
            userId: userId,
            userName: userName,
            playerId: playerId,
            playerName: playerName,
            status: status
        )

        try await db.collection("events")
            .document(eventId)
            .collection("registrations")
            .document(userId)
            .setData(from: registration)

        await loadRegistrations(for: eventId)
    }

    func updateRegistrationStatus(
        eventId: String,
        userId: String,
        status: AttendanceStatus,
        notes: String? = nil
    ) async throws {
        let updateData: [String: Any] = [
            "status": status.rawValue,
            "notes": notes as Any,
            "updatedAt": Date()
        ]

        try await db.collection("events")
            .document(eventId)
            .collection("registrations")
            .document(userId)
            .updateData(updateData)

        await loadRegistrations(for: eventId)
    }

    func getRegistration(eventId: String, userId: String) async -> EventRegistration? {
        do {
            let document = try await db.collection("events")
                .document(eventId)
                .collection("registrations")
                .document(userId)
                .getDocument()

            return try? document.data(as: EventRegistration.self)
        } catch {
            print("Error getting registration: \(error)")
            return nil
        }
    }

    func getAttendanceSummary(for eventId: String) -> EventAttendanceSummary? {
        guard let eventRegistrations = registrations[eventId] else { return nil }
        return EventAttendanceSummary.from(registrations: eventRegistrations)
    }

    // MARK: - Utility Methods

    func getEventsInDateRange(from startDate: Date, to endDate: Date, teamId: String? = nil) -> [Event] {
        var filteredEvents = events.filter { event in
            event.eventDate >= startDate && event.eventDate <= endDate
        }

        if let teamId = teamId {
            filteredEvents = filteredEvents.filter { $0.teamId == teamId }
        }

        return filteredEvents.sorted { $0.eventDate < $1.eventDate }
    }

    func getEventsByType(_ type: EventType, teamId: String? = nil) -> [Event] {
        var filteredEvents = events.filter { $0.type == type }

        if let teamId = teamId {
            filteredEvents = filteredEvents.filter { $0.teamId == teamId }
        }

        return filteredEvents.sorted { $0.eventDate < $1.eventDate }
    }

    func getUpcomingEventsCount(for teamId: String) -> Int {
        let upcoming = events.filter { event in
            event.teamId == teamId && event.eventDate > Date()
        }
        return upcoming.count
    }

    func hasRegistrationDeadlinePassed(_ event: Event) -> Bool {
        guard let deadline = event.registrationDeadline else { return false }
        return Date() > deadline
    }

    func canUserRegister(_ event: Event, userId: String) -> Bool {
        if event.isPast || !event.isRegistrationOpen {
            return false
        }

        if hasRegistrationDeadlinePassed(event) {
            return false
        }

        return true
    }

    func searchEvents(query: String, teamId: String? = nil) -> [Event] {
        let lowercaseQuery = query.lowercased()
        var searchableEvents = events

        if let teamId = teamId {
            searchableEvents = searchableEvents.filter { $0.teamId == teamId }
        }

        return searchableEvents.filter { event in
            event.title.lowercased().contains(lowercaseQuery) ||
            event.venue.lowercased().contains(lowercaseQuery) ||
            event.type.displayName.lowercased().contains(lowercaseQuery)
        }
    }
}

enum EventError: LocalizedError {
    case invalidEventId
    case registrationClosed
    case registrationNotFound

    var errorDescription: String? {
        switch self {
        case .invalidEventId:
            return "無効なイベントIDです。"
        case .registrationClosed:
            return "登録受付は終了しています。"
        case .registrationNotFound:
            return "登録情報が見つかりません。"
        }
    }
}