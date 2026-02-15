//
//  CoachRequestService.swift
//  SetFlow
//
//  Sends "write to coach" requests from athletes; coach sees them as notifications in Updates.
//

import Foundation
import FirebaseFirestore

// MARK: - Model

struct CoachRequest: Identifiable {
    let id: String
    let coachId: String
    let athleteId: String
    let athleteName: String
    let type: String // "workout_request"
    let workoutTitle: String?
    let rating: Int?
    let createdAt: Date
}

// MARK: - Service

private let coachRequestsCollection = "coachRequests"

final class CoachRequestService {
    private let db = Firestore.firestore()

    /// Athlete sends a "I need a workout" request; coach will see it in Updates.
    func sendWorkoutRequest(athleteId: String, athleteName: String, coachId: String) async throws {
        let ref = db.collection(coachRequestsCollection).document()
        let data: [String: Any] = [
            "coachId": coachId,
            "athleteId": athleteId,
            "athleteName": athleteName,
            "type": "workout_request",
            "createdAt": Timestamp(date: Date())
        ]
        try await ref.setData(data)
    }

    /// Athlete completed workout and sends summary ping to coach.
    func sendWorkoutCompleted(
        athleteId: String,
        athleteName: String,
        coachId: String,
        workoutTitle: String,
        rating: Int
    ) async throws {
        let ref = db.collection(coachRequestsCollection).document()
        let data: [String: Any] = [
            "coachId": coachId,
            "athleteId": athleteId,
            "athleteName": athleteName,
            "type": "workout_completed",
            "workoutTitle": workoutTitle,
            "rating": rating,
            "createdAt": Timestamp(date: Date())
        ]
        try await ref.setData(data)
    }

    /// Fetch requests for coach (Updates tab). Use pull-to-refresh or onAppear.
    func fetchRequests(coachId: String) async throws -> [CoachRequest] {
        let snapshot = try await db.collection(coachRequestsCollection)
            .whereField("coachId", isEqualTo: coachId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        return snapshot.documents.compactMap { doc -> CoachRequest? in
            let data = doc.data()
            guard let coachId = data["coachId"] as? String,
                  let athleteId = data["athleteId"] as? String,
                  let athleteName = data["athleteName"] as? String,
                  let type = data["type"] as? String,
                  let ts = data["createdAt"] as? Timestamp else { return nil }
            return CoachRequest(
                id: doc.documentID,
                coachId: coachId,
                athleteId: athleteId,
                athleteName: athleteName,
                type: type,
                workoutTitle: data["workoutTitle"] as? String,
                rating: data["rating"] as? Int,
                createdAt: ts.dateValue()
            )
        }
    }
}
