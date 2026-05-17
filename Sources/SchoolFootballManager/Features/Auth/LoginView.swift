import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingRegister = false
    @State private var showingForgotPassword = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.footballBlue, .footballGreen],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()

                        // Logo and title
                        VStack(spacing: 16) {
                            Image(systemName: "sportscourt")
                                .font(.system(size: 80))
                                .foregroundColor(.white)

                            VStack(spacing: 8) {
                                Text("Football Manager")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text("小学校サッカーチーム管理")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }

                        // Login form
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                CustomTextField(
                                    title: "メールアドレス",
                                    text: $email,
                                    icon: "envelope"
                                )
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)

                                CustomSecureField(
                                    title: "パスワード",
                                    text: $password,
                                    icon: "lock"
                                )
                            }

                            VStack(spacing: 12) {
                                LoadingButton(
                                    title: "ログイン",
                                    isLoading: authService.isLoading
                                ) {
                                    Task {
                                        await login()
                                    }
                                }
                                .disabled(!isValidInput)

                                Button("パスワードを忘れた方") {
                                    showingForgotPassword = true
                                }
                                .foregroundColor(.white)
                                .font(.subheadline)
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)

                        // Register section
                        VStack(spacing: 12) {
                            Text("アカウントをお持ちでない方")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))

                            Button("新規登録") {
                                showingRegister = true
                            }
                            .font(.headline)
                            .foregroundColor(.footballBlue)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.white)
                            .cornerRadius(12)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .errorAlert($authService.error)
        .onAppear {
            // Clear any existing error
            authService.error = nil
        }
    }

    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private func login() async {
        hideKeyboard()

        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            appState.showError("ログインに失敗しました: \(error.localizedDescription)")
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
            }
        }
        .padding(16)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String

    @State private var isShowingPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    if isShowingPassword {
                        TextField("", text: $text)
                            .textFieldStyle(PlainTextFieldStyle())
                    } else {
                        SecureField("", text: $text)
                            .textFieldStyle(PlainTextFieldStyle())
                    }

                    Button {
                        isShowingPassword.toggle()
                    } label: {
                        Image(systemName: isShowingPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService

    @State private var email: String = ""
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    VStack(spacing: 8) {
                        Text("パスワードリセット")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("登録済みのメールアドレスを入力してください。パスワードリセット用のリンクをお送りします。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                CustomTextField(
                    title: "メールアドレス",
                    text: $email,
                    icon: "envelope"
                )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

                VStack(spacing: 16) {
                    LoadingButton(
                        title: "リセットメールを送信",
                        isLoading: authService.isLoading
                    ) {
                        Task {
                            await sendResetEmail()
                        }
                    }
                    .disabled(!email.contains("@"))

                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("パスワードリセット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .alert("送信完了", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("パスワードリセット用のメールを送信しました。メールをご確認ください。")
        }
        .errorAlert($authService.error)
    }

    private func sendResetEmail() async {
        hideKeyboard()

        do {
            try await authService.requestPasswordReset(email: email)
            showingSuccess = true
        } catch {
            // Error will be displayed through the error alert
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
        .environmentObject(AppState())
}