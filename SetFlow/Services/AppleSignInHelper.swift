//
//  AppleSignInHelper.swift
//  SetFlow
//
//  Presents Sign in with Apple and returns idToken + rawNonce for Firebase.
//  Enable "Sign in with Apple" capability and Apple provider in Firebase Console.
//

import Foundation
import AuthenticationServices
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

final class AppleSignInHelper: NSObject {
    static let shared = AppleSignInHelper()

    private var currentNonce: String?
    private var onSuccess: ((String, String, PersonNameComponents?) -> Void)?
    private var onFailure: ((Error) -> Void)?

    private override init() {
        super.init()
    }

    /// Call from the Sign In screen. Presents Apple ID sheet; on success calls back with idToken, rawNonce, fullName.
    func performSignIn(
        onSuccess: @escaping (String, String, PersonNameComponents?) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        currentNonce = randomNonceString()
        guard let nonce = currentNonce else {
            onFailure(NSError(domain: "AppleSignInHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate nonce"]))
            return
        }
        let hashedNonce = sha256(nonce)
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return randomBytes.map { charset[Int($0) % charset.count] }.map(String.init).joined()
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInHelper: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onFailure?(NSError(domain: "AppleSignInHelper", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            cleanup()
            return
        }
        guard let nonce = currentNonce else {
            onFailure?(NSError(domain: "AppleSignInHelper", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid state: no nonce"]))
            cleanup()
            return
        }
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            onFailure?(NSError(domain: "AppleSignInHelper", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
            cleanup()
            return
        }
        onSuccess?(idTokenString, nonce, appleIDCredential.fullName)
        cleanup()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onFailure?(error)
        cleanup()
    }

    private func cleanup() {
        currentNonce = nil
        onSuccess = nil
        onFailure = nil
    }
}

extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first { $0.isKeyWindow }
            ?? windows.first
            ?? UIWindow()
        #else
        return UIWindow()
        #endif
    }
}
