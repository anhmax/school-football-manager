import SwiftUI

enum EventFormMode {
    case add
    case edit(Event)
}

struct AddEditEventView: View {
    @EnvironmentObject var eventStore: EventStore
    @Environment(\.dismiss) var dismiss

    let mode: EventFormMode

    // Fields
    @State private var title        = ""
    @State private var type: EventType = .match
    @State private var eventDate    = nextSaturday()
    @State private var venue        = ""
    @State private var hasDepartureTime = false
    @State private var departureTime = nextSaturday()
    @State private var hasArrivalTime   = false
    @State private var arrivalTime   = nextSaturday()
    @State private var hasMeetingPoint  = false
    @State private var meetingPoint  = ""
    @State private var checklistItems: [String] = []
    @State private var newChecklistItem = ""
    @State private var notes         = ""
    @State private var hasDeadline   = false
    @State private var deadline      = Date()

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !venue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(mode: EventFormMode) {
        self.mode = mode

        if case .edit(let event) = mode {
            _title        = State(initialValue: event.title)
            _type         = State(initialValue: event.type)
            _eventDate    = State(initialValue: event.eventDate)
            _venue        = State(initialValue: event.venue)
            _checklistItems = State(initialValue: event.checklist)
            _notes        = State(initialValue: event.notes ?? "")

            if let dep = event.departureTime {
                _hasDepartureTime = State(initialValue: true)
                _departureTime    = State(initialValue: dep)
            }
            if let arr = event.estimatedArrivalTime {
                _hasArrivalTime  = State(initialValue: true)
                _arrivalTime     = State(initialValue: arr)
            }
            if let mp = event.meetingPoint, !mp.isEmpty {
                _hasMeetingPoint = State(initialValue: true)
                _meetingPoint    = State(initialValue: mp)
            }
            if let dl = event.registrationDeadline {
                _hasDeadline = State(initialValue: true)
                _deadline    = State(initialValue: dl)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                scheduleSection
                checklistSection
                notesSection
            }
            .navigationTitle(isEditing ? "イベントを編集" : "イベントを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Sections

    var basicSection: some View {
        Section("基本情報") {
            Picker("種類", selection: $type) {
                ForEach(EventType.allCases, id: \.rawValue) { t in
                    Label(t.displayName, systemImage: t.icon).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            HStack {
                Text("タイトル")
                    .foregroundColor(.textSecondary)
                Spacer()
                TextField("春季大会 第1試合", text: $title)
                    .multilineTextAlignment(.trailing)
            }

            DatePicker("日時", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                .environment(\.locale, Locale(identifier: "ja_JP"))

            HStack {
                Text("会場")
                    .foregroundColor(.textSecondary)
                Spacer()
                TextField("緑ヶ丘グラウンド", text: $venue)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    var scheduleSection: some View {
        Section("スケジュール（任意）") {
            Toggle("出発時間", isOn: $hasDepartureTime)
            if hasDepartureTime {
                DatePicker("", selection: $departureTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }

            Toggle("到着予定時間", isOn: $hasArrivalTime)
            if hasArrivalTime {
                DatePicker("", selection: $arrivalTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }

            Toggle("集合場所", isOn: $hasMeetingPoint)
            if hasMeetingPoint {
                TextField("学校正門前", text: $meetingPoint)
            }

            Toggle("参加登録締め切り", isOn: $hasDeadline)
            if hasDeadline {
                DatePicker("締め切り", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
        }
    }

    var checklistSection: some View {
        Section("持ち物チェックリスト") {
            ForEach(Array(checklistItems.enumerated()), id: \.offset) { idx, item in
                HStack {
                    Image(systemName: "checkmark.square")
                        .foregroundColor(.footballGreen)
                    Text(item)
                    Spacer()
                    Button { checklistItems.remove(at: idx) } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.statusError)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
                TextField("アイテムを追加", text: $newChecklistItem)
                    .onSubmit { addChecklistItem() }
                if !newChecklistItem.isEmpty {
                    Button { addChecklistItem() } label: {
                        Text("追加")
                            .font(.caption).fontWeight(.semibold)
                    }
                }
            }
        }
    }

    var notesSection: some View {
        Section("メモ（任意）") {
            TextField("連絡事項など", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Helpers

    private func addChecklistItem() {
        let item = newChecklistItem.trimmingCharacters(in: .whitespaces)
        guard !item.isEmpty else { return }
        checklistItems.append(item)
        newChecklistItem = ""
    }

    private func save() {
        switch mode {
        case .add:
            var event = Event(
                teamId: EventStore.teamId,
                type: type,
                title: title.trimmingCharacters(in: .whitespaces),
                eventDate: eventDate,
                venue: venue.trimmingCharacters(in: .whitespaces),
                checklist: checklistItems,
                createdBy: EventStore.managerId
            )
            event.departureTime         = hasDepartureTime ? departureTime : nil
            event.estimatedArrivalTime  = hasArrivalTime   ? arrivalTime   : nil
            event.meetingPoint          = hasMeetingPoint && !meetingPoint.isEmpty ? meetingPoint : nil
            event.notes                 = notes.isEmpty    ? nil            : notes
            event.registrationDeadline  = hasDeadline      ? deadline       : nil
            eventStore.add(event)

        case .edit(var event):
            event.type                  = type
            event.title                 = title.trimmingCharacters(in: .whitespaces)
            event.eventDate             = eventDate
            event.venue                 = venue.trimmingCharacters(in: .whitespaces)
            event.checklist             = checklistItems
            event.notes                 = notes.isEmpty    ? nil            : notes
            event.departureTime         = hasDepartureTime ? departureTime  : nil
            event.estimatedArrivalTime  = hasArrivalTime   ? arrivalTime    : nil
            event.meetingPoint          = hasMeetingPoint && !meetingPoint.isEmpty ? meetingPoint : nil
            event.registrationDeadline  = hasDeadline      ? deadline       : nil
            event.updatedAt             = Date()
            eventStore.update(event)
        }

        dismiss()
    }

    private static func nextSaturday() -> Date {
        var date = Date()
        let weekday = Calendar.current.component(.weekday, from: date)
        let daysToSaturday = (7 - weekday + 7) % 7 == 0 ? 7 : (7 - weekday + 7) % 7
        date = Calendar.current.date(byAdding: .day, value: daysToSaturday, to: date) ?? date
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }
}

#Preview {
    AddEditEventView(mode: .add)
        .environmentObject(EventStore())
}
