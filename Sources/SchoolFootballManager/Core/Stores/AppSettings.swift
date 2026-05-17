import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("sheetsScriptURL")    var sheetsScriptURL: String = ""
    @AppStorage("spreadsheetFileURL") var spreadsheetFileURL: String = ""

    /// True if attendance sync (write-back) is available
    var isSheetsConfigured: Bool {
        !sheetsScriptURL.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// True if event import (read) is available — either via CSV or Apps Script
    var isImportConfigured: Bool {
        !spreadsheetFileURL.trimmingCharacters(in: .whitespaces).isEmpty || isSheetsConfigured
    }
}
