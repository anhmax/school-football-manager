import SwiftUI

extension Color {
    // MARK: - App Brand Colors

    static let brandPrimary = Color("BrandPrimary")
    static let brandSecondary = Color("BrandSecondary")
    static let brandAccent = Color("BrandAccent")

    // MARK: - Football Team Colors

    static let footballGreen = Color(red: 0.2, green: 0.6, blue: 0.2)
    static let footballBlue = Color(red: 0.1, green: 0.4, blue: 0.8)
    static let footballRed = Color(red: 0.8, green: 0.2, blue: 0.2)
    static let footballOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let footballPurple = Color(red: 0.5, green: 0.2, blue: 0.8)
    static let footballYellow = Color(red: 1.0, green: 0.8, blue: 0.0)

    // MARK: - Status Colors

    static let statusSuccess = Color(red: 0.2, green: 0.7, blue: 0.2)
    static let statusWarning = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let statusError = Color(red: 0.8, green: 0.2, blue: 0.2)
    static let statusInfo = Color(red: 0.2, green: 0.6, blue: 1.0)

    // MARK: - Attendance Colors

    static let attendanceAttending = statusSuccess
    static let attendanceAbsent = statusError
    static let attendanceNotConfirmed = statusWarning

    // MARK: - Match Result Colors

    static let matchWin = Color(red: 0.1, green: 0.6, blue: 0.1)
    static let matchLoss = Color(red: 0.7, green: 0.1, blue: 0.1)
    static let matchDraw = Color(red: 0.5, green: 0.5, blue: 0.5)

    // MARK: - Position Colors

    static let positionForward = Color(red: 0.8, green: 0.2, blue: 0.2)
    static let positionMidfielder = Color(red: 0.2, green: 0.6, blue: 0.2)
    static let positionDefender = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let positionGoalkeeper = Color(red: 1.0, green: 0.6, blue: 0.0)

    // MARK: - Background Colors

    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    static let backgroundGrouped = Color(.systemGroupedBackground)
    static let backgroundGroupedSecondary = Color(.secondarySystemGroupedBackground)

    // MARK: - Text Colors

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let textQuaternary = Color(.quaternaryLabel)

    // MARK: - Separator Colors

    static let separator = Color(.separator)
    static let separatorOpaque = Color(.opaqueSeparator)

    // MARK: - Helper Methods

    static func teamColor(for grade: Grade) -> Color {
        switch grade {
        case .first:
            return .footballRed
        case .second:
            return .footballBlue
        case .third:
            return .footballGreen
        case .fourth:
            return .footballOrange
        case .fifth:
            return .footballPurple
        case .sixth:
            return .footballYellow
        }
    }

    static func positionColor(for position: Position) -> Color {
        switch position {
        case .forward:
            return .positionForward
        case .midfielder:
            return .positionMidfielder
        case .defender:
            return .positionDefender
        case .goalkeeper:
            return .positionGoalkeeper
        }
    }

    static func attendanceColor(for status: AttendanceStatus) -> Color {
        switch status {
        case .attending:
            return .attendanceAttending
        case .absent:
            return .attendanceAbsent
        case .notConfirmed:
            return .attendanceNotConfirmed
        }
    }

    static func matchResultColor(for result: MatchResult) -> Color {
        switch result {
        case .win:
            return .matchWin
        case .loss:
            return .matchLoss
        case .draw:
            return .matchDraw
        }
    }

    static func bookingStatusColor(for status: BookingStatus) -> Color {
        switch status {
        case .confirmed:
            return .statusSuccess
        case .cancelled:
            return .statusError
        case .pending:
            return .statusWarning
        }
    }
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = components[0]
        let g = components[1]
        let b = components[2]

        return String(format: "#%02lX%02lX%02lX", lround(Double(r * 255)), lround(Double(g * 255)), lround(Double(b * 255)))
    }
}

// MARK: - Gradient Helpers

extension Color {
    static func gradient(from: Color, to: Color) -> LinearGradient {
        LinearGradient(
            colors: [from, to],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var teamGradient: LinearGradient {
        LinearGradient(
            colors: [.footballBlue, .footballGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var statsGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var eventGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Dynamic Color Support

extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}