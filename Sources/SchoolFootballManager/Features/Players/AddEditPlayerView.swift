import SwiftUI

enum PlayerFormMode {
    case add
    case edit(Player)
}

struct AddEditPlayerView: View {
    @EnvironmentObject var playerStore: PlayerStore
    @Environment(\.dismiss) var dismiss

    let mode: PlayerFormMode

    // Fields
    @State private var name = ""
    @State private var jerseyNumber = 1
    @State private var position: Position = .forward
    @State private var birthday = Calendar.current.date(from: DateComponents(year: 2017, month: 4, day: 1)) ?? Date()
    @State private var weight: Double = 30.0
    @State private var height: Double = 130.0
    @State private var bloodType: BloodType = .a

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String { isEditing ? "選手を編集" : "選手を追加" }

    init(mode: PlayerFormMode) {
        self.mode = mode

        if case .edit(let player) = mode {
            _name          = State(initialValue: player.name)
            _jerseyNumber  = State(initialValue: player.jerseyNumber)
            _position      = State(initialValue: player.position)
            _birthday      = State(initialValue: player.birthday)
            _weight        = State(initialValue: player.weight)
            _height        = State(initialValue: player.height)
            _bloodType     = State(initialValue: player.bloodType)
        }
    }

    var isFormValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                physicalSection
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Form Sections

    var basicSection: some View {
        Section("基本情報") {
            HStack {
                Text("氏名")
                    .foregroundColor(.textSecondary)
                Spacer()
                TextField("山田 太郎", text: $name)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("背番号")
                    .foregroundColor(.textSecondary)
                Spacer()
                Stepper("\(jerseyNumber)", value: $jerseyNumber, in: 1...99)
                    .labelsHidden()
                Text("\(jerseyNumber)")
                    .frame(width: 32, alignment: .center)
                    .font(.headline)
            }

            Picker("ポジション", selection: $position) {
                ForEach(Position.allCases, id: \.rawValue) { pos in
                    HStack {
                        Circle()
                            .fill(Color.positionColor(for: pos))
                            .frame(width: 10, height: 10)
                        Text(pos.displayName)
                    }
                    .tag(pos)
                }
            }

            HStack {
                Text("血液型")
                    .foregroundColor(.textSecondary)
                Spacer()
                Picker("", selection: $bloodType) {
                    ForEach(BloodType.allCases, id: \.rawValue) { bt in
                        Text(bt.displayName).tag(bt)
                    }
                }
                .pickerStyle(.menu)
            }

            DatePicker("生年月日", selection: $birthday, in: ...Date(), displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }

    var physicalSection: some View {
        Section("身体情報") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("身長")
                    Spacer()
                    Text("\(Int(height)) cm")
                        .foregroundColor(.accentColor)
                        .fontWeight(.medium)
                }
                Slider(value: $height, in: 100...180, step: 0.5)
                    .tint(.footballBlue)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("体重")
                    Spacer()
                    Text(String(format: "%.1f kg", weight))
                        .foregroundColor(.accentColor)
                        .fontWeight(.medium)
                }
                Slider(value: $weight, in: 15...80, step: 0.5)
                    .tint(.footballGreen)
            }
        }
    }

    // MARK: - Save

    private func save() {
        let teamId = PlayerStore.defaultTeamId

        switch mode {
        case .add:
            var player = Player(
                teamId: teamId,
                name: name.trimmingCharacters(in: .whitespaces),
                jerseyNumber: jerseyNumber,
                position: position,
                birthday: birthday,
                weight: weight,
                height: height,
                bloodType: bloodType
            )
            player.id = UUID().uuidString
            playerStore.add(player)

        case .edit(var player):
            player.name          = name.trimmingCharacters(in: .whitespaces)
            player.jerseyNumber  = jerseyNumber
            player.position      = position
            player.birthday      = birthday
            player.weight        = weight
            player.height        = height
            player.bloodType     = bloodType
            player.updatedAt     = Date()
            playerStore.update(player)
        }

        dismiss()
    }
}

#Preview {
    AddEditPlayerView(mode: .add)
        .environmentObject(PlayerStore())
}
