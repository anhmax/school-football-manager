import Foundation
import FirebaseFirestoreSwift

struct MatchRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var playerId: String
    var teamId: String
    var opponentName: String
    var matchDate: Date
    var isHome: Bool
    var ourScore: Int
    var opponentScore: Int
    var playedAsGoalkeeper: Bool
    var goals: Int
    var assists: Int
    var yellowCards: Int
    var redCards: Int
    var minutesPlayed: Int?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(playerId: String, teamId: String, opponentName: String, matchDate: Date,
         isHome: Bool = true, ourScore: Int = 0, opponentScore: Int = 0,
         playedAsGoalkeeper: Bool = false, goals: Int = 0, assists: Int = 0,
         yellowCards: Int = 0, redCards: Int = 0, minutesPlayed: Int? = nil,
         notes: String? = nil) {
        self.playerId = playerId
        self.teamId = teamId
        self.opponentName = opponentName
        self.matchDate = matchDate
        self.isHome = isHome
        self.ourScore = ourScore
        self.opponentScore = opponentScore
        self.playedAsGoalkeeper = playedAsGoalkeeper
        self.goals = goals
        self.assists = assists
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.minutesPlayed = minutesPlayed
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var result: MatchResult {
        if ourScore > opponentScore {
            return .win
        } else if ourScore < opponentScore {
            return .loss
        } else {
            return .draw
        }
    }

    var resultDisplayText: String {
        return "\(ourScore) - \(opponentScore)"
    }

    var resultWithOpponent: String {
        let homeAwayText = isHome ? "vs" : "@"
        return "\(homeAwayText) \(opponentName) \(resultDisplayText)"
    }

    var shortResultText: String {
        return "\(result.displayName) \(resultDisplayText)"
    }
}

enum MatchResult: String, CaseIterable, Codable {
    case win = "win"
    case loss = "loss"
    case draw = "draw"

    var displayName: String {
        switch self {
        case .win:
            return "勝利"
        case .loss:
            return "敗北"
        case .draw:
            return "引き分け"
        }
    }

    var emoji: String {
        switch self {
        case .win:
            return "🏆"
        case .loss:
            return "😔"
        case .draw:
            return "🤝"
        }
    }
}