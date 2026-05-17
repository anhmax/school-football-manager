import SwiftUI

struct SheetsSetupView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var sheets = SheetsService()

    @State private var fileDraft   = ""
    @State private var scriptDraft = ""
    @State private var isTesting   = false
    @State private var testResult: TestResult? = nil
    @State private var showScript  = false

    enum TestResult { case success, failure(String) }

    var body: some View {
        Form {
            // ── ① File URL (works with Excel too) ────────────────────
            Section {
                TextField("https://docs.google.com/spreadsheets/d/...",
                          text: $fileDraft, axis: .vertical)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .lineLimit(3...5)
                    .font(.caption)

                Button("保存") {
                    settings.spreadsheetFileURL = fileDraft.trimmingCharacters(in: .whitespaces)
                }
                .buttonStyle(.borderedProminent)
                .tint(.footballGreen)
                .disabled(fileDraft.trimmingCharacters(in: .whitespaces).isEmpty)

                if !settings.spreadsheetFileURL.isEmpty {
                    Label("保存済み", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.statusSuccess).font(.caption)
                }
            } header: {
                Text("ステップ1: スプレッドシートのURL")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Google DriveのExcelファイル・Google Sheetsどちらでも使えます。")
                    Text("ファイルの共有設定を「リンクを知っている全員が閲覧可能」にしてから、共有リンクをここに貼り付けてください。")
                    Text("これだけでイベントのインポートができます。")
                }
                .font(.caption)
            }

            // ── ② Apps Script URL (optional, for write-back) ─────────
            Section {
                Button { showScript = true } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Apps Scriptコードを表示")
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("ステップ2（任意）: 参加登録の同期")
            } footer: {
                Text("参加登録をスプレッドシートに書き戻したい場合のみ設定が必要です。Google Sheetsファイルのみ対応（Excelファイルは不可）。")
                    .font(.caption)
            }

            Section("Apps Script URL（任意）") {
                TextField("https://script.google.com/macros/s/...",
                          text: $scriptDraft, axis: .vertical)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .lineLimit(3...5)
                    .font(.caption)

                HStack(spacing: 12) {
                    Button("保存") {
                        settings.sheetsScriptURL = scriptDraft.trimmingCharacters(in: .whitespaces)
                        testResult = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.footballBlue)
                    .disabled(scriptDraft.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button(isTesting ? "確認中..." : "接続テスト") {
                        Task { await runTest() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isTesting || scriptDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if let result = testResult {
                    switch result {
                    case .success:
                        Label("接続成功！", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.statusSuccess).font(.subheadline)
                    case .failure(let msg):
                        Label("失敗: \(msg)", systemImage: "xmark.circle.fill")
                            .foregroundColor(.statusError).font(.caption)
                    }
                }
            }

            // ── Deploy guide ──────────────────────────────────────────
            Section("Apps Scriptデプロイ手順") {
                VStack(alignment: .leading, spacing: 10) {
                    StepRow(n: 1, text: "Google Sheetsを開く → 拡張機能 → Apps Script")
                    StepRow(n: 2, text: "コードを貼り付けてCtrl+S で保存")
                    StepRow(n: 3, text: "デプロイ → 新しいデプロイ → ウェブアプリ")
                    StepRow(n: 4, text: "「次のユーザーとして実行」: 自分\n「アクセスできるユーザー」: 全員")
                    StepRow(n: 5, text: "URLをコピーして上のフィールドに貼り付け")
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Google Sheets 連携")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fileDraft   = settings.spreadsheetFileURL
            scriptDraft = settings.sheetsScriptURL
        }
        .sheet(isPresented: $showScript) {
            ScriptCodeSheet()
        }
    }

    private func runTest() async {
        isTesting = true; testResult = nil
        do {
            try await sheets.testConnection(scriptURL: scriptDraft.trimmingCharacters(in: .whitespaces))
            testResult = .success
        } catch {
            testResult = .failure(error.localizedDescription)
        }
        isTesting = false
    }
}

// MARK: - Supporting views (unchanged)

struct StepRow: View {
    let n: Int
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Color.footballGreen).frame(width: 22, height: 22)
                Text("\(n)").font(.caption.bold()).foregroundColor(.white)
            }
            Text(text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ScriptCodeSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var copied = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("このコードをApps Scriptに貼り付けてください")
                        .font(.subheadline).foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    Text(SheetsService.appsScriptCode)
                        .font(.system(.caption, design: .monospaced))
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    Button {
                        UIPasteboard.general.string = SheetsService.appsScriptCode
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Label(copied ? "コピー済み" : "コードをコピー",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(copied ? Color.statusSuccess : Color.footballGreen)
                            .foregroundColor(.white).cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.2), value: copied)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Apps Script コード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("閉じる") { dismiss() } } }
        }
    }
}
