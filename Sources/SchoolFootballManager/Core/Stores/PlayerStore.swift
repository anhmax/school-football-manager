import Foundation

@MainActor
class PlayerStore: ObservableObject {
    @Published var players: [Player] = []

    static let defaultTeamId = "3nensei"

    init() {
        setupMockData()
    }

    // MARK: - Mock Data

    private func setupMockData() {
        players = []
    }

    private func make(name: String, number: Int, pos: Position, bday: Date,
                      weight: Double, height: Double, blood: BloodType) -> Player {
        var p = Player(teamId: Self.defaultTeamId, name: name, jerseyNumber: number,
                       position: pos, birthday: bday, weight: weight, height: height, bloodType: blood)
        p.id = UUID().uuidString
        return p
    }

    private func ymd(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
    }

    // MARK: - CRUD

    func add(_ player: Player) {
        var p = player
        if p.id == nil { p.id = UUID().uuidString }
        players.append(p)
        players.sort { $0.jerseyNumber < $1.jerseyNumber }
    }

    func update(_ player: Player) {
        guard let idx = players.firstIndex(where: { $0.id == player.id }) else { return }
        players[idx] = player
        players.sort { $0.jerseyNumber < $1.jerseyNumber }
    }

    func delete(_ player: Player) {
        players.removeAll { $0.id == player.id }
    }
}
