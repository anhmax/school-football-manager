import Foundation
import FirebaseFirestoreSwift

enum Position: String, CaseIterable, Codable {
    case forward = "forward"
    case midfielder = "midfielder"
    case defender = "defender"
    case goalkeeper = "goalkeeper"

    var displayName: String {
        switch self {
        case .forward:
            return "フォワード"
        case .midfielder:
            return "ミッドフィールダー"
        case .defender:
            return "ディフェンダー"
        case .goalkeeper:
            return "ゴールキーパー"
        }
    }

    var shortName: String {
        switch self {
        case .forward:
            return "FW"
        case .midfielder:
            return "MF"
        case .defender:
            return "DF"
        case .goalkeeper:
            return "GK"
        }
    }
}

enum BloodType: String, CaseIterable, Codable {
    case a = "A"
    case b = "B"
    case ab = "AB"
    case o = "O"

    var displayName: String {
        return "\(rawValue)型"
    }
}

struct Player: Codable, Identifiable {
    @DocumentID var id: String?
    var teamId: String
    var name: String
    var jerseyNumber: Int
    var position: Position
    var birthday: Date
    var weight: Double
    var height: Double
    var bloodType: BloodType
    var profilePhotoURL: String?
    var parentId: String?
    var parentName: String?
    var createdAt: Date
    var updatedAt: Date

    init(teamId: String, name: String, jerseyNumber: Int, position: Position,
         birthday: Date, weight: Double, height: Double, bloodType: BloodType,
         parentId: String? = nil, parentName: String? = nil) {
        self.teamId = teamId
        self.name = name
        self.jerseyNumber = jerseyNumber
        self.position = position
        self.birthday = birthday
        self.weight = weight
        self.height = height
        self.bloodType = bloodType
        self.parentId = parentId
        self.parentName = parentName
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        return ageComponents.year ?? 0
    }

    var displayInfo: String {
        return "No.\(jerseyNumber) | \(position.shortName) | \(age)歳"
    }

    var fullDisplayInfo: String {
        return "\(name) (No.\(jerseyNumber)) - \(position.displayName)"
    }
}