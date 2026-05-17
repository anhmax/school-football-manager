import SwiftUI

struct PlayersView: View {
    @EnvironmentObject var playerStore: PlayerStore

    @State private var searchText = ""
    @State private var selectedPosition: Position? = nil
    @State private var showingAdd = false

    var filtered: [Player] {
        playerStore.players.filter { p in
            let matchesSearch = searchText.isEmpty
                || p.name.localizedCaseInsensitiveContains(searchText)
            let matchesPosition = selectedPosition == nil || p.position == selectedPosition
            return matchesSearch && matchesPosition
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                positionFilter
                Divider()

                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { player in
                            NavigationLink {
                                PlayerDetailView(player: player)
                            } label: {
                                PlayerRowView(player: player)
                            }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { filtered[$0] }
                            toDelete.forEach { playerStore.delete($0) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("選手一覧")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "名前で検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditPlayerView(mode: .add)
            }
        }
    }

    // MARK: - Subviews

    var positionFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "全員", isSelected: selectedPosition == nil, color: .accentColor) {
                    selectedPosition = nil
                }
                ForEach(Position.allCases, id: \.rawValue) { pos in
                    FilterChip(
                        title: "\(pos.shortName) \(pos.displayName)",
                        isSelected: selectedPosition == pos,
                        color: Color.positionColor(for: pos)
                    ) {
                        selectedPosition = selectedPosition == pos ? nil : pos
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3")
                .font(.system(size: 52))
                .foregroundColor(.textTertiary)
            Text(searchText.isEmpty ? "選手がいません" : "「\(searchText)」は見つかりません")
                .font(.headline)
                .foregroundColor(.textSecondary)
            if searchText.isEmpty {
                Text("右上の「+」から選手を追加できます")
                    .font(.subheadline)
                    .foregroundColor(.textTertiary)
            }
            Spacer()
        }
    }
}

// MARK: - Player Row

struct PlayerRowView: View {
    let player: Player

    var body: some View {
        HStack(spacing: 14) {
            numberBadge
            info
            Spacer()
            physicalInfo
        }
        .padding(.vertical, 6)
    }

    var numberBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.positionColor(for: player.position))
                .frame(width: 48, height: 48)
            VStack(spacing: 0) {
                Text("\(player.jerseyNumber)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(player.position.shortName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }

    var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.name)
                .font(.headline)
            Text(player.position.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.positionColor(for: player.position).opacity(0.12))
                .foregroundColor(Color.positionColor(for: player.position))
                .cornerRadius(6)
        }
    }

    var physicalInfo: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("\(Int(player.height)) cm")
                .font(.caption)
                .foregroundColor(.textSecondary)
            Text("\(player.weight, specifier: "%.1f") kg")
                .font(.caption)
                .foregroundColor(.textSecondary)
            Text("\(player.bloodType.displayName)")
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .secondary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color(.separator), lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    PlayersView()
        .environmentObject(PlayerStore())
}
