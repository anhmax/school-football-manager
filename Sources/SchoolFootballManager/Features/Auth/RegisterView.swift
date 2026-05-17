import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @State private var selectedRole: UserRole = .parent
    @State private var selectedTeam: Grade? = nil
    @State private var agreedToTerms: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    personalInfoSection

                    roleSection

                    if selectedRole != .admin {
                        teamSelectionSection
                    }

                    termsSection

                    registerButton

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("新規登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .errorAlert($authService.error)
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("アカウント作成")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("必要な情報を入力してアカウントを作成してください。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var personalInfoSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "個人情報")

            CustomTextField(
                title: "お名前",
                text: $name,
                icon: "person"
            )

            CustomTextField(
                title: "メールアドレス",
                text: $email,
                icon: "envelope"
            )
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)

            CustomSecureField(
                title: "パスワード",
                text: $password,
                icon: "lock"
            )

            CustomSecureField(
                title: "パスワード（確認）",
                text: $confirmPassword,
                icon: "lock.fill"
            )

            if !password.isEmpty && password != confirmPassword {
                Text("パスワードが一致しません")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var roleSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "役割")

            VStack(spacing: 12) {
                ForEach(UserRole.allCases.filter { $0 != .admin }, id: \.self) { role in
                    RoleSelectionRow(
                        role: role,
                        isSelected: selectedRole == role
                    ) {
                        selectedRole = role
                        if role == .admin {
                            selectedTeam = nil
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var teamSelectionSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "チーム選択")

            Text("管理または参加するチームを選択してください")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Grade.allCases, id: \.self) { grade in
                    TeamSelectionCard(
                        grade: grade,
                        isSelected: selectedTeam == grade
                    ) {
                        selectedTeam = grade
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var termsSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    agreedToTerms.toggle()
                } label: {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToTerms ? .blue : .secondary)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("利用規約とプライバシーポリシーに同意する")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("アカウント作成には管理者の承認が必要です。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                agreedToTerms.toggle()
            }
        }
    }

    @ViewBuilder
    private var registerButton: some View {
        LoadingButton(
            title: "アカウント作成",
            isLoading: authService.isLoading
        ) {
            Task {
                await register()
            }
        }
        .disabled(!isValidInput)
    }

    private var isValidInput: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreedToTerms &&
        (selectedRole == .admin || selectedTeam != nil)
    }

    private func register() async {
        hideKeyboard()

        let teamId = selectedRole == .admin ? nil : selectedTeam?.rawValue

        do {
            try await authService.signUp(
                email: email,
                password: password,
                name: name,
                role: selectedRole,
                teamId: teamId
            )

            // Show success message
            appState.showInfo(
                "登録完了",
                message: "アカウントが作成されました。管理者の承認をお待ちください。"
            )

            dismiss()
        } catch {
            // Error will be displayed through the error alert
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
    }
}

struct RoleSelectionRow: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(roleColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: roleIcon)
                        .foregroundColor(roleColor)
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(roleDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var roleColor: Color {
        switch role {
        case .admin: return .red
        case .manager: return .blue
        case .parent: return .green
        }
    }

    private var roleIcon: String {
        switch role {
        case .admin: return "crown"
        case .manager: return "sportscourt"
        case .parent: return "person.2"
        }
    }

    private var roleDescription: String {
        switch role {
        case .admin:
            return "全チームの管理、ユーザー承認"
        case .manager:
            return "チーム管理、選手登録、試合記録"
        case .parent:
            return "子供の情報確認、イベント参加"
        }
    }
}

struct TeamSelectionCard: View {
    let grade: Grade
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                TeamAvatarView(grade: grade, size: .large)

                Text(grade.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.teamColor(for: grade).opacity(0.1) : Color.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.teamColor(for: grade) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthService())
        .environmentObject(AppState())
}