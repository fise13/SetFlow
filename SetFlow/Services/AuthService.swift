//
//  AuthService.swift
//  SetFlow
//

import Foundation
import FirebaseAuth
import Combine

final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentFirebaseUser: FirebaseAuth.User?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentFirebaseUser = user
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isSignedIn: Bool { currentFirebaseUser != nil }
    var uid: String? { currentFirebaseUser?.uid }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        if let displayName, !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            try await changeRequest.commitChanges()
            await MainActor.run {
                self.currentFirebaseUser = Auth.auth().currentUser
            }
        }
    }

    func signInAnonymously() async throws {
        _ = try await Auth.auth().signInAnonymously()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func linkAnonymousWithEmail(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser, user.isAnonymous else { return }
        let cred = EmailAuthProvider.credential(withEmail: email, password: password)
        _ = try await user.link(with: cred)
    }

    /// Returns a short, user-friendly message for Auth errors (e.g. "No account with this email").
    static func userFriendlyMessage(for error: Error) -> String {
        let ns = error as NSError
        guard ns.domain.contains("Auth") else { return error.localizedDescription }
        guard let code = AuthErrorCode(rawValue: ns.code) else { return error.localizedDescription }
        switch code {
        case .userNotFound:
            return String(localized: "auth_error_user_not_found")
        case .wrongPassword:
            return String(localized: "auth_error_wrong_password")
        case .invalidEmail:
            return String(localized: "auth_error_invalid_email")
        case .invalidCredential:
            return String(localized: "auth_error_invalid_credential")
        case .userDisabled:
            return String(localized: "auth_error_user_disabled")
        case .emailAlreadyInUse:
            return String(localized: "auth_error_email_in_use")
        case .weakPassword:
            return String(localized: "auth_error_weak_password")
        case .tooManyRequests:
            return String(localized: "auth_error_too_many_requests")
        case .networkError:
            return String(localized: "auth_error_network")
        case .operationNotAllowed:
            return String(localized: "auth_error_operation_not_allowed")
        case .requiresRecentLogin:
            return String(localized: "auth_error_requires_recent_login")
        default:
            return error.localizedDescription
        }
    }
}
