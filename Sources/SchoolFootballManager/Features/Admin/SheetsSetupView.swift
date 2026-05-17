import SwiftUI

struct SheetsSetupView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var sheets = SheetsService()

    @State private var urlDraft     = ""
    @State private var isTesting    = false
    @State private var testResult:  TestResult? = nil
    @State private var showScript   = false

    enum TestResult { case success, failure(String) }

    var body: some View {
        Form {
            statusSection
            urlSection
            scriptSection
            guideSection
        }
        .navigationTitle("Google Sheets 連携")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { urlDraft = settings.sheetsScriptURL }
        .sheet(isPresented: $showScript) {
            ScriptCodeSheet()
        }
    }

    // MARK: - Sections

    var statusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: settings.isSheetsConfigured ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundColor(settings.isSheetsConfigured ? .statusSuccess : .statusWarning)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.isSheetsConfigured ? "連携済み" : "未設定")
                        .fontWeight(.semibold)
                    Text(settings.isSheetsConfigured
                         ? "参加登録をSheetsと同期できます"
                         : "Apps ScriptのURLを設定してください")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    var urlSection: some View {
        Section("Apps Script URL") {
            TextField("https://script.google.com/macros/s/...", text: $urlDraft, axis: .vertical)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .lineLimit(3...5)
                .font(.caption)

            HStack(spacing: 12) {
                Button("保存") {
                    settings.sheetsScriptURL = urlDraft.trimmingCharacters(in: .whitespaces)
                    testResult = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.footballGreen)
                .disabled(urlDraft.trimmingCharacters(in: .whitespaces).isEmpty)

                Button(isTesting ? "確認中..." : "接続テスト") {
                    Task { await runTest() }
                }
                .buttonStyle(.bordered)
                .disabled(isTesting || urlDraft.trimmingCharacters(in: .whitespaces).isEmpty)
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
    }

    var scriptSection: some View {
        Section {
            Button {
                showScript = true
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Apps Scriptコードを表示")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                }
            }
        } header: {
            Text("ステップ1: スクリプトを設定")
        }
    }

    var guideSection: some View {
        Section("ステップ2: デプロイ手順") {
            VStack(alignment: .leading, spacing: 10) {
                StepRow(n: 1, text: "Google Sheetsを開く → 拡張機能 → Apps Script")
                StepRow(n: 2, text: "コードを貼り付けてCtrl+S で保存")
                StepRow(n: 3, text: "デプロイ → 新しいデプロイ → ウェブアプリ")
                StepRow(n: 4, text: "「次のユーザーとして実行」: 自分\n「アクセスできるユーザー」: 全員")
                StepRow(n: 5, text: "URLをコピーして上のフィールドに貼り付けて保存")
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Test

    private func runTest() async {
        isTesting = true
        testResult = nil
        let url = urlDraft.trimmingCharacters(in: .whitespaces)
        do {
            try await sheets.testConnection(scriptURL: url)
            testResult = .success
        } catch {
            testResult = .failure(error.localizedDescription)
        }
        isTesting = false
    }
}

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

// MARK: - Script Code Sheet

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
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(copied ? Color.statusSuccess : Color.footballGreen)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.2), value: copied)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Apps Script コード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
