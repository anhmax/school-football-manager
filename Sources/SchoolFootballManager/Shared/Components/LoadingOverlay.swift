import SwiftUI

struct LoadingOverlay: View {
    var message: String = "読み込み中..."
    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(1.2)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

struct LoadingRow: View {
    var height: CGFloat = 60

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
        .padding(.horizontal, 16)
        .shimmer(isActive: true)
    }
}

struct LoadingCard: View {
    var height: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .frame(maxWidth: .infinity)
                }
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 10)
                .frame(width: 100)
        }
        .padding(16)
        .frame(height: height)
        .cardStyle()
        .shimmer(isActive: true)
    }
}

struct LoadingState<Content: View>: View {
    let isLoading: Bool
    let content: Content

    init(isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.isLoading = isLoading
        self.content = content()
    }

    var body: some View {
        ZStack {
            content

            if isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Specialized Loading Views

struct PlayerLoadingRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 18)
                    .frame(maxWidth: 150)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .frame(maxWidth: 100)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
                    .frame(maxWidth: 80)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 20)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 30, height: 16)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .shimmer(isActive: true)
    }
}

struct EventLoadingRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(maxWidth: 200)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .frame(maxWidth: 150)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
                    .frame(maxWidth: 120)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 24)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shimmer(isActive: true)
    }
}

struct StatsLoadingGrid: View {
    let columns = Array(repeating: GridItem(.flexible()), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 24)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 14)
                }
                .padding(16)
                .cardStyle()
                .shimmer(isActive: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Loading Overlays")
                .font(.title2)
                .fontWeight(.bold)

            LoadingCard()

            Divider()

            Text("Loading Rows")
                .font(.title3)
                .fontWeight(.semibold)

            PlayerLoadingRow()
            EventLoadingRow()

            Divider()

            Text("Loading Grid")
                .font(.title3)
                .fontWeight(.semibold)

            StatsLoadingGrid()

            Divider()

            Text("Loading Buttons")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                LoadingButton(title: "保存", isLoading: false) {}
                LoadingButton(title: "読み込み中", isLoading: true) {}
            }
        }
        .padding()
    }
    .overlay(
        LoadingOverlay(message: "データを読み込んでいます...")
            .opacity(0.8)
    )
}