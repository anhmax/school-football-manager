import SwiftUI

struct PlayerAvatarView: View {
    let profilePhotoURL: String?
    let playerName: String
    let size: AvatarSize
    let showBorder: Bool

    init(
        profilePhotoURL: String? = nil,
        playerName: String,
        size: AvatarSize = .medium,
        showBorder: Bool = false
    ) {
        self.profilePhotoURL = profilePhotoURL
        self.playerName = playerName
        self.size = size
        self.showBorder = showBorder
    }

    var body: some View {
        Group {
            if let urlString = profilePhotoURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(showBorder ? Color.separator : Color.clear, lineWidth: showBorder ? 1 : 0)
                )
            } else {
                placeholderView
            }
        }
        .accessibilityLabel("\(playerName)のプロフィール写真")
    }

    @ViewBuilder
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension, height: size.dimension)

            Text(initials)
                .font(size.font)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(showBorder ? Color.separator : Color.clear, lineWidth: showBorder ? 1 : 0)
        )
    }

    private var initials: String {
        let components = playerName.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = String(components[0].prefix(1))
            let lastInitial = String(components[1].prefix(1))
            return firstInitial + lastInitial
        } else {
            return String(playerName.prefix(2))
        }
    }
}

enum AvatarSize {
    case small
    case medium
    case large
    case extraLarge

    var dimension: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 48
        case .large: return 64
        case .extraLarge: return 96
        }
    }

    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .footnote
        case .large: return .headline
        case .extraLarge: return .title2
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            PlayerAvatarView(
                playerName: "田中太郎",
                size: .small
            )
            PlayerAvatarView(
                playerName: "鈴木次郎",
                size: .medium,
                showBorder: true
            )
            PlayerAvatarView(
                playerName: "佐藤三郎",
                size: .large
            )
            PlayerAvatarView(
                playerName: "高橋四郎",
                size: .extraLarge,
                showBorder: true
            )
        }

        VStack(spacing: 8) {
            Text("画像付きの例")
                .font(.caption)
                .foregroundColor(.secondary)

            PlayerAvatarView(
                profilePhotoURL: "https://example.com/photo.jpg",
                playerName: "山田花子",
                size: .medium,
                showBorder: true
            )
        }
    }
    .padding()
}

// MARK: - TeamAvatarView for Team Display

struct TeamAvatarView: View {
    let grade: Grade
    let size: AvatarSize
    let showBorder: Bool

    init(grade: Grade, size: AvatarSize = .medium, showBorder: Bool = false) {
        self.grade = grade
        self.size = size
        self.showBorder = showBorder
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.teamColor(for: grade))
                .frame(width: size.dimension, height: size.dimension)

            Text(grade.displayName.prefix(2))
                .font(size.font)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(showBorder ? Color.separator : Color.clear, lineWidth: showBorder ? 1 : 0)
        )
        .accessibilityLabel("\(grade.displayName)チーム")
    }
}

// MARK: - UserAvatarView for User Display

struct UserAvatarView: View {
    let userName: String
    let role: UserRole
    let size: AvatarSize
    let showBorder: Bool

    init(
        userName: String,
        role: UserRole,
        size: AvatarSize = .medium,
        showBorder: Bool = false
    ) {
        self.userName = userName
        self.role = role
        self.size = size
        self.showBorder = showBorder
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(roleColor)
                .frame(width: size.dimension, height: size.dimension)

            Text(initials)
                .font(size.font)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(showBorder ? Color.separator : Color.clear, lineWidth: showBorder ? 1 : 0)
        )
        .accessibilityLabel("\(userName) (\(role.displayName))")
    }

    private var roleColor: Color {
        switch role {
        case .admin:
            return .red
        case .manager:
            return .blue
        case .parent:
            return .green
        }
    }

    private var initials: String {
        let components = userName.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = String(components[0].prefix(1))
            let lastInitial = String(components[1].prefix(1))
            return firstInitial + lastInitial
        } else {
            return String(userName.prefix(2))
        }
    }
}