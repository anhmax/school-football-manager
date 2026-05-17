import SwiftUI

// MARK: - Main View

struct SheetImportView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var eventStore: EventStore
    @Environment(\.dismiss) var dismiss

    @StateObject private var sheets = SheetsService()

    // Input
    @State private var monthName  = "5月"
    @State private var rawRows:   [[String]] = []
    @State private var inputError: String?

    // Mapping
    @State private var mapping = ColumnMapping()

    // Results
    @State private var events:        [SheetEvent] = []
    @State private var selectedDates: Set<String>  = []

    // Computed
    private var colCount: Int { max((rawRows.max { $0.count < $1.count }?.count ?? 0), 14) }

    private func colLabel(_ i: Int) -> String {
        String(UnicodeScalar(65 + (i % 26))!)  // A, B, C …
    }

    private func colPreview(_ i: Int) -> String {
        // first non-empty value in that column (skip header row)
        let val = rawRows.dropFirst().first { i < $0.count && !$0[i].trimmingCharacters(in: .whitespaces).isEmpty }?[i] ?? ""
        return String(val.prefix(10))
    }

    var body: some View {
        NavigationStack {
            Form {
                pasteSection
                if !rawRows.isEmpty { mappingSection }
                if !events.isEmpty  { eventsSection   }
                if !selectedDates.isEmpty { importSection }
            }
            .navigationTitle("データをインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("閉じる") { dismiss() } }
            }
        }
    }

    // MARK: - ① Paste section

    var pasteSection: some View {
        Section {
            HStack {
                Text("月名（シート名）")
                Spacer()
                TextField("5月", text: $monthName)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
            }

            Button {
                loadFromClipboard()
            } label: {
                Label("クリップボードから読み込む", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.footballGreen)

            if let err = inputError {
                Label(err, systemImage: "xmark.circle")
                    .font(.caption).foregroundColor(.statusError)
                    .textSelection(.enabled)
            }

            if !rawRows.isEmpty {
                Label("\(max(rawRows.count - 1, 0))行を読み込みました", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundColor(.statusSuccess)

                // Preview first 2 data rows
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(rawRows.prefix(3).enumerated()), id: \.offset) { idx, row in
                        Text(row.prefix(5).joined(separator: " | "))
                            .font(.system(.caption2, design: .monospaced))
                            .lineLimit(1)
                            .foregroundColor(idx == 0 ? .secondary : .primary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("データを貼り付け")
        } footer: {
            Text("Excelまたはスプレッドシートで対象シートを開き、全セル選択（Ctrl+A）→ コピー（Ctrl+C）してからボタンを押してください。")
                .font(.caption)
        }
    }

    // MARK: - ② Column mapping section

    var mappingSection: some View {
        Section {
            colPicker("日付",    idx: $mapping.date)
            colPicker("予定名",  idx: $mapping.schedule)
            colPicker("会場",    idx: $mapping.venue)
            colPicker("集合時間", idx: $mapping.meetingTime)
            colPicker("集合場所", idx: $mapping.meetingPlace)

            Button {
                applyMapping()
            } label: {
                Label("この設定でプレビュー", systemImage: "eye")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        } header: {
            Text("列のマッピング")
        } footer: {
            if let header = rawRows.first {
                Text("1行目: " + header.prefix(8).enumerated().map { "\(colLabel($0)):\($1.prefix(5))" }.joined(separator: "  "))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func colPicker(_ label: String, idx: Binding<Int>) -> some View {
        HStack {
            Text(label).frame(width: 72, alignment: .leading)
            Spacer()
            Picker("", selection: idx) {
                ForEach(0..<colCount, id: \.self) { i in
                    let preview = colPreview(i)
                    Text(preview.isEmpty ? colLabel(i) : "\(colLabel(i)): \(preview)").tag(i)
                }
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - ③ Events section

    var eventsSection: some View {
        Section {
            ForEach(events) { ev in
                let imported = alreadyImported(ev)
                HStack(spacing: 12) {
                    Image(systemName: imported || selectedDates.contains(ev.sheetDate)
                          ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(
                            imported ? .secondary
                            : selectedDates.contains(ev.sheetDate) ? .footballGreen : .secondary)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\(ev.sheetDate)(\(ev.dayOfWeek))")
                                .font(.caption).foregroundColor(.secondary)
                            EventTypeBadge(type: ev.eventType)
                        }
                        Text(ev.schedule)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(imported ? .secondary : .primary)
                        if !ev.venue.isEmpty {
                            Label(ev.venue, systemImage: "mappin")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if imported { Text("済み").font(.caption2).foregroundColor(.secondary) }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !imported else { return }
                    if selectedDates.contains(ev.sheetDate) { selectedDates.remove(ev.sheetDate) }
                    else { selectedDates.insert(ev.sheetDate) }
                }
                .opacity(imported ? 0.5 : 1)
            }
        } header: {
            HStack {
                Text("イベント一覧（\(events.count)件）")
                Spacer()
                let available = events.filter { !alreadyImported($0) }
                Button(selectedDates.count == available.count ? "全解除" : "全選択") {
                    let ids = available.map { $0.sheetDate }
                    selectedDates = selectedDates.count == ids.count ? [] : Set(ids)
                }
                .font(.caption)
            }
        }
    }

    // MARK: - ④ Import button

    var importSection: some View {
        Section {
            Button {
                doImport()
                dismiss()
            } label: {
                Label("\(selectedDates.count)件をインポート",
                      systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity).foregroundColor(.white)
            }
            .listRowBackground(Color.footballGreen)
        }
    }

    // MARK: - Logic

    private func loadFromClipboard() {
        inputError = nil
        let text = UIPasteboard.general.string ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            inputError = "クリップボードにデータがありません。ExcelでCtrl+Cしてからもう一度試してください"
            return
        }
        rawRows = sheets.parseDelimitedText(text)
        if rawRows.isEmpty {
            inputError = "データを解析できませんでした"
        } else {
            events = []
            selectedDates = []
            applyMapping()
        }
    }

    private func applyMapping() {
        events = sheets.rowsToSheetEvents(rawRows, mapping: mapping)
        selectedDates = Set(events.filter { !alreadyImported($0) }.map { $0.sheetDate })
    }

    private func alreadyImported(_ e: SheetEvent) -> Bool {
        eventStore.events.contains { $0.sheetDate == e.sheetDate && $0.sheetMonth == monthName.trimmingCharacters(in: .whitespaces) }
    }

    private func doImport() {
        let month = monthName.trimmingCharacters(in: .whitespaces)
        for ev in events where selectedDates.contains(ev.sheetDate) {
            guard let date = ev.date(year: 2026) else { continue }
            var event = Event(
                teamId: EventStore.teamId, type: ev.eventType,
                title: ev.schedule, eventDate: date,
                venue: ev.venue, checklist: [], createdBy: EventStore.managerId
            )
            event.sheetDate  = ev.sheetDate
            event.sheetMonth = month
            if !ev.meetingPlace.isEmpty { event.meetingPoint = ev.meetingPlace }
            event.departureTime = parseTime(ev.meetingTime, on: date)
                ?? parseTime(ev.localMeetingTime, on: date)
            eventStore.add(event)
        }
    }

    private func parseTime(_ str: String, on date: Date) -> Date? {
        let clean = str.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return nil }
        let fmt = DateFormatter(); fmt.locale = Locale(identifier: "ja_JP")
        let base = Calendar.current.dateComponents([.year, .month, .day], from: date)
        for f in ["H:mm", "HH:mm", "H時mm分"] {
            fmt.dateFormat = f
            if let t = fmt.date(from: clean) {
                let tp = Calendar.current.dateComponents([.hour, .minute], from: t)
                var c = base; c.hour = tp.hour; c.minute = tp.minute
                return Calendar.current.date(from: c)
            }
        }
        return nil
    }
}
