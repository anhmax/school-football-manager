import Foundation

@MainActor
class AccountStore: ObservableObject {
    @Published var accounts: [Account]
    @Published var currentAccount: Account?
    @Published var loginError: String?

    init() {
        accounts = [
            Account(username: "admin", password: "1234",
                    displayName: "監督", role: .manager)
        ]
    }

    // MARK: - Auth

    var isManager: Bool { currentAccount?.role == .manager }
    var isParent:  Bool { currentAccount?.role == .parent  }

    @discardableResult
    func login(username: String, password: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        if let account = accounts.first(where: { $0.username == trimmed && $0.password == password }) {
            currentAccount = account
            loginError = nil
            return true
        }
        loginError = "ユーザー名またはパスワードが違います"
        return false
    }

    func logout() {
        currentAccount = nil
        loginError = nil
    }

    // MARK: - Account management (manager only)

    func addParentAccount(username: String, password: String,
                          displayName: String, linkedPlayerIds: [String]) {
        let account = Account(username: username, password: password,
                              displayName: displayName, role: .parent,
                              linkedPlayerIds: linkedPlayerIds)
        accounts.append(account)
    }

    func update(_ account: Account) {
        if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[idx] = account
        }
        if currentAccount?.id == account.id { currentAccount = account }
    }

    func delete(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
    }

    // MARK: - Helpers

    var parentAccounts: [Account] {
        accounts.filter { $0.role == .parent }
    }

    func linkedPlayers(from players: [Player]) -> [Player] {
        guard let ids = currentAccount?.linkedPlayerIds else { return [] }
        return players.filter { ids.contains($0.id ?? "") }
    }

    func canEdit(player: Player) -> Bool {
        if isManager { return true }
        return currentAccount?.linkedPlayerIds.contains(player.id ?? "") == true
    }
}
