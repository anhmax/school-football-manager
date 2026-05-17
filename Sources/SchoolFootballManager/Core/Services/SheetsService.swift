import Foundation

// MARK: - Sheet Event (read from Google Sheet)

struct SheetEvent: Identifiable {
    var id: String { "\(sheetDate)-\(schedule)" }
    var sheetDate: String       // "5/2"
    var dayOfWeek: String       // "土"
    var schedule: String        // "TRM 9-13 vs綾瀬JETS"
    var venue: String
    var localMeetingTime: String   // 現地集合時間
    var meetingTime: String        // 集合時間
    var meetingPlace: String       // 集合場所
    var attendingPlayers: [String] // column M — attending
    var absentPlayers: [String]    // column N — absent

    var isOff: Bool {
        schedule.uppercased().hasPrefix("OFF") || schedule.isEmpty
    }

    var eventType: EventType {
        let upper = schedule.uppercased()
        if upper.contains("TRM") || upper.contains("リーグ") ||
           upper.contains("カップ") || upper.contains("大会") || upper.contains("VS") {
            return .match
        }
        return .practice
    }

    /// Parse "5/2" into Date for given year
    func date(year: Int = 2026) -> Date? {
        let parts = sheetDate.split(separator: "/")
        guard parts.count == 2,
              let month = Int(parts[0]),
              let day   = Int(parts[1]) else { return nil }
        return Calendar.current.date(
            from: DateComponents(year: year, month: month, day: day, hour: 9)
        )
    }

    func myStatus(playerName: String) -> AttendanceStatus {
        if attendingPlayers.contains(playerName) { return .attending }
        if absentPlayers.contains(playerName)    { return .absent }
        return .notConfirmed
    }
}

// MARK: - Service

@MainActor
class SheetsService: ObservableObject {
    @Published var isSyncing    = false
    @Published var lastSyncTime: Date?
    @Published var syncError:   String?

    // MARK: - Fetch events from a month sheet

    func fetchEvents(month: String, scriptURL: String) async throws -> [SheetEvent] {
        let url = try buildURL(scriptURL, params: [
            "action": "fetchEvents",
            "month": month
        ])
        isSyncing = true; syncError = nil
        defer { isSyncing = false }

        let data = try await get(url)
        try throwIfServerError(data)
        let raw = try JSONDecoder().decode([RawSheetRow].self, from: data)
        lastSyncTime = Date()
        return raw.compactMap { SheetEvent(raw: $0) }
    }

    // MARK: - Update attendance (writes player name to col M or N)

    func updateAttendance(month: String, sheetDate: String,
                          playerName: String, status: AttendanceStatus,
                          scriptURL: String) async throws {
        let url = try buildURL(scriptURL, params: [
            "action":     "updateAttendance",
            "month":      month,
            "date":       sheetDate,
            "playerName": playerName,
            "status":     status.sheetLabel
        ])
        let data = try await get(url)
        try throwIfServerError(data)
        struct Res: Codable { var success: Bool?; var error: String? }
        let res = try JSONDecoder().decode(Res.self, from: data)
        if res.success != true {
            throw SheetsError.serverError(res.error ?? "不明なエラー")
        }
        lastSyncTime = Date()
    }

    // MARK: - Fetch events from CSV (works with Excel files on Google Drive)

    func fetchEventsFromCSV(sheetName: String, spreadsheetURL: String) async throws -> [SheetEvent] {
        let fileId = try extractSpreadsheetId(from: spreadsheetURL)
        let encoded = sheetName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sheetName
        let urlString = "https://docs.google.com/spreadsheets/d/\(fileId)/export?format=csv&sheet=\(encoded)"
        guard let url = URL(string: urlString) else { throw SheetsError.invalidURL }

        isSyncing = true; syncError = nil
        defer { isSyncing = false }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw SheetsError.httpError(0) }
        guard (200...299).contains(http.statusCode) else {
            throw SheetsError.serverError("アクセスエラー (HTTP \(http.statusCode))。ファイルを「リンクを知っている全員が閲覧可能」に設定してください")
        }

        guard let csv = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .shiftJIS) else {
            throw SheetsError.serverError("データの読み込みに失敗しました")
        }
        if csv.trimmingCharacters(in: .whitespaces).hasPrefix("<") {
            throw SheetsError.serverError("Googleのログインページにリダイレクトされました。ファイルの共有設定を確認してください")
        }

        lastSyncTime = Date()
        return parseCSVToEvents(csv)
    }

    private func extractSpreadsheetId(from urlString: String) throws -> String {
        for pattern in [#"/spreadsheets/d/([a-zA-Z0-9_-]+)"#, #"/file/d/([a-zA-Z0-9_-]+)"#] {
            if let range = urlString.range(of: pattern, options: .regularExpression) {
                let parts = String(urlString[range]).components(separatedBy: "/")
                if let id = parts.last(where: { !$0.isEmpty && $0 != "d" }), !id.isEmpty {
                    return id
                }
            }
        }
        throw SheetsError.serverError("URLからファイルIDを取得できませんでした。共有リンクを貼り付けてください")
    }

    private func parseCSVToEvents(_ csv: String) -> [SheetEvent] {
        let rows = parseCSVRows(csv)
        return rows.dropFirst().compactMap { row -> SheetEvent? in
            let get: (Int) -> String = { i in i < row.count ? row[i].trimmingCharacters(in: .whitespaces) : "" }
            let date = get(0); let schedule = get(2)
            guard !date.isEmpty, !schedule.isEmpty else { return nil }
            guard !schedule.uppercased().hasPrefix("OFF") else { return nil }
            let raw = RawSheetRow(
                date: date, dayOfWeek: get(1), schedule: schedule, venue: get(3),
                localMeetingTime: get(4), meetingTime: get(5), meetingPlace: get(6),
                attendingPlayers: splitCellNames(get(12)),
                absentPlayers: splitCellNames(get(13))
            )
            return SheetEvent(raw: raw)
        }
    }

    private func splitCellNames(_ str: String) -> [String] {
        str.components(separatedBy: CharacterSet(charactersIn: "\n,、"))
           .map { $0.trimmingCharacters(in: .whitespaces) }
           .filter { !$0.isEmpty }
    }

    private func parseCSVRows(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        var idx = csv.startIndex

        while idx < csv.endIndex {
            let ch = csv[idx]
            let nxt = csv.index(after: idx)
            if inQuotes {
                if ch == "\"" {
                    if nxt < csv.endIndex && csv[nxt] == "\"" { field.append("\""); idx = csv.index(after: nxt); continue }
                    else { inQuotes = false }
                } else { field.append(ch) }
            } else {
                switch ch {
                case "\"": inQuotes = true
                case ",": fields.append(field); field = ""
                case "\r":
                    fields.append(field); field = ""; rows.append(fields); fields = []
                    if nxt < csv.endIndex && csv[nxt] == "\n" { idx = csv.index(after: nxt); continue }
                case "\n":
                    fields.append(field); field = ""; rows.append(fields); fields = []
                default: field.append(ch)
                }
            }
            idx = csv.index(after: idx)
        }
        if !field.isEmpty || !fields.isEmpty { fields.append(field); rows.append(fields) }
        return rows.filter { $0.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }
    }

    // MARK: - Fetch sheet tab names

    func fetchSheetNames(scriptURL: String) async throws -> [String] {
        let url = try buildURL(scriptURL, params: ["action": "getSheetNames"])
        isSyncing = true; syncError = nil
        defer { isSyncing = false }
        let data = try await get(url)
        try throwIfServerError(data)
        return try JSONDecoder().decode([String].self, from: data)
    }

    // MARK: - Test connection

    func testConnection(scriptURL: String) async throws {
        let url = try buildURL(scriptURL, params: ["action": "ping"])
        _ = try await get(url)
    }

    // MARK: - Helpers

    /// If the JSON is {"error":"..."}, throw serverError so callers get a clear message
    /// instead of a confusing DecodingError.
    private func throwIfServerError(_ data: Data) throws {
        struct ErrPayload: Codable { var error: String? }
        if let payload = try? JSONDecoder().decode(ErrPayload.self, from: data),
           let msg = payload.error {
            throw SheetsError.serverError(msg)
        }
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw SheetsError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    private func buildURL(_ base: String, params: [String: String]) throws -> URL {
        var comps = URLComponents(string: base)
        comps?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = comps?.url else { throw SheetsError.invalidURL }
        return url
    }
}

// MARK: - Errors & extensions

enum SheetsError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case serverError(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "URLが正しくありません"
        case .httpError(let c):   return "HTTPエラー: \(c)"
        case .serverError(let m): return "サーバーエラー: \(m)"
        }
    }
}

extension AttendanceStatus {
    var sheetLabel: String {
        switch self {
        case .attending:    return "参加"
        case .absent:       return "欠席"
        case .notConfirmed: return "未確認"
        }
    }
}

// MARK: - Column mapping + clipboard parsing

struct ColumnMapping {
    var date         = 0   // A
    var dayOfWeek    = 1   // B
    var schedule     = 2   // C
    var venue        = 3   // D
    var localTime    = 4   // E
    var meetingTime  = 5   // F
    var meetingPlace = 6   // G
    var attending    = 12  // M
    var absent       = 13  // N
}

extension SheetsService {
    /// Parse tab-separated (Excel copy) or comma-separated text into a 2-D array of strings.
    func parseDelimitedText(_ text: String) -> [[String]] {
        let firstLine = text.components(separatedBy: "\n").first ?? ""
        if firstLine.contains("\t") {
            return text
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\r")) }
                .filter { !$0.isEmpty }
                .map { $0.components(separatedBy: "\t") }
        }
        return parseCSVRows(text)
    }

    /// Convert a 2-D row array (first row = header, skipped) to SheetEvents using the given mapping.
    func rowsToSheetEvents(_ rows: [[String]], mapping: ColumnMapping) -> [SheetEvent] {
        rows.dropFirst().compactMap { row in
            let get: (Int) -> String = { i in i < row.count ? row[i].trimmingCharacters(in: .whitespaces) : "" }
            let date = get(mapping.date)
            let schedule = get(mapping.schedule)
            guard !date.isEmpty, !schedule.isEmpty else { return nil }
            guard !schedule.uppercased().hasPrefix("OFF") else { return nil }
            let raw = RawSheetRow(
                date: date, dayOfWeek: get(mapping.dayOfWeek),
                schedule: schedule, venue: get(mapping.venue),
                localMeetingTime: get(mapping.localTime),
                meetingTime: get(mapping.meetingTime),
                meetingPlace: get(mapping.meetingPlace),
                attendingPlayers: splitCellNames(get(mapping.attending)),
                absentPlayers: splitCellNames(get(mapping.absent))
            )
            return SheetEvent(raw: raw)
        }
    }
}

// MARK: - Raw JSON row from Apps Script

private struct RawSheetRow: Codable {
    var date: String
    var dayOfWeek: String
    var schedule: String
    var venue: String
    var localMeetingTime: String
    var meetingTime: String
    var meetingPlace: String
    var attendingPlayers: [String]
    var absentPlayers: [String]
}

private extension SheetEvent {
    init?(raw: RawSheetRow) {
        guard !raw.date.isEmpty, !raw.schedule.isEmpty else { return nil }
        self.sheetDate          = raw.date
        self.dayOfWeek          = raw.dayOfWeek
        self.schedule           = raw.schedule
        self.venue              = raw.venue
        self.localMeetingTime   = raw.localMeetingTime
        self.meetingTime        = raw.meetingTime
        self.meetingPlace       = raw.meetingPlace
        self.attendingPlayers   = raw.attendingPlayers
        self.absentPlayers      = raw.absentPlayers
    }
}

// MARK: - Apps Script source code (user pastes this into Google Sheets)

extension SheetsService {
    static let appsScriptCode = """
// ① Google Sheetsを開く → 拡張機能 → Apps Script
// ② 以下を貼り付けて保存（Ctrl+S）
// ③ デプロイ → 新しいデプロイ → ウェブアプリ
//    実行: 自分 / アクセス: 全員
// ④ URLをアプリに貼り付ける

function doGet(e) {
  try {
    const action = e.parameter.action;
    if (action === "ping")             return json({ ok: true });
    if (action === "getSheetNames")    return json(getSheetNames());
    if (action === "fetchEvents")      return json(fetchEvents(e.parameter.month));
    if (action === "updateAttendance") return json(updateAttendance(e));
    return json({ error: "Unknown action" });
  } catch(err) {
    return json({ error: err.toString() });
  }
}

function getSheetNames() {
  return SpreadsheetApp.getActiveSpreadsheet()
           .getSheets()
           .map(s => s.getName());
}

// 列インデックス（1始まり）
const COL = { DATE:1, DAY:2, SCHEDULE:3, VENUE:4,
              LOCAL_TIME:5, MEETING_TIME:6, MEETING_PLACE:7,
              SUPPORTERS:8, COACH:9, COACH_STATUS:10, NOTES:11,
              COACH_ATT:12, ATTENDING:13, ABSENT:14 };

function fetchEvents(monthName) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet()
                  .getSheetByName(monthName);
  if (!sheet) return { error: monthName + " シートが見つかりません" };

  const data = sheet.getDataRange().getValues();
  const result = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const date     = String(row[COL.DATE - 1] || "").trim();
    const schedule = String(row[COL.SCHEDULE - 1] || "").trim();
    if (!date || !schedule || schedule.toUpperCase().startsWith("OFF")) continue;

    result.push({
      date:             date,
      dayOfWeek:        String(row[COL.DAY - 1] || "").trim(),
      schedule:         schedule,
      venue:            String(row[COL.VENUE - 1] || "").trim(),
      localMeetingTime: String(row[COL.LOCAL_TIME - 1] || "").trim(),
      meetingTime:      String(row[COL.MEETING_TIME - 1] || "").trim(),
      meetingPlace:     String(row[COL.MEETING_PLACE - 1] || "").trim(),
      attendingPlayers: splitNames(row[COL.ATTENDING - 1]),
      absentPlayers:    splitNames(row[COL.ABSENT - 1])
    });
  }
  return result;
}

function updateAttendance(e) {
  const { month, date, playerName, status } = e.parameter;
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(month);
  if (!sheet) return { error: month + " シートが見つかりません" };

  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    const rowDate = String(data[i][COL.DATE - 1] || "").trim();
    if (rowDate !== date) continue;

    // col M (index 13) = attending, col N (index 14) = absent
    let attending = splitNames(data[i][COL.ATTENDING - 1]);
    let absent    = splitNames(data[i][COL.ABSENT - 1]);

    // remove from both first
    attending = attending.filter(n => n !== playerName);
    absent    = absent.filter(n => n !== playerName);

    if (status === "参加") attending.push(playerName);
    if (status === "欠席") absent.push(playerName);

    sheet.getRange(i + 1, COL.ATTENDING).setValue(attending.join("\\n"));
    sheet.getRange(i + 1, COL.ABSENT).setValue(absent.join("\\n"));
    return { success: true };
  }
  return { error: "行が見つかりません: " + date };
}

function splitNames(cell) {
  if (!cell) return [];
  return String(cell).split(/[\\n,、]/).map(s => s.trim()).filter(s => s.length > 0);
}

function json(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
"""
}
