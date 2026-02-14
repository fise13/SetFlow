//
//  InviteCodeService.swift
//  SetFlow
//

import Foundation
import FirebaseFirestore

private let inviteCodesCollection = "inviteCodes"
private let codeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // avoid confusing chars (0,O,I,1)
private let codeSegmentLength = 4
private let codeSegmentCount = 2
private let expiryHours: Double = 24

final class InviteCodeService {
    private let db = Firestore.firestore()

    /// Generates a new invite code in format XXXX-XXXX, valid for 24 hours.
    func generateCode(coachId: String) async throws -> String {
        let code = generateRandomCode()
        let expiresAt = Date().addingTimeInterval(expiryHours * 3600)
        let normalizedCode = code.uppercased().replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        let data: [String: Any] = [
            "code": code,
            "coachId": coachId,
            "expiresAt": Timestamp(date: expiresAt),
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection(inviteCodesCollection)
            .document(normalizedCode)
            .setData(data)
        return formatCodeForDisplay(normalizedCode)
    }

    /// Redeems an invite code. Returns coachId if valid, nil if expired or invalid. Invalidates the code (one-time use).
    func redeemCode(_ code: String) async throws -> String? {
        let normalized = code.uppercased().replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard normalized.count == 8 else { return nil }
        let docId = normalized
        let ref = db.collection(inviteCodesCollection).document(docId)
        let snapshot = try await ref.getDocument()
        guard let data = snapshot.data(),
              let coachId = data["coachId"] as? String,
              let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue(),
              expiresAt > Date() else {
            return nil
        }
        try await ref.delete()
        return coachId
    }

    private func generateRandomCode() -> String {
        let chars = Array(codeChars)
        var result = ""
        for _ in 0..<(codeSegmentLength * codeSegmentCount) {
            result += String(chars.randomElement()!)
        }
        return formatCodeForDisplay(result)
    }

    private func formatCodeForDisplay(_ raw: String) -> String {
        let s = String(raw.prefix(8))
        if s.count >= 8 {
            return String(s.prefix(4)) + "-" + String(s.suffix(4))
        }
        return s
    }
}
