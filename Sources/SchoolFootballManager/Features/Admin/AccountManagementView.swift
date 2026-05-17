import SwiftUI

struct AccountManagementView: View {
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var playerStore:  PlayerStore

    @State private var showingAdd = false
    @State private var editingAccount: Account? = nil

    var body: some View {
        NavigationStack {
            List {
                // Manager accounts (read-only)
                Section("監督") {
                    ForEach(accountStore.accounts.filter { $0.role == .manager }) { account in
                        AccountRow(account: account, players: playerStore.players)
                    }
                }

                // Parent accounts
                Section("保護者 (\(accountStore.parentAccounts.count)名)") {
                    if accountStore.parentAccounts.isEmpty {
                        Text("保護者アカウントなし")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(accountStore.parentAccounts) { account in
                            AccountRow(account: account, players: playerStore.players)
                                .contentShape(Rectangle())
                                .onTapGesture { editingAccount = account }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { accountStore.parentAccounts[$0] }
                            toDelete.forEach { accountStore.delete($0) }
                        }
                    }
                }
            }
            .navigationTitle("アカウント管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddParentAccountView()
            }
            .sheet(item: $editingAccount) { account in
                EditParentAccountView(account: account)
            }
        }
    }
}

// MARK: - Account Row

struct AccountRow: View {
    let account: Account
    let players: [Player]

    var linkedPlayers: [Player] {
        players.filter { account.linkedPlayerIds.contains($0.id ?? "") }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(account.role == .manager ? Color.footballBlue.opacity(0.15) : Color.footballGreen.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: account.role.icon)
                    .font(.system(size: 18))
                    .foregroundColor(account.role == .manager ? .footballBlue : .footballGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(account.displayName)
                    .font(.subheadline).fontWeight(.semibold)
                Text("@\(account.username)")
                    .font(.caption).foregroundColor(.secondary)
                if !linkedPlayers.isEmpty {
                    Text(linkedPlayers.map { $0.name }.joined(separator: "、"))
                        .font(.caption2).foregroundColor(.footballGreen)
                }
            }

            Spacer()

            Text(account.role.displayName)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(account.role == .manager ? Color.footballBlue.opacity(0.1) : Color.footballGreen.opacity(0.1))
                .foregroundColor(account.role == .manager ? .footballBlue : .footballGreen)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Parent Account

struct AddParentAccountView: View {
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var playerStore:  PlayerStore
    @Environment(\.dismiss) var dismiss

    @State private var displayName    = ""
    @State private var username       = ""
    @State private var password       = ""
    @State private var selectedIds:   Set<String> = []
    @State private var showPassword   = false
    @State private var usernameError  = ""

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("アカウント情報") {
                    HStack {
                        Text("表示名")
                        Spacer()
                        TextField("田中 花子", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("ユーザー名")
                        Spacer()
                        TextField("hanako", text: $username)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: username) { _ in usernameError = "" }
                    }

                    if !usernameError.isEmpty {
                        Text(usernameError)
                            .font(.caption).foregroundColor(.statusError)
                    }

                    HStack {
                        Text("パスワード")
                        Spacer()
                        Group {
                            if showPassword {
                                TextField("パスワード", text: $password)
                            } else {
                                SecureField("パスワード", text: $password)
                            }
                        }
                        .multilineTextAlignment(.trailing)
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("担当の選手（任意）") {
                    if playerStore.players.isEmpty {
                        Text("選手がまだ登録されていません")
                            .font(.subheadline).foregroundColor(.secondary)
                    } else {
                        ForEach(playerStore.players) { player in
                            HStack {
                                PlayerMiniRow(player: player)
                                Spacer()
                                Image(systemName: selectedIds.contains(player.id ?? "") ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedIds.contains(player.id ?? "") ? .footballGreen : .secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { togglePlayer(player) }
                        }
                    }
                }
            }
            .navigationTitle("保護者を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading)  { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func togglePlayer(_ player: Player) {
        guard let id = player.id else { return }
        if selectedIds.contains(id) { selectedIds.remove(id) }
        else { selectedIds.insert(id) }
    }

    private func save() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        if accountStore.accounts.contains(where: { $0.username == trimmedUsername }) {
            usernameError = "このユーザー名は既に使われています"
            return
        }
        accountStore.addParentAccount(
            username: trimmedUsername,
            password: password,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            linkedPlayerIds: Array(selectedIds)
        )
        dismiss()
    }
}

// MARK: - Edit Parent Account

struct EditParentAccountView: View {
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var playerStore:  PlayerStore
    @Environment(\.dismiss) var dismiss

    let account: Account
    @State private var displayName   = ""
    @State private var username      = ""
    @State private var password      = ""
    @State private var selectedIds:  Set<String> = []
    @State private var showPassword  = false

    init(account: Account) {
        self.account = account
        _displayName  = State(initialValue: account.displayName)
        _username     = State(initialValue: account.username)
        _password     = State(initialValue: account.password)
        _selectedIds  = State(initialValue: Set(account.linkedPlayerIds))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("アカウント情報") {
                    HStack {
                        Text("表示名")
                        Spacer()
                        TextField("表示名", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("ユーザー名")
                        Spacer()
                        TextField("ユーザー名", text: $username)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    HStack {
                        Text("パスワード")
                        Spacer()
                        Group {
                            if showPassword {
                                TextField("パスワード", text: $password)
                            } else {
                                SecureField("パスワード", text: $password)
                            }
                        }
                        .multilineTextAlignment(.trailing)
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("担当の選手") {
                    ForEach(playerStore.players) { player in
                        HStack {
                            PlayerMiniRow(player: player)
                            Spacer()
                            Image(systemName: selectedIds.contains(player.id ?? "") ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedIds.contains(player.id ?? "") ? .footballGreen : .secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { togglePlayer(player) }
                    }
                }
            }
            .navigationTitle("アカウントを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading)  { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func togglePlayer(_ player: Player) {
        guard let id = player.id else { return }
        if selectedIds.contains(id) { selectedIds.remove(id) }
        else { selectedIds.insert(id) }
    }

    private func save() {
        var updated = account
        updated.displayName      = displayName.trimmingCharacters(in: .whitespaces)
        updated.username         = username.trimmingCharacters(in: .whitespaces)
        updated.password         = password
        updated.linkedPlayerIds  = Array(selectedIds)
        accountStore.update(updated)
        dismiss()
    }
}

// MARK: - Shared mini player row

struct PlayerMiniRow: View {
    let player: Player
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.positionColor(for: player.position))
                    .frame(width: 32, height: 32)
                Text("\(player.jerseyNumber)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name).font(.subheadline)
                Text(player.position.displayName).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
