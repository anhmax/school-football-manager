import SwiftUI

struct SheetImportView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var eventStore: EventStore
    @Environment(\.dismiss) var dismiss

    @StateObject private var sheets = SheetsService()

    private let months = ["4月","5月","6月","7月","8月","9月","10月","11月","12月","1月","2月","3月"]
    @State private var selectedMonth = "5月"
    @State private var fetchedEvents: [SheetEvent] = []
    @State private var selectedDates: Set<String> = []
    @State private var errorMessage: String?
    @State private var hasFetched = false

    private func alreadyImported(_ e: SheetEvent) -> Bool {
        eventStore.events.contains { $0.sheetDate == e.sheetDate && $0.sheetMonth == selectedMonth }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("シートの月を選択") {
                    Picker("月", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)

                    Button {
                        Task { await fetchEvents() }
                    } label: {
                        if sheets.isSyncing {
                            HStack {
                                ProgressView().scaleEffect(0.8)
                                Text("読み込み中...")
                            }
                        } else {
                            Label("スケジュールを読み込む", systemImage: "arrow.down.doc")
                        }
                    }
                    .disabled(sheets.isSyncing || !settings.isSheetsConfigured)
                }

                if !settings.isSheetsConfigured {
                    Section {
                        Label("Sheets連携が未設定です。アカウント管理から設定してください。",
                              systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundColor(.statusWarning)
                    }
                }

                if let err = errorMessage {
                    Section {
                        Label(err, systemImage: "xmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.statusError)
                    }
                }

                if hasFetched {
                    if fetchedEvents.isEmpty {
                        Section {
                            Text("イベントが見つかりませんでした")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Section("インポートするイベント（\(selectedDates.count)件選択中）") {
                            ForEach(fetchedEvents) { event in
                                importRow(for: event)
                            }
                        }

                        if !selectedDates.isEmpty {
                            Section {
                                Button { importSelected(); dismiss() } label: {
                                    Label("\(selectedDates.count)件をインポート",
                                          systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(.white)
                                }
                                .listRowBackground(Color.footballGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sheetsからインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onChange(of: selectedMonth) { _ in
                fetchedEvents = []
                selectedDates = []
                hasFetched = false
                errorMessage = nil
            }
        }
    }

    @ViewBuilder
    private func importRow(for event: SheetEvent) -> some View {
        let imported = alreadyImported(event)
        HStack(spacing: 12) {
            Image(systemName: imported || selectedDates.contains(event.sheetDate)
                  ? "checkmark.circle.fill" : "circle")
                .foregroundColor(imported ? .secondary
                    : selectedDates.contains(event.sheetDate) ? .footballGreen : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(event.sheetDate)(\(event.dayOfWeek))")
                        .font(.caption).foregroundColor(.secondary)
                    EventTypeBadge(type: event.eventType)
                }
                Text(event.schedule)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(imported ? .secondary : .primary)
                if !event.venue.isEmpty {
                    Label(event.venue, systemImage: "mappin")
                        .font(.caption).foregroundColor(.secondary)
                }
                if !event.meetingTime.isEmpty {
                    Label("集合 \(event.meetingTime)", systemImage: "clock")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            if imported {
                Text("済み").font(.caption2).foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !imported else { return }
            if selectedDates.contains(event.sheetDate) {
                selectedDates.remove(event.sheetDate)
            } else {
                selectedDates.insert(event.sheetDate)
            }
        }
        .opacity(imported ? 0.5 : 1.0)
    }

    private func fetchEvents() async {
        errorMessage = nil
        do {
            fetchedEvents = try await sheets.fetchEvents(month: selectedMonth,
                                                         scriptURL: settings.sheetsScriptURL)
            hasFetched = true
            selectedDates = Set(fetchedEvents.filter { !alreadyImported($0) }.map { $0.sheetDate })
        } catch {
            errorMessage = error.localizedDescription
            hasFetched = true
        }
    }

    private func importSelected() {
        for sheetEvent in fetchedEvents where selectedDates.contains(sheetEvent.sheetDate) {
            guard let date = sheetEvent.date(year: 2026) else { continue }
            var event = Event(
                teamId: EventStore.teamId,
                type: sheetEvent.eventType,
                title: sheetEvent.schedule,
                eventDate: date,
                venue: sheetEvent.venue,
                checklist: [],
                createdBy: EventStore.managerId
            )
            event.sheetDate = sheetEvent.sheetDate
            event.sheetMonth = selectedMonth
            if !sheetEvent.meetingPlace.isEmpty {
                event.meetingPoint = sheetEvent.meetingPlace
            }
            event.departureTime = parseTime(sheetEvent.meetingTime, on: date)
                ?? parseTime(sheetEvent.localMeetingTime, on: date)
            eventStore.add(event)
        }
    }

    private func parseTime(_ timeStr: String, on date: Date) -> Date? {
        let clean = timeStr.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        for fmt in ["H:mm", "HH:mm", "H時mm分", "HH時mm分"] {
            formatter.dateFormat = fmt
            if let parsed = formatter.date(from: clean) {
                let timeParts = Calendar.current.dateComponents([.hour, .minute], from: parsed)
                var combined = comps
                combined.hour = timeParts.hour
                combined.minute = timeParts.minute
                return Calendar.current.date(from: combined)
            }
        }
        return nil
    }
}
