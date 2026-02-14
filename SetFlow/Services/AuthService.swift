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

    func signUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
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
            return "No account found with this email. Check the address or sign up."
        case .wrongPassword:
            return "Incorrect password. Try again or use “Forgot password?”."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidCredential:
            return "Invalid or expired login. Please sign in again with your email and password."
        case .userDisabled:
            return "This account has been disabled. Contact support."
        case .emailAlreadyInUse:
            return "This email is already registered. Sign in or use “Forgot password?”."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .tooManyRequests:
            return "Too many attempts. Please try again in a few minutes."
        case .networkError:
            return "No internet connection. Check your network and try again."
        case .operationNotAllowed:
            return "Email sign-in is not enabled for this app. Contact support."
        case .requiresRecentLogin:
            return "Please sign out and sign in again, then try again."
        default:
            return error.localizedDescription
        }
    }
}
