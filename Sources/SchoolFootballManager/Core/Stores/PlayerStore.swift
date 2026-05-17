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
        players = [
            make(name: "山田 太郎",  number: 10, pos: .forward,    bday: ymd(2017, 4, 12),  weight: 32.5, height: 138, blood: .a),
            make(name: "鈴木 健太",  number:  7, pos: .midfielder,  bday: ymd(2017, 6, 3),   weight: 30.0, height: 135, blood: .b),
            make(name: "田中 拓也",  number:  5, pos: .defender,    bday: ymd(2017, 2, 18),  weight: 33.0, height: 140, blood: .o),
            make(name: "佐藤 大樹",  number:  1, pos: .goalkeeper,  bday: ymd(2017, 9, 25),  weight: 34.5, height: 142, blood: .ab),
            make(name: "渡辺 勇気",  number: 11, pos: .forward,    bday: ymd(2017, 11, 7),  weight: 28.5, height: 132, blood: .a),
            make(name: "伊藤 翔",    number:  4, pos: .defender,    bday: ymd(2017, 3, 14),  weight: 31.0, height: 137, blood: .b),
        ]
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
