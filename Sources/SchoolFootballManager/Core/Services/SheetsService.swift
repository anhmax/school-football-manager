import Foundation

struct SheetRegistration: Codable {
    var eventTitle: String
    var playerName: String
    var status: String
    var updatedAt: String

    var attendanceStatus: AttendanceStatus {
        switch status {
        case "参加":   return .attending
        case "欠席":   return .absent
        default:      return .notConfirmed
        }
    }
}

@MainActor
class SheetsService: ObservableObject {
    @Published var isSyncing    = false
    @Published var lastSyncTime: Date?
    @Published var syncError:   String?

    // MARK: - Fetch all registrations for an event

    func fetch(eventTitle: String, scriptURL: String) async throws -> [SheetRegistration] {
        let urlString = "\(scriptURL)?action=fetch&eventTitle=\(eventTitle.urlEncoded)"
        guard let url = URL(string: urlString) else { throw SheetsError.invalidURL }

        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        let (data, response) = try await URLSession.shared.data(from: url)
        try checkHTTP(response)

        let result = try JSONDecoder().decode([SheetRegistration].self, from: data)
        lastSyncTime = Date()
        return result
    }

    // MARK: - Push a single status update

    func update(eventTitle: String, playerName: String,
                status: AttendanceStatus, scriptURL: String) async throws {
        let statusStr = status.sheetLabel
        let urlString = "\(scriptURL)?action=update"
            + "&eventTitle=\(eventTitle.urlEncoded)"
            + "&playerName=\(playerName.urlEncoded)"
            + "&status=\(statusStr.urlEncoded)"

        guard let url = URL(string: urlString) else { throw SheetsError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        try checkHTTP(response)

        struct Result: Codable { var success: Bool? ; var error: String? }
        let result = try JSONDecoder().decode(Result.self, from: data)
        if result.success != true {
            throw SheetsError.serverError(result.error ?? "Unknown error")
        }
        lastSyncTime = Date()
    }

    // MARK: - Test connection

    func testConnection(scriptURL: String) async throws {
        let urlString = "\(scriptURL)?action=fetch&eventTitle=__test__"
        guard let url = URL(string: urlString) else { throw SheetsError.invalidURL }
        let (_, response) = try await URLSession.shared.data(from: url)
        try checkHTTP(response)
    }

    // MARK: - Helpers

    private func checkHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw SheetsError.httpError(http.statusCode)
        }
    }
}

// MARK: - Errors

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

// MARK: - Extensions

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
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

// MARK: - Apps Script source (display only, user copies to Google Sheet)

extension SheetsService {
    static let appsScriptCode = """
// ① Google Sheetsを開く → 拡張機能 → Apps Script
// ② 以下のコードを貼り付けてCtrl+S
// ③ デプロイ → 新しいデプロイ → ウェブアプリ
//    ・次のユーザーとして実行: 自分
//    ・アクセスできるユーザー: 全員
// ④ URLをコピーしてアプリに貼り付ける

const SHEET_NAME = "登録";

function doGet(e) {
  try {
    const ss    = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAME) || createSheet(ss);
    const action = e.parameter.action || "fetch";

    if (action === "fetch") {
      const title = e.parameter.eventTitle || "";
      const rows  = getRows(sheet);
      const result = rows.filter(r => !title || r.eventTitle === title);
      return json(result);
    }

    if (action === "update") {
      const { eventTitle, playerName, status } = e.parameter;
      upsert(sheet, eventTitle, playerName, status);
      return json({ success: true });
    }

    return json({ error: "Unknown action" });
  } catch (err) {
    return json({ error: err.toString() });
  }
}

function getRows(sheet) {
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];
  return data.slice(1).map(r => ({
    eventTitle: r[0], playerName: r[1],
    status: r[2], updatedAt: r[3]
  }));
}

function upsert(sheet, eventTitle, playerName, status) {
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === eventTitle && data[i][1] === playerName) {
      sheet.getRange(i + 1, 3).setValue(status);
      sheet.getRange(i + 1, 4).setValue(new Date().toLocaleString("ja-JP"));
      return;
    }
  }
  sheet.appendRow([eventTitle, playerName, status,
                   new Date().toLocaleString("ja-JP")]);
}

function createSheet(ss) {
  const s = ss.insertSheet(SHEET_NAME);
  s.appendRow(["イベント名", "選手名", "ステータス", "更新日時"]);
  return s;
}

function json(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
"""
}
