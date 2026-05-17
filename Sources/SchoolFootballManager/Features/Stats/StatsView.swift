import SwiftUI

struct StatsView: View {
    @EnvironmentObject var playerStore: PlayerStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(playerStore.players) { player in
                    NavigationLink {
                        PlayerDetailView(player: player)
                    } label: {
                        PlayerStatsRow(player: player)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PlayerStatsRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.positionColor(for: player.position))
                    .frame(width: 40, height: 40)
                Text("\(player.jerseyNumber)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(player.name).font(.subheadline).fontWeight(.semibold)
                Text(player.position.displayName).font(.caption).foregroundColor(.textSecondary)
            }

            Spacer()

            HStack(spacing: 16) {
                StatPill(value: "0", label: "得点")
                StatPill(value: "0", label: "アシスト")
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).fontWeight(.bold)
            Text(label).font(.system(size: 9)).foregroundColor(.textSecondary)
        }
        .frame(width: 44)
    }
}

#Preview {
    StatsView()
        .environmentObject(PlayerStore())
}
