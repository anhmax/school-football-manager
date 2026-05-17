import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?

    // User-related computed properties
    var userRole: UserRole? {
        currentUser?.role
    }

    var userTeamId: String? {
        currentUser?.teamId
    }

    var userName: String? {
        currentUser?.name
    }

    var isUserApproved: Bool {
        currentUser?.isApproved ?? false
    }

    var canManageTeams: Bool {
        currentUser?.canManageTeam ?? false
    }

    var canViewAllTeams: Bool {
        currentUser?.canViewAllTeams ?? false
    }

    // Navigation state
    @Published var selectedTab: Int = 0
    @Published var navigationPath = NavigationPath()

    // Alert state
    @Published var showingAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    // Loading states for different features
    @Published var isLoadingPlayers: Bool = false
    @Published var isLoadingEvents: Bool = false
    @Published var isLoadingStats: Bool = false

    // Update user info
    func updateUser(_ user: AppUser?) {
        self.currentUser = user
        self.isLoggedIn = user?.isApproved ?? false

        if let user = user, !user.isApproved {
            showError("アカウントの承認待ちです。管理者の承認をお待ちください。")
        }
    }

    // Error handling
    func showError(_ message: String) {
        self.error = message
        self.alertTitle = "エラー"
        self.alertMessage = message
        self.showingAlert = true
    }

    func showSuccess(_ message: String) {
        self.alertTitle = "成功"
        self.alertMessage = message
        self.showingAlert = true
    }

    func showInfo(_ title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }

    func clearError() {
        self.error = nil
        self.showingAlert = false
    }

    // Loading state management
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func setPlayersLoading(_ isLoading: Bool) {
        self.isLoadingPlayers = isLoading
    }

    func setEventsLoading(_ isLoading: Bool) {
        self.isLoadingEvents = isLoading
    }

    func setStatsLoading(_ isLoading: Bool) {
        self.isLoadingStats = isLoading
    }

    // Navigation helpers
    func navigateToTab(_ tab: Int) {
        selectedTab = tab
    }

    func navigateToPlayerDetail(_ playerId: String) {
        navigationPath.append("player_\(playerId)")
    }

    func navigateToEventDetail(_ eventId: String) {
        navigationPath.append("event_\(eventId)")
    }

    func navigateToTeamDetail(_ teamId: String) {
        navigationPath.append("team_\(teamId)")
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }

    // Permission checks
    func canManageTeam(_ teamId: String) -> Bool {
        guard let user = currentUser else { return false }

        if user.role == .admin {
            return true
        }

        if user.role == .manager && user.isApproved && user.teamId == teamId {
            return true
        }

        return false
    }

    func canViewTeam(_ teamId: String) -> Bool {
        guard let user = currentUser else { return false }

        if user.role == .admin {
            return true
        }

        if user.role == .manager && user.isApproved && user.teamId == teamId {
            return true
        }

        if user.role == .parent && user.teamId == teamId {
            return true
        }

        return false
    }

    func canCreateEvent(for teamId: String) -> Bool {
        canManageTeam(teamId)
    }

    func canEditEvent(_ event: Event) -> Bool {
        guard let user = currentUser else { return false }

        if user.role == .admin {
            return true
        }

        if user.role == .manager && user.isApproved && user.teamId == event.teamId {
            return true
        }

        return false
    }

    func canAddPlayer(to teamId: String) -> Bool {
        canManageTeam(teamId)
    }

    func canEditPlayer(_ player: Player) -> Bool {
        canManageTeam(player.teamId)
    }

    func canViewStats(for teamId: String) -> Bool {
        canViewTeam(teamId)
    }

    func canManageRegistrations(for event: Event) -> Bool {
        canManageTeam(event.teamId)
    }

    // User role specific helpers
    func isDashboardAccessible() -> Bool {
        return isLoggedIn && isUserApproved
    }

    func getAccessibleTeams() -> [String] {
        guard let user = currentUser else { return [] }

        if user.role == .admin {
            return Grade.allCases.map { $0.rawValue }
        } else if let teamId = user.teamId {
            return [teamId]
        }

        return []
    }

    // Reset state on logout
    func reset() {
        currentUser = nil
        isLoggedIn = false
        isLoading = false
        error = nil
        selectedTab = 0
        navigationPath = NavigationPath()
        showingAlert = false
        alertTitle = ""
        alertMessage = ""
        isLoadingPlayers = false
        isLoadingEvents = false
        isLoadingStats = false
    }
}