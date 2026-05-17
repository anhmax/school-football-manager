import SwiftUI

struct SimpleLoginView: View {
    @EnvironmentObject var accountStore: AccountStore

    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    enum Field { case username, password }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.footballGreen, .footballBlue],
                                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 90, height: 90)
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                Text("Football Manager")
                    .font(.title2).fontWeight(.bold)
                Text("3年生チーム")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .padding(.bottom, 48)

            // Form
            VStack(spacing: 14) {
                // Username
                HStack(spacing: 10) {
                    Image(systemName: "person")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("ユーザー名", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .username)
                        .onSubmit { focusedField = .password }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Password
                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Group {
                        if showPassword {
                            TextField("パスワード", text: $password)
                        } else {
                            SecureField("パスワード", text: $password)
                        }
                    }
                    .focused($focusedField, equals: .password)
                    .onSubmit { attemptLogin() }
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Error
                if let error = accountStore.loginError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                        Text(error)
                    }
                    .font(.caption)
                    .foregroundColor(.statusError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }

                // Login button
                Button(action: attemptLogin) {
                    Text("ログイン")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            username.isEmpty || password.isEmpty
                                ? Color.footballGreen.opacity(0.4)
                                : Color.footballGreen
                        )
                        .cornerRadius(14)
                }
                .disabled(username.isEmpty || password.isEmpty)
                .padding(.top, 6)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear { focusedField = .username }
    }

    private func attemptLogin() {
        accountStore.login(username: username, password: password)
    }
}

#Preview {
    SimpleLoginView()
        .environmentObject(AccountStore())
}
