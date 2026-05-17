import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var error: String?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadCurrentUser(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await loadCurrentUser(uid: result.user.uid)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func signUp(email: String, password: String, name: String, role: UserRole, teamId: String?) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            let newUser = AppUser(
                email: email,
                name: name,
                role: role,
                teamId: teamId,
                approvalStatus: role == .admin ? .approved : .pending
            )

            try await saveUser(newUser, uid: result.user.uid)
            await loadCurrentUser(uid: result.user.uid)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func signOut() async throws {
        try auth.signOut()
        currentUser = nil
        isLoggedIn = false
    }

    func requestPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    private func loadCurrentUser(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if let user = try? document.data(as: AppUser.self) {
                currentUser = user
                isLoggedIn = user.isApproved

                if !user.isApproved {
                    error = "アカウントの承認待ちです。管理者の承認をお待ちください。"
                }
            }
        } catch {
            print("Error loading current user: \(error)")
            self.error = error.localizedDescription
        }
    }

    private func saveUser(_ user: AppUser, uid: String) async throws {
        var userToSave = user
        userToSave.id = uid
        try await db.collection("users").document(uid).setData(from: userToSave)
    }

    func updateFCMToken(_ token: String) async {
        guard let userId = currentUser?.id else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": token,
                "updatedAt": Date()
            ])
        } catch {
            print("Error updating FCM token: \(error)")
        }
    }

    func checkUserRole() -> UserRole? {
        return currentUser?.role
    }

    func canManageTeam(_ teamId: String) -> Bool {
        guard let user = currentUser else { return false }

        if user.role == .admin {
            return true
        }

        if user.role == .manager && user.isApproved && user.teamId == teamId {
            return true
        }

        return false
    }

    func canViewTeam(_ teamId: String) -> Bool {
        guard let user = currentUser else { return false }

        if user.role == .admin {
            return true
        }

        if user.role == .manager && user.isApproved && user.teamId == teamId {
            return true
        }

        if user.role == .parent && user.teamId == teamId {
            return true
        }

        return false
    }

    func refreshUserData() async {
        guard let userId = currentUser?.id else { return }
        await loadCurrentUser(uid: userId)
    }
}