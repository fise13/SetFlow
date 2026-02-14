//
//  UserService.swift
//  SetFlow
//

import Foundation
import FirebaseFirestore

private let usersCollection = "users"

final class UserService {
    private let db = Firestore.firestore()

    func createUser(id: String, name: String, role: UserRole, coachId: String? = nil) async throws {
        var data: [String: Any] = [
            "name": name,
            "role": role.rawValue
        ]
        if let coachId = coachId {
            data["coachId"] = coachId
        }
        try await db.collection(usersCollection).document(id).setData(data)
    }

    func getUser(id: String) async throws -> User? {
        let snapshot = try await db.collection(usersCollection).document(id).getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        let name = data["name"] as? String ?? ""
        let roleRaw = data["role"] as? String ?? UserRole.athlete.rawValue
        let role = UserRole(rawValue: roleRaw) ?? .athlete
        let coachId = data["coachId"] as? String
        return User(id: id, name: name, role: role, coachId: coachId)
    }

    func updateUser(id: String, name: String? = nil, role: UserRole? = nil, coachId: String?? = nil) async throws {
        var data: [String: Any] = [:]
        if let name = name { data["name"] = name }
        if let role = role { data["role"] = role.rawValue }
        if let coachId = coachId {
            if let value = coachId { data["coachId"] = value }
            else { data["coachId"] = FieldValue.delete() }
        }
        guard !data.isEmpty else { return }
        try await db.collection(usersCollection).document(id).updateData(data)
    }

    func setCoachId(athleteId: String, coachId: String) async throws {
        try await db.collection(usersCollection).document(athleteId).updateData(["coachId": coachId])
    }

    func athletesForCoach(coachId: String) async throws -> [User] {
        let snapshot = try await db.collection(usersCollection)
            .whereField("coachId", isEqualTo: coachId)
            .whereField("role", isEqualTo: UserRole.athlete.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { doc -> User? in
            let data = doc.data()
            let name = data["name"] as? String ?? ""
            let coachIdVal = data["coachId"] as? String
            return User(id: doc.documentID, name: name, role: .athlete, coachId: coachIdVal)
        }
    }
}
