import Foundation
import FirebaseFirestoreSwift

struct PlayerStats: Codable, Identifiable {
    @DocumentID var id: String?
    var playerId: String
    var teamId: String
    var totalGames: Int
    var totalGoalkeeperGames: Int
    var totalGoals: Int
    var totalAssists: Int
    var totalYellowCards: Int
    var totalRedCards: Int
    var totalMinutesPlayed: Int
    var wins: Int
    var losses: Int
    var draws: Int
    var lastUpdated: Date

    init(playerId: String, teamId: String) {
        self.playerId = playerId
        self.teamId = teamId
        self.totalGames = 0
        self.totalGoalkeeperGames = 0
        self.totalGoals = 0
        self.totalAssists = 0
        self.totalYellowCards = 0
        self.totalRedCards = 0
        self.totalMinutesPlayed = 0
        self.wins = 0
        self.losses = 0
        self.draws = 0
        self.lastUpdated = Date()
    }

    var winPercentage: Double {
        guard totalGames > 0 else { return 0 }
        return Double(wins) / Double(totalGames) * 100
    }

    var goalsPerGame: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalGoals) / Double(totalGames)
    }

    var assistsPerGame: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalAssists) / Double(totalGames)
    }

    var averageMinutesPerGame: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalMinutesPlayed) / Double(totalGames)
    }

    var goalkeeperGamePercentage: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalGoalkeeperGames) / Double(totalGames) * 100
    }

    func updateWith(matchRecords: [MatchRecord]) {
        // This would be called when recalculating stats from match records
        // Implementation would aggregate all the match data
    }

    mutating func addMatchRecord(_ record: MatchRecord) {
        totalGames += 1
        totalGoals += record.goals
        totalAssists += record.assists
        totalYellowCards += record.yellowCards
        totalRedCards += record.redCards
        totalMinutesPlayed += record.minutesPlayed ?? 0

        if record.playedAsGoalkeeper {
            totalGoalkeeperGames += 1
        }

        switch record.result {
        case .win:
            wins += 1
        case .loss:
            losses += 1
        case .draw:
            draws += 1
        }

        lastUpdated = Date()
    }

    var displaySummary: [StatItem] {
        return [
            StatItem(title: "試合数", value: "\(totalGames)", icon: "sportscourt"),
            StatItem(title: "ゴール", value: "\(totalGoals)", icon: "soccer.ball"),
            StatItem(title: "アシスト", value: "\(totalAssists)", icon: "figure.soccer"),
            StatItem(title: "勝利", value: "\(wins)", icon: "trophy"),
            StatItem(title: "敗北", value: "\(losses)", icon: "xmark.circle"),
            StatItem(title: "引き分け", value: "\(draws)", icon: "minus.circle"),
            StatItem(title: "イエローカード", value: "\(totalYellowCards)", icon: "rectangle.fill"),
            StatItem(title: "レッドカード", value: "\(totalRedCards)", icon: "rectangle.fill")
        ]
    }
}

struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
}