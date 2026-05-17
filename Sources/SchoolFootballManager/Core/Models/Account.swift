import Foundation

enum AccountRole: String, CaseIterable {
    case manager = "manager"
    case parent  = "parent"

    var displayName: String {
        switch self {
        case .manager: return "監督"
        case .parent:  return "保護者"
        }
    }

    var icon: String {
        switch self {
        case .manager: return "person.crop.circle.badge.checkmark"
        case .parent:  return "figure.and.child.holdinghands"
        }
    }
}

struct Account: Identifiable, Equatable {
    var id: String
    var username: String
    var password: String
    var displayName: String
    var role: AccountRole
    var linkedPlayerIds: [String]   // parent only — which players they manage

    init(username: String, password: String, displayName: String,
         role: AccountRole, linkedPlayerIds: [String] = []) {
        self.id               = UUID().uuidString
        self.username         = username
        self.password         = password
        self.displayName      = displayName
        self.role             = role
        self.linkedPlayerIds  = linkedPlayerIds
    }
}
