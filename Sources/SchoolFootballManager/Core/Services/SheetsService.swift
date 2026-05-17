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
    if (action === "ping")            return json({ ok: true });
    if (action === "fetchEvents")     return json(fetchEvents(e.parameter.month));
    if (action === "updateAttendance") return json(updateAttendance(e));
    return json({ error: "Unknown action" });
  } catch(err) {
    return json({ error: err.toString() });
  }
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
