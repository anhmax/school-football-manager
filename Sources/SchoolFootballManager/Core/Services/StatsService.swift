import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class StatsService: ObservableObject {
    @Published var playerStats: [String: PlayerStats] = [:] // playerId -> stats
    @Published var matchRecords: [String: [MatchRecord]] = [:] // playerId -> records
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()

    // MARK: - Match Records

    func loadMatchRecords(for playerId: String, in teamId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("teams")
                .document(teamId)
                .collection("players")
                .document(playerId)
                .collection("matchRecords")
                .order(by: "matchDate", descending: true)
                .getDocuments()

            let records = snapshot.documents.compactMap { document in
                try? document.data(as: MatchRecord.self)
            }

            matchRecords[playerId] = records
        } catch {
            self.error = error.localizedDescription
            print("Error loading match records: \(error)")
        }
    }

    func addMatchRecord(_ record: MatchRecord) async throws -> String {
        var recordToSave = record
        recordToSave.updatedAt = Date()

        let docRef = try await db.collection("teams")
            .document(record.teamId)
            .collection("players")
            .document(record.playerId)
            .collection("matchRecords")
            .addDocument(from: recordToSave)

        // Update player stats
        await updatePlayerStats(for: record.playerId, in: record.teamId)
        await loadMatchRecords(for: record.playerId, in: record.teamId)

        return docRef.documentID
    }

    func updateMatchRecord(_ record: MatchRecord) async throws {
        guard let recordId = record.id else {
            throw StatsError.invalidRecordId
        }

        var recordToUpdate = record
        recordToUpdate.updatedAt = Date()

        try await db.collection("teams")
            .document(record.teamId)
            .collection("players")
            .document(record.playerId)
            .collection("matchRecords")
            .document(recordId)
            .setData(from: recordToUpdate)

        // Update player stats
        await updatePlayerStats(for: record.playerId, in: record.teamId)
        await loadMatchRecords(for: record.playerId, in: record.teamId)
    }

    func deleteMatchRecord(_ record: MatchRecord) async throws {
        guard let recordId = record.id else {
            throw StatsError.invalidRecordId
        }

        try await db.collection("teams")
            .document(record.teamId)
            .collection("players")
            .document(record.playerId)
            .collection("matchRecords")
            .document(recordId)
            .delete()

        // Update player stats
        await updatePlayerStats(for: record.playerId, in: record.teamId)
        await loadMatchRecords(for: record.playerId, in: record.teamId)
    }

    // MARK: - Player Stats

    func loadPlayerStats(for playerId: String, in teamId: String) async {
        do {
            let document = try await db.collection("teams")
                .document(teamId)
                .collection("players")
                .document(playerId)
                .collection("stats")
                .document("current")
                .getDocument()

            if let stats = try? document.data(as: PlayerStats.self) {
                playerStats[playerId] = stats
            } else {
                // Create initial stats if they don't exist
                let initialStats = PlayerStats(playerId: playerId, teamId: teamId)
                playerStats[playerId] = initialStats
                try await savePlayerStats(initialStats)
            }
        } catch {
            print("Error loading player stats: \(error)")
        }
    }

    func updatePlayerStats(for playerId: String, in teamId: String) async {
        // Load all match records for the player
        await loadMatchRecords(for: playerId, in: teamId)

        guard let records = matchRecords[playerId] else { return }

        // Calculate new stats from all records
        var stats = PlayerStats(playerId: playerId, teamId: teamId)

        for record in records {
            stats.addMatchRecord(record)
        }

        // Save updated stats
        playerStats[playerId] = stats
        try? await savePlayerStats(stats)
    }

    private func savePlayerStats(_ stats: PlayerStats) async throws {
        try await db.collection("teams")
            .document(stats.teamId)
            .collection("players")
            .document(stats.playerId)
            .collection("stats")
            .document("current")
            .setData(from: stats)
    }

    // MARK: - Team Statistics

    func loadTeamStats(for teamId: String) async -> TeamStatsResponse {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load all players for the team
            let playersSnapshot = try await db.collection("teams")
                .document(teamId)
                .collection("players")
                .getDocuments()

            var allMatchRecords: [MatchRecord] = []
            var allPlayerStats: [PlayerStats] = []

            for playerDoc in playersSnapshot.documents {
                let playerId = playerDoc.documentID

                // Load match records for each player
                let recordsSnapshot = try await playerDoc.reference
                    .collection("matchRecords")
                    .getDocuments()

                let playerRecords = recordsSnapshot.documents.compactMap { doc in
                    try? doc.data(as: MatchRecord.self)
                }
                allMatchRecords.append(contentsOf: playerRecords)

                // Load stats for each player
                await loadPlayerStats(for: playerId, in: teamId)
                if let stats = playerStats[playerId] {
                    allPlayerStats.append(stats)
                }
            }

            return TeamStatsResponse(
                teamId: teamId,
                totalGames: Set(allMatchRecords.map { "\($0.opponentName)-\($0.matchDate)" }).count,
                totalPlayers: allPlayerStats.count,
                totalGoals: allPlayerStats.reduce(0) { $0 + $1.totalGoals },
                totalWins: calculateTeamWins(from: allMatchRecords),
                totalLosses: calculateTeamLosses(from: allMatchRecords),
                totalDraws: calculateTeamDraws(from: allMatchRecords),
                playerStats: allPlayerStats,
                recentMatches: Array(allMatchRecords.sorted { $0.matchDate > $1.matchDate }.prefix(5))
            )
        } catch {
            self.error = error.localizedDescription
            print("Error loading team stats: \(error)")
            return TeamStatsResponse(teamId: teamId)
        }
    }

    private func calculateTeamWins(from records: [MatchRecord]) -> Int {
        let uniqueMatches = Dictionary(grouping: records) { "\($0.opponentName)-\($0.matchDate)" }
        return uniqueMatches.values.count { matchRecords in
            guard let firstRecord = matchRecords.first else { return false }
            return firstRecord.result == .win
        }
    }

    private func calculateTeamLosses(from records: [MatchRecord]) -> Int {
        let uniqueMatches = Dictionary(grouping: records) { "\($0.opponentName)-\($0.matchDate)" }
        return uniqueMatches.values.count { matchRecords in
            guard let firstRecord = matchRecords.first else { return false }
            return firstRecord.result == .loss
        }
    }

    private func calculateTeamDraws(from records: [MatchRecord]) -> Int {
        let uniqueMatches = Dictionary(grouping: records) { "\($0.opponentName)-\($0.matchDate)" }
        return uniqueMatches.values.count { matchRecords in
            guard let firstRecord = matchRecords.first else { return false }
            return firstRecord.result == .draw
        }
    }

    // MARK: - Utility Methods

    func getTopScorers(in teamId: String, limit: Int = 5) async -> [PlayerStats] {
        let teamStats = await loadTeamStats(for: teamId)
        return Array(teamStats.playerStats
            .sorted { $0.totalGoals > $1.totalGoals }
            .prefix(limit))
    }

    func getTopAssists(in teamId: String, limit: Int = 5) async -> [PlayerStats] {
        let teamStats = await loadTeamStats(for: teamId)
        return Array(teamStats.playerStats
            .sorted { $0.totalAssists > $1.totalAssists }
            .prefix(limit))
    }

    func getMostActivePlayer(in teamId: String) async -> PlayerStats? {
        let teamStats = await loadTeamStats(for: teamId)
        return teamStats.playerStats
            .max { $0.totalGames < $1.totalGames }
    }

    func getMatchHistory(for teamId: String, limit: Int? = nil) async -> [MatchRecord] {
        let teamStats = await loadTeamStats(for: teamId)
        let sortedMatches = teamStats.recentMatches.sorted { $0.matchDate > $1.matchDate }

        if let limit = limit {
            return Array(sortedMatches.prefix(limit))
        } else {
            return sortedMatches
        }
    }

    func searchMatchRecords(query: String, in teamId: String) async -> [MatchRecord] {
        let teamStats = await loadTeamStats(for: teamId)
        let lowercaseQuery = query.lowercased()

        return teamStats.recentMatches.filter { record in
            record.opponentName.lowercased().contains(lowercaseQuery) ||
            record.resultWithOpponent.lowercased().contains(lowercaseQuery)
        }
    }
}

struct TeamStatsResponse {
    let teamId: String
    let totalGames: Int
    let totalPlayers: Int
    let totalGoals: Int
    let totalWins: Int
    let totalLosses: Int
    let totalDraws: Int
    let playerStats: [PlayerStats]
    let recentMatches: [MatchRecord]

    init(teamId: String, totalGames: Int = 0, totalPlayers: Int = 0, totalGoals: Int = 0,
         totalWins: Int = 0, totalLosses: Int = 0, totalDraws: Int = 0,
         playerStats: [PlayerStats] = [], recentMatches: [MatchRecord] = []) {
        self.teamId = teamId
        self.totalGames = totalGames
        self.totalPlayers = totalPlayers
        self.totalGoals = totalGoals
        self.totalWins = totalWins
        self.totalLosses = totalLosses
        self.totalDraws = totalDraws
        self.playerStats = playerStats
        self.recentMatches = recentMatches
    }

    var winPercentage: Double {
        let totalDecidedGames = totalWins + totalLosses
        guard totalDecidedGames > 0 else { return 0 }
        return Double(totalWins) / Double(totalDecidedGames) * 100
    }

    var averageGoalsPerGame: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalGoals) / Double(totalGames)
    }
}

enum StatsError: LocalizedError {
    case invalidRecordId
    case statsNotFound
    case calculationError

    var errorDescription: String? {
        switch self {
        case .invalidRecordId:
            return "無効な記録IDです。"
        case .statsNotFound:
            return "統計データが見つかりません。"
        case .calculationError:
            return "統計の計算中にエラーが発生しました。"
        }
    }
}