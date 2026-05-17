import SwiftUI

struct SheetImportView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var eventStore: EventStore
    @Environment(\.dismiss) var dismiss

    @StateObject private var sheets = SheetsService()

    @State private var sheetNames: [String] = []
    @State private var selectedSheet: String? = nil
    @State private var fetchedEvents: [SheetEvent] = []
    @State private var selectedDates: Set<String> = []
    @State private var loadingNames = false
    @State private var loadingEvents = false
    @State private var namesError: String?
    @State private var eventsError: String?

    var body: some View {
        NavigationStack {
            Group {
                if !settings.isSheetsConfigured {
                    notConfiguredView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Sheetsからインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if loadingNames || loadingEvents {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button { Task { await loadSheetNames() } } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .task {
                if settings.isSheetsConfigured { await loadSheetNames() }
            }
        }
    }

    // MARK: - Not configured

    var notConfiguredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48)).foregroundColor(.statusWarning)
            Text("Sheets連携が未設定です")
                .font(.headline)
            Text("アカウント管理 → Sheets同期の設定 からURLを登録してください")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main content

    var mainContent: some View {
        Form {
            // Sheet list section
            Section {
                if loadingNames {
                    HStack {
                        ProgressView().scaleEffect(0.8)
                        Text("シート一覧を取得中...")
                            .foregroundColor(.secondary)
                    }
                } else if let err = namesError {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("シート一覧の取得に失敗しました", systemImage: "xmark.circle")
                            .font(.subheadline.bold()).foregroundColor(.statusError)
                        Text(err).font(.caption).foregroundColor(.statusError)
                        Button("再試行") { Task { await loadSheetNames() } }
                            .font(.caption)
                    }
                } else {
                    ForEach(sheetNames, id: \.self) { name in
                        Button {
                            if selectedSheet != name {
                                selectedSheet = name
                                fetchedEvents = []
                                selectedDates = []
                                eventsError = nil
                                Task { await loadEvents(for: name) }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "tablecells")
                                    .foregroundColor(.footballGreen)
                                    .frame(width: 24)
                                Text(name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedSheet == name {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.footballGreen)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("シートを選択")
            } footer: {
                if sheetNames.isEmpty && !loadingNames && namesError == nil {
                    Text("シートが見つかりませんでした")
                }
            }

            // Events section (shown after a sheet is selected)
            if let sheet = selectedSheet {
                Section {
                    if loadingEvents {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("イベントを読み込み中...")
                                .foregroundColor(.secondary)
                        }
                    } else if let err = eventsError {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("読み込みに失敗しました", systemImage: "xmark.circle")
                                .font(.subheadline.bold()).foregroundColor(.statusError)
                            Text(err).font(.caption).foregroundColor(.statusError)
                        }
                    } else if fetchedEvents.isEmpty {
                        Text("イベントが見つかりませんでした")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(fetchedEvents) { event in
                            importRow(for: event, sheet: sheet)
                        }
                    }
                } header: {
                    HStack {
                        Text("\(sheet) のイベント")
                        Spacer()
                        if !fetchedEvents.isEmpty {
                            Button(selectedDates.count == availableCount ? "全解除" : "全選択") {
                                toggleSelectAll(sheet: sheet)
                            }
                            .font(.caption)
                        }
                    }
                }

                if !selectedDates.isEmpty {
                    Section {
                        Button {
                            importSelected(sheet: sheet)
                            dismiss()
                        } label: {
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

    // MARK: - Import row

    @ViewBuilder
    private func importRow(for event: SheetEvent, sheet: String) -> some View {
        let imported = alreadyImported(event, sheet: sheet)
        HStack(spacing: 12) {
            Image(systemName: imported || selectedDates.contains(event.sheetDate)
                  ? "checkmark.circle.fill" : "circle")
                .foregroundColor(
                    imported ? .secondary
                    : selectedDates.contains(event.sheetDate) ? .footballGreen : .secondary
                )
                .font(.system(size: 20))

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

    // MARK: - Helpers

    private var availableCount: Int {
        guard let sheet = selectedSheet else { return 0 }
        return fetchedEvents.filter { !alreadyImported($0, sheet: sheet) }.count
    }

    private func alreadyImported(_ e: SheetEvent, sheet: String) -> Bool {
        eventStore.events.contains { $0.sheetDate == e.sheetDate && $0.sheetMonth == sheet }
    }

    private func toggleSelectAll(sheet: String) {
        let available = fetchedEvents.filter { !alreadyImported($0, sheet: sheet) }.map { $0.sheetDate }
        if selectedDates.count == available.count {
            selectedDates = []
        } else {
            selectedDates = Set(available)
        }
    }

    // MARK: - Async loaders

    private func loadSheetNames() async {
        loadingNames = true
        namesError = nil
        defer { loadingNames = false }
        do {
            sheetNames = try await sheets.fetchSheetNames(scriptURL: settings.sheetsScriptURL)
        } catch {
            namesError = error.localizedDescription
        }
    }

    private func loadEvents(for sheet: String) async {
        loadingEvents = true
        eventsError = nil
        defer { loadingEvents = false }
        do {
            fetchedEvents = try await sheets.fetchEvents(month: sheet,
                                                         scriptURL: settings.sheetsScriptURL)
            selectedDates = Set(fetchedEvents.filter { !alreadyImported($0, sheet: sheet) }.map { $0.sheetDate })
        } catch {
            eventsError = error.localizedDescription
        }
    }

    // MARK: - Import

    private func importSelected(sheet: String) {
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
            event.sheetMonth = sheet
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
