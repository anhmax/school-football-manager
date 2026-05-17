import SwiftUI

struct StatBadgeView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let style: BadgeStyle

    init(
        title: String,
        value: String,
        icon: String,
        color: Color = .blue,
        style: BadgeStyle = .normal
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.style = style
    }

    var body: some View {
        VStack(spacing: style.spacing) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(style.iconFont)
                    .foregroundColor(color)

                if style.showTitle {
                    Text(title)
                        .font(style.titleFont)
                        .foregroundColor(.secondary)
                }
            }

            Text(value)
                .font(style.valueFont)
                .fontWeight(style.valueFontWeight)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(minWidth: style.minWidth)
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

enum BadgeStyle {
    case compact
    case normal
    case prominent

    var spacing: CGFloat {
        switch self {
        case .compact: return 2
        case .normal: return 4
        case .prominent: return 6
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .compact: return EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        case .normal: return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .prominent: return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        }
    }

    var minWidth: CGFloat {
        switch self {
        case .compact: return 60
        case .normal: return 80
        case .prominent: return 100
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: return 6
        case .normal: return 8
        case .prominent: return 12
        }
    }

    var backgroundColor: Color {
        Color.backgroundSecondary
    }

    var iconFont: Font {
        switch self {
        case .compact: return .caption
        case .normal: return .footnote
        case .prominent: return .subheadline
        }
    }

    var titleFont: Font {
        switch self {
        case .compact: return .caption2
        case .normal: return .caption
        case .prominent: return .footnote
        }
    }

    var valueFont: Font {
        switch self {
        case .compact: return .footnote
        case .normal: return .headline
        case .prominent: return .title2
        }
    }

    var valueFontWeight: Font.Weight {
        switch self {
        case .compact: return .semibold
        case .normal: return .bold
        case .prominent: return .bold
        }
    }

    var showTitle: Bool {
        self != .compact
    }
}

// MARK: - Specialized Badge Views

struct GoalsBadgeView: View {
    let goals: Int
    let style: BadgeStyle

    init(goals: Int, style: BadgeStyle = .normal) {
        self.goals = goals
        self.style = style
    }

    var body: some View {
        StatBadgeView(
            title: "ゴール",
            value: "\(goals)",
            icon: "soccer.ball",
            color: .green,
            style: style
        )
    }
}

struct AssistsBadgeView: View {
    let assists: Int
    let style: BadgeStyle

    init(assists: Int, style: BadgeStyle = .normal) {
        self.assists = assists
        self.style = style
    }

    var body: some View {
        StatBadgeView(
            title: "アシスト",
            value: "\(assists)",
            icon: "figure.soccer",
            color: .blue,
            style: style
        )
    }
}

struct GamesBadgeView: View {
    let games: Int
    let style: BadgeStyle

    init(games: Int, style: BadgeStyle = .normal) {
        self.games = games
        self.style = style
    }

    var body: some View {
        StatBadgeView(
            title: "試合数",
            value: "\(games)",
            icon: "sportscourt",
            color: .purple,
            style: style
        )
    }
}

struct WinsBadgeView: View {
    let wins: Int
    let style: BadgeStyle

    init(wins: Int, style: BadgeStyle = .normal) {
        self.wins = wins
        self.style = style
    }

    var body: some View {
        StatBadgeView(
            title: "勝利",
            value: "\(wins)",
            icon: "trophy",
            color: .matchWin,
            style: style
        )
    }
}

struct CardsBadgeView: View {
    let yellowCards: Int
    let redCards: Int
    let style: BadgeStyle

    init(yellowCards: Int, redCards: Int, style: BadgeStyle = .normal) {
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.style = style
    }

    var body: some View {
        HStack(spacing: 8) {
            if yellowCards > 0 {
                StatBadgeView(
                    title: "イエロー",
                    value: "\(yellowCards)",
                    icon: "rectangle.fill",
                    color: .yellow,
                    style: style
                )
            }

            if redCards > 0 {
                StatBadgeView(
                    title: "レッド",
                    value: "\(redCards)",
                    icon: "rectangle.fill",
                    color: .red,
                    style: style
                )
            }
        }
    }
}

struct PositionBadgeView: View {
    let position: Position
    let style: BadgeStyle

    init(position: Position, style: BadgeStyle = .compact) {
        self.position = position
        self.style = style
    }

    var body: some View {
        StatBadgeView(
            title: position.displayName,
            value: position.shortName,
            icon: positionIcon,
            color: Color.positionColor(for: position),
            style: style
        )
    }

    private var positionIcon: String {
        switch position {
        case .forward: return "figure.run"
        case .midfielder: return "figure.walk"
        case .defender: return "shield"
        case .goalkeeper: return "hand.raised"
        }
    }
}

struct AttendanceBadgeView: View {
    let status: AttendanceStatus
    let style: BadgeStyle

    init(status: AttendanceStatus, style: BadgeStyle = .compact) {
        self.status = status
        self.style = style
    }

    var body: some View {
        StatBadgeView(
            title: status.displayName,
            value: status.emoji,
            icon: statusIcon,
            color: Color.attendanceColor(for: status),
            style: style
        )
    }

    private var statusIcon: String {
        switch status {
        case .attending: return "checkmark.circle"
        case .absent: return "xmark.circle"
        case .notConfirmed: return "questionmark.circle"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Stat Badges")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                GoalsBadgeView(goals: 15)
                AssistsBadgeView(assists: 8)
                GamesBadgeView(games: 23)
                WinsBadgeView(wins: 18)
                PositionBadgeView(position: .forward)
                AttendanceBadgeView(status: .attending)
            }

            Divider()

            Text("Compact Style")
                .font(.title3)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                GoalsBadgeView(goals: 15, style: .compact)
                AssistsBadgeView(assists: 8, style: .compact)
                GamesBadgeView(games: 23, style: .compact)
                WinsBadgeView(wins: 18, style: .compact)
            }

            Divider()

            Text("Prominent Style")
                .font(.title3)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                GoalsBadgeView(goals: 15, style: .prominent)
                AssistsBadgeView(assists: 8, style: .prominent)
            }

            Divider()

            Text("Cards")
                .font(.title3)
                .fontWeight(.semibold)

            CardsBadgeView(yellowCards: 2, redCards: 1)
        }
        .padding()
    }
}