import Foundation
import FirebaseFirestoreSwift

enum UserRole: String, CaseIterable, Codable {
    case admin = "admin"
    case manager = "manager"
    case parent = "parent"

    var displayName: String {
        switch self {
        case .admin:
            return "管理者"
        case .manager:
            return "監督"
        case .parent:
            return "保護者"
        }
    }
}

enum ApprovalStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .pending:
            return "承認待ち"
        case .approved:
            return "承認済み"
        case .rejected:
            return "拒否"
        }
    }
}

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var name: String
    var role: UserRole
    var teamId: String?
    var approvalStatus: ApprovalStatus
    var fcmToken: String?
    var createdAt: Date
    var updatedAt: Date

    init(email: String, name: String, role: UserRole, teamId: String? = nil, approvalStatus: ApprovalStatus = .pending) {
        self.email = email
        self.name = name
        self.role = role
        self.teamId = teamId
        self.approvalStatus = approvalStatus
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isApproved: Bool {
        approvalStatus == .approved
    }

    var canManageTeam: Bool {
        role == .admin || (role == .manager && isApproved)
    }

    var canViewAllTeams: Bool {
        role == .admin
    }
}