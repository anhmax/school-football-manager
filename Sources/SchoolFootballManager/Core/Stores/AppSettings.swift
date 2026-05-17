import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("sheetsScriptURL") var sheetsScriptURL: String = ""

    var isSheetsConfigured: Bool {
        !sheetsScriptURL.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
