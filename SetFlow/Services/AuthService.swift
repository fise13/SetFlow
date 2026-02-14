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
}
