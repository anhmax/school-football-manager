import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - Specialized Empty States

struct NoPlayersEmptyState: View {
    let teamName: String
    let canAddPlayers: Bool
    let onAddPlayer: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "person.3",
            title: "選手がいません",
            message: "\(teamName)にはまだ選手が登録されていません。",
            actionTitle: canAddPlayers ? "選手を追加" : nil,
            action: canAddPlayers ? onAddPlayer : nil
        )
    }
}

struct NoEventsEmptyState: View {
    let canCreateEvents: Bool
    let onCreateEvent: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "calendar",
            title: "予定がありません",
            message: "まだ試合や練習の予定が登録されていません。",
            actionTitle: canCreateEvents ? "イベントを作成" : nil,
            action: canCreateEvents ? onCreateEvent : nil
        )
    }
}

struct NoMatchHistoryEmptyState: View {
    let playerName: String
    let canAddMatches: Bool
    let onAddMatch: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "sportscourt",
            title: "試合記録がありません",
            message: "\(playerName)の試合記録はまだありません。",
            actionTitle: canAddMatches ? "試合記録を追加" : nil,
            action: canAddMatches ? onAddMatch : nil
        )
    }
}

struct NoCarpoolsEmptyState: View {
    let eventTitle: String
    let canCreateCarpool: Bool
    let onCreateCarpool: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "car.2",
            title: "相乗りがありません",
            message: "\(eventTitle)の相乗り募集はまだありません。",
            actionTitle: canCreateCarpool ? "相乗りを登録" : nil,
            action: canCreateCarpool ? onCreateCarpool : nil
        )
    }
}

struct SearchEmptyState: View {
    let searchQuery: String

    var body: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "検索結果がありません",
            message: "「\(searchQuery)」に一致する結果が見つかりませんでした。"
        )
    }
}

struct NetworkErrorEmptyState: View {
    let onRetry: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "wifi.exclamationmark",
            title: "接続エラー",
            message: "インターネット接続を確認して、もう一度お試しください。",
            actionTitle: "再試行",
            action: onRetry
        )
    }
}

struct PermissionDeniedEmptyState: View {
    let permissionType: String

    var body: some View {
        EmptyStateView(
            icon: "lock.shield",
            title: "アクセス権限がありません",
            message: "\(permissionType)にアクセスする権限がありません。管理者にお問い合わせください。"
        )
    }
}

struct MaintenanceEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "wrench.and.screwdriver",
            title: "メンテナンス中",
            message: "現在システムメンテナンス中です。しばらく時間をおいてからお試しください。"
        )
    }
}

struct NoNotificationsEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "bell",
            title: "通知がありません",
            message: "新しい通知はありません。"
        )
    }
}

struct NoTeamsEmptyState: View {
    let canCreateTeams: Bool
    let onCreateTeam: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "person.3.sequence",
            title: "チームがありません",
            message: "まだチームが作成されていません。",
            actionTitle: canCreateTeams ? "チームを作成" : nil,
            action: canCreateTeams ? onCreateTeam : nil
        )
    }
}

// MARK: - Empty State with Animation

struct AnimatedEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - Preview

#Preview {
    TabView {
        NoPlayersEmptyState(
            teamName: "3年生チーム",
            canAddPlayers: true
        ) {
            print("Add player tapped")
        }
        .tabItem {
            Label("選手なし", systemImage: "person.3")
        }

        NoEventsEmptyState(canCreateEvents: true) {
            print("Create event tapped")
        }
        .tabItem {
            Label("イベントなし", systemImage: "calendar")
        }

        SearchEmptyState(searchQuery: "サッカー")
            .tabItem {
                Label("検索結果なし", systemImage: "magnifyingglass")
            }

        NetworkErrorEmptyState {
            print("Retry tapped")
        }
        .tabItem {
            Label("エラー", systemImage: "wifi.exclamationmark")
        }

        AnimatedEmptyStateView(
            icon: "star",
            title: "アニメーション付き",
            message: "これはアニメーション付きの空状態表示です。",
            actionTitle: "アクション",
            action: {
                print("Animated action tapped")
            }
        )
        .tabItem {
            Label("アニメーション", systemImage: "star")
        }
    }
}