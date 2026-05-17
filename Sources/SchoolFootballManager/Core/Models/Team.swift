import Foundation
import FirebaseFirestoreSwift

enum Grade: String, CaseIterable, Codable {
    case first = "1nensei"
    case second = "2nensei"
    case third = "3nensei"
    case fourth = "4nensei"
    case fifth = "5nensei"
    case sixth = "6nensei"

    var displayName: String {
        switch self {
        case .first:
            return "1年生"
        case .second:
            return "2年生"
        case .third:
            return "3年生"
        case .fourth:
            return "4年生"
        case .fifth:
            return "5年生"
        case .sixth:
            return "6年生"
        }
    }

    var sortOrder: Int {
        switch self {
        case .first: return 1
        case .second: return 2
        case .third: return 3
        case .fourth: return 4
        case .fifth: return 5
        case .sixth: return 6
        }
    }
}

struct Team: Codable, Identifiable {
    @DocumentID var id: String?
    var grade: Grade
    var name: String
    var managerId: String?
    var playerCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(grade: Grade) {
        self.grade = grade
        self.name = "\(grade.displayName)チーム"
        self.playerCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var teamId: String {
        return grade.rawValue
    }

    static let allTeams: [Team] = Grade.allCases.map { grade in
        var team = Team(grade: grade)
        team.id = grade.rawValue
        return team
    }
}