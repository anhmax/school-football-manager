import Foundation
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit

@MainActor
class PlayerService: ObservableObject {
    @Published var players: [Player] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Player CRUD Operations

    func loadPlayers(for teamId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("teams")
                .document(teamId)
                .collection("players")
                .order(by: "jerseyNumber")
                .getDocuments()

            players = snapshot.documents.compactMap { document in
                try? document.data(as: Player.self)
            }
        } catch {
            self.error = error.localizedDescription
            print("Error loading players: \(error)")
        }
    }

    func addPlayer(_ player: Player) async throws -> String {
        // Check for duplicate jersey number
        if await isDuplicateJerseyNumber(player.jerseyNumber, in: player.teamId, excluding: nil) {
            throw PlayerError.duplicateJerseyNumber
        }

        var playerToSave = player
        playerToSave.updatedAt = Date()

        let docRef = try await db.collection("teams")
            .document(player.teamId)
            .collection("players")
            .addDocument(from: playerToSave)

        // Update team player count
        await updateTeamPlayerCount(teamId: player.teamId)

        return docRef.documentID
    }

    func updatePlayer(_ player: Player) async throws {
        guard let playerId = player.id else {
            throw PlayerError.invalidPlayerId
        }

        // Check for duplicate jersey number
        if await isDuplicateJerseyNumber(player.jerseyNumber, in: player.teamId, excluding: playerId) {
            throw PlayerError.duplicateJerseyNumber
        }

        var playerToUpdate = player
        playerToUpdate.updatedAt = Date()

        try await db.collection("teams")
            .document(player.teamId)
            .collection("players")
            .document(playerId)
            .setData(from: playerToUpdate)

        // Refresh local data
        await loadPlayers(for: player.teamId)
    }

    func deletePlayer(_ player: Player) async throws {
        guard let playerId = player.id else {
            throw PlayerError.invalidPlayerId
        }

        // Delete player document
        try await db.collection("teams")
            .document(player.teamId)
            .collection("players")
            .document(playerId)
            .delete()

        // Delete profile photo if exists
        if let photoURL = player.profilePhotoURL {
            await deleteProfilePhoto(url: photoURL)
        }

        // Update team player count
        await updateTeamPlayerCount(teamId: player.teamId)

        // Refresh local data
        await loadPlayers(for: player.teamId)
    }

    // MARK: - Photo Management

    func uploadProfilePhoto(_ image: UIImage, for playerId: String, teamId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw PlayerError.invalidImage
        }

        let fileName = "profile_\(playerId)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = storage.reference()
            .child("teams")
            .child(teamId)
            .child("players")
            .child(playerId)
            .child(fileName)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()

        return downloadURL.absoluteString
    }

    func deleteProfilePhoto(url: String) async {
        do {
            let photoRef = storage.reference(forURL: url)
            try await photoRef.delete()
        } catch {
            print("Error deleting profile photo: \(error)")
        }
    }

    // MARK: - Search and Filter

    func searchPlayers(query: String, in teamId: String) -> [Player] {
        let lowercaseQuery = query.lowercased()
        return players.filter { player in
            player.teamId == teamId && (
                player.name.lowercased().contains(lowercaseQuery) ||
                String(player.jerseyNumber).contains(lowercaseQuery) ||
                player.position.displayName.lowercased().contains(lowercaseQuery)
            )
        }
    }

    func filterPlayers(by position: Position, in teamId: String) -> [Player] {
        return players.filter { player in
            player.teamId == teamId && player.position == position
        }
    }

    func getPlayersByPosition(in teamId: String) -> [Position: [Player]] {
        let teamPlayers = players.filter { $0.teamId == teamId }
        return Dictionary(grouping: teamPlayers) { $0.position }
    }

    // MARK: - Utility Methods

    private func isDuplicateJerseyNumber(_ number: Int, in teamId: String, excluding playerId: String?) async -> Bool {
        do {
            var query = db.collection("teams")
                .document(teamId)
                .collection("players")
                .whereField("jerseyNumber", isEqualTo: number)

            let snapshot = try await query.getDocuments()

            if let excludingId = playerId {
                // Check if any document other than the excluded one has this jersey number
                return snapshot.documents.contains { $0.documentID != excludingId }
            } else {
                // For new players, any existing document with this number is a duplicate
                return !snapshot.documents.isEmpty
            }
        } catch {
            print("Error checking duplicate jersey number: \(error)")
            return false
        }
    }

    private func updateTeamPlayerCount(teamId: String) async {
        do {
            let snapshot = try await db.collection("teams")
                .document(teamId)
                .collection("players")
                .getDocuments()

            try await db.collection("teams")
                .document(teamId)
                .updateData([
                    "playerCount": snapshot.count,
                    "updatedAt": Date()
                ])
        } catch {
            print("Error updating team player count: \(error)")
        }
    }

    func getAvailableJerseyNumbers(for teamId: String, maxNumber: Int = 99) async -> [Int] {
        do {
            let snapshot = try await db.collection("teams")
                .document(teamId)
                .collection("players")
                .getDocuments()

            let usedNumbers = Set(snapshot.documents.compactMap { document in
                try? document.data(as: Player.self)
            }.map { $0.jerseyNumber })

            return (1...maxNumber).filter { !usedNumbers.contains($0) }
        } catch {
            print("Error getting available jersey numbers: \(error)")
            return Array(1...maxNumber)
        }
    }

    func getPlayer(id: String, in teamId: String) async -> Player? {
        do {
            let document = try await db.collection("teams")
                .document(teamId)
                .collection("players")
                .document(id)
                .getDocument()

            return try? document.data(as: Player.self)
        } catch {
            print("Error getting player: \(error)")
            return nil
        }
    }
}

enum PlayerError: LocalizedError {
    case duplicateJerseyNumber
    case invalidPlayerId
    case invalidImage
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .duplicateJerseyNumber:
            return "この背番号は既に使用されています。"
        case .invalidPlayerId:
            return "無効な選手IDです。"
        case .invalidImage:
            return "無効な画像ファイルです。"
        case .uploadFailed:
            return "画像のアップロードに失敗しました。"
        }
    }
}