import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        Group {
            if let user = authService.currentUser {
                if user.isApproved {
                    switch user.role {
                    case .admin:
                        AdminDashboardView()
                    case .manager:
                        ManagerDashboardView()
                    case .parent:
                        ParentDashboardView()
                    }
                } else {
                    PendingApprovalView()
                }
            } else {
                LoadingView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToEvent"))) { notification in
            if let eventId = notification.userInfo?["eventId"] as? String {
                appState.navigateToEventDetail(eventId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTeam"))) { notification in
            if let teamId = notification.userInfo?["teamId"] as? String {
                appState.navigateToTeamDetail(teamId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToPlayer"))) { notification in
            if let playerId = notification.userInfo?["playerId"] as? String {
                appState.navigateToPlayerDetail(playerId)
            }
        }
    }
}

struct PendingApprovalView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "clock.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)

                VStack(spacing: 12) {
                    Text("承認待ち")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("アカウントの承認をお待ちください")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 16) {
                Text("管理者によるアカウントの承認が完了するまで、しばらくお待ちください。承認が完了次第、アプリをご利用いただけます。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let user = authService.currentUser {
                    VStack(spacing: 8) {
                        Text("登録情報")
                            .font(.headline)
                            .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("名前:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(user.name)
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("メール:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(user.email)
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("役割:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(user.role.displayName)
                                    .fontWeight(.medium)
                            }

                            if let teamId = user.teamId,
                               let grade = Grade(rawValue: teamId) {
                                HStack {
                                    Text("チーム:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(grade.displayName)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button("アカウント情報を更新") {
                    Task {
                        await authService.refreshUserData()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("ログアウト") {
                    Task {
                        try await authService.signOut()
                    }
                }
                .foregroundColor(.red)
            }
        }
        .padding(24)
        .navigationBarHidden(true)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("読み込み中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
        .navigationBarHidden(true)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    NavigationView {
        RootView()
    }
    .environmentObject(AppState())
    .environmentObject(AuthService())
}