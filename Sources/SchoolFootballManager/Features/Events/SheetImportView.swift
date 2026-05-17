import SwiftUI

struct SheetImportView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var eventStore: EventStore
    @Environment(\.dismiss) var dismiss

    @StateObject private var sheets = SheetsService()

    // Sheet selection
    @State private var sheetNames: [String] = []
    @State private var showManualInput = false   // fallback when getSheetNames unavailable
    @State private var manualInput = "5月"
    @State private var selectedSheet: String? = nil
    @State private var loadingNames = false
    @State private var namesError: String? = nil

    // Event loading
    @State private var fetchedEvents: [SheetEvent] = []
    @State private var selectedDates: Set<String> = []
    @State private var loadingEvents = false
    @State private var eventsError: String? = nil

    private var activeSheet: String {
        showManualInput
            ? manualInput.trimmingCharacters(in: .whitespaces)
            : (selectedSheet ?? "")
    }

    var body: some View {
        NavigationStack {
            Group {
                if !settings.isSheetsConfigured {
                    notConfiguredView
                } else {
                    mainForm
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

    // MARK: - Main form

    var mainForm: some View {
        Form {
            sheetPickerSection
            if !activeSheet.isEmpty && (selectedSheet != nil || showManualInput) {
                loadEventsButton
            }
            if loadingEvents {
                Section { HStack { ProgressView().scaleEffect(0.8); Text("読み込み中...").foregroundColor(.secondary) } }
            }
            if let err = eventsError {
                errorSection(err, label: "イベントの読み込みに失敗しました")
            }
            if !fetchedEvents.isEmpty {
                eventsSection
            }
            if !selectedDates.isEmpty {
                importButton
            }
        }
    }

    // MARK: - Sheet picker section

    @ViewBuilder
    var sheetPickerSection: some View {
        if loadingNames {
            Section("シートを選択") {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("シート一覧を取得中...").foregroundColor(.secondary)
                }
            }
        } else if showManualInput {
            Section {
                HStack {
                    Text("シート名")
                    Spacer()
                    TextField("例: 5月", text: $manualInput)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .onChange(of: manualInput) { _ in clearEvents() }
                }
                if !sheetNames.isEmpty {
                    Button { showManualInput = false } label: {
                        Label("シート一覧から選ぶ", systemImage: "list.bullet")
                            .font(.subheadline)
                    }
                }
            } header: {
                Text("シートを選択")
            } footer: {
                if let err = namesError {
                    Text("シート一覧取得エラー: \(err)")
                        .foregroundColor(.statusError)
                } else {
                    Text("スプレッドシートのタブ名を正確に入力してください")
                }
            }
        } else {
            Section("シートを選択") {
                ForEach(sheetNames, id: \.self) { name in
                    Button {
                        if selectedSheet != name {
                            selectedSheet = name
                            clearEvents()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tablecells").foregroundColor(.footballGreen).frame(width: 24)
                            Text(name).foregroundColor(.primary)
                            Spacer()
                            if selectedSheet == name {
                                Image(systemName: "checkmark").foregroundColor(.footballGreen).fontWeight(.semibold)
                            }
                        }
                    }
                }
                Button { showManualInput = true } label: {
                    Label("手動で入力する", systemImage: "keyboard")
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Load events button

    var loadEventsButton: some View {
        Section {
            Button { Task { await loadEvents() } } label: {
                Label("\(activeSheet) のイベントを読み込む", systemImage: "arrow.down.doc")
            }
            .disabled(loadingEvents || activeSheet.isEmpty)
        }
    }

    // MARK: - Events section

    var eventsSection: some View {
        Section {
            ForEach(fetchedEvents) { event in
                importRow(for: event)
            }
        } header: {
            HStack {
                Text("\(activeSheet) のイベント")
                Spacer()
                Button(selectedDates.count == availableCount ? "全解除" : "全選択") {
                    toggleSelectAll()
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Import button

    var importButton: some View {
        Section {
            Button { importSelected(); dismiss() } label: {
                Label("\(selectedDates.count)件をインポート", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
            }
            .listRowBackground(Color.footballGreen)
        }
    }

    // MARK: - Error section

    func errorSection(_ message: String, label: String) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label(label, systemImage: "xmark.circle")
                    .font(.subheadline.bold()).foregroundColor(.statusError)
                Text(message)
                    .font(.caption).foregroundColor(.statusError)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Import row

    @ViewBuilder
    private func importRow(for event: SheetEvent) -> some View {
        let imported = alreadyImported(event)
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
            if imported { Text("済み").font(.caption2).foregroundColor(.secondary) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !imported else { return }
            if selectedDates.contains(event.sheetDate) { selectedDates.remove(event.sheetDate) }
            else { selectedDates.insert(event.sheetDate) }
        }
        .opacity(imported ? 0.5 : 1.0)
    }

    // MARK: - Helpers

    private var availableCount: Int {
        fetchedEvents.filter { !alreadyImported($0) }.count
    }

    private func alreadyImported(_ e: SheetEvent) -> Bool {
        eventStore.events.contains { $0.sheetDate == e.sheetDate && $0.sheetMonth == activeSheet }
    }

    private func toggleSelectAll() {
        let available = fetchedEvents.filter { !alreadyImported($0) }.map { $0.sheetDate }
        selectedDates = selectedDates.count == available.count ? [] : Set(available)
    }

    private func clearEvents() {
        fetchedEvents = []
        selectedDates = []
        eventsError = nil
    }

    // MARK: - Async loaders

    private func loadSheetNames() async {
        loadingNames = true
        namesError = nil
        defer { loadingNames = false }
        do {
            sheetNames = try await sheets.fetchSheetNames(scriptURL: settings.sheetsScriptURL)
            showManualInput = sheetNames.isEmpty
        } catch SheetsError.serverError(let msg) where msg.lowercased().contains("unknown action") {
            // Old script without getSheetNames → silently fall back to text input
            showManualInput = true
        } catch {
            namesError = error.localizedDescription
            showManualInput = true
        }
    }

    private func loadEvents() async {
        loadingEvents = true
        eventsError = nil
        defer { loadingEvents = false }
        do {
            fetchedEvents = try await sheets.fetchEvents(month: activeSheet,
                                                         scriptURL: settings.sheetsScriptURL)
            selectedDates = Set(fetchedEvents.filter { !alreadyImported($0) }.map { $0.sheetDate })
        } catch {
            eventsError = error.localizedDescription
        }
    }

    // MARK: - Import

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
            event.sheetMonth = activeSheet
            if !sheetEvent.meetingPlace.isEmpty { event.meetingPoint = sheetEvent.meetingPlace }
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
