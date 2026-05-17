import SwiftUI

struct PlayerDetailView: View {
    @EnvironmentObject var playerStore: PlayerStore
    let player: Player

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss

    // Keep in sync with store edits
    var currentPlayer: Player {
        playerStore.players.first { $0.id == player.id } ?? player
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                infoGrid
                physicalGrid
            }
            .padding(16)
        }
        .background(Color.backgroundGrouped)
        .navigationTitle(currentPlayer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDeleteAlert = true } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditPlayerView(mode: .edit(currentPlayer))
        }
        .alert("選手を削除しますか？", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                playerStore.delete(currentPlayer)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(currentPlayer.name) のデータを削除します。この操作は取り消せません。")
        }
    }

    // MARK: - Subviews

    var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.positionColor(for: currentPlayer.position))
                    .frame(width: 90, height: 90)
                Text("\(currentPlayer.jerseyNumber)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 6) {
                Text(currentPlayer.name)
                    .font(.title2).fontWeight(.bold)

                HStack(spacing: 8) {
                    PositionBadge(position: currentPlayer.position)
                    Text("No. \(currentPlayer.jerseyNumber)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
    }

    var infoGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本情報")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InfoCell(label: "生年月日", value: currentPlayer.birthday.formatted(date: .abbreviated, time: .omitted))
                InfoCell(label: "年齢", value: "\(currentPlayer.age) 歳")
                InfoCell(label: "血液型", value: currentPlayer.bloodType.displayName)
                InfoCell(label: "チーム", value: Grade(rawValue: currentPlayer.teamId)?.displayName ?? currentPlayer.teamId)
            }
        }
    }

    var physicalGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("身体情報")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                PhysicalStatCard(value: "\(Int(currentPlayer.height))", unit: "cm", label: "身長")
                PhysicalStatCard(value: String(format: "%.1f", currentPlayer.weight), unit: "kg", label: "体重")
            }
        }
    }
}

// MARK: - Supporting Views

struct PositionBadge: View {
    let position: Position

    var body: some View {
        Text(position.displayName)
            .font(.subheadline).fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.positionColor(for: position).opacity(0.15))
            .foregroundColor(Color.positionColor(for: position))
            .cornerRadius(8)
    }
}

struct InfoCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.subheadline).fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

struct PhysicalStatCard: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}
