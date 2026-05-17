import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?

    private let authService = AuthService()

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, name: String, role: UserRole, teamId: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signUp(email: email, password: password, name: name, role: role, teamId: teamId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func requestPasswordReset(email: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.requestPasswordReset(email: email)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearError() {
        error = nil
    }
}