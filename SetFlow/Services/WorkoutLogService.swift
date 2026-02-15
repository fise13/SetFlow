//
//  WorkoutLogService.swift
//  SetFlow
//

import Foundation
import FirebaseFirestore

private let logsCollection = "workoutLogs"

final class WorkoutLogService {
    private let db = Firestore.firestore()

    func saveLog(_ log: WorkoutLog) async throws {
        let feedbackArray = log.exerciseFeedbacks.map { feedback in
            [
                "id": feedback.id,
                "exerciseName": feedback.exerciseName,
                "difficulty": feedback.difficulty,
                "note": feedback.note as Any
            ]
        }
        let data: [String: Any] = [
            "athleteId": log.athleteId,
            "workoutTitle": log.workoutTitle,
            "date": Timestamp(date: log.date),
            "durationMinutes": log.durationMinutes,
            "totalSets": log.totalSets,
            "totalVolume": log.totalVolume,
            "rating": log.rating,
            "exerciseFeedbacks": feedbackArray,
            "status": log.status.rawValue
        ]
        if log.id.isEmpty || log.id.hasPrefix("temp-") {
            let ref = db.collection(logsCollection).document()
            try await ref.setData(data)
        } else {
            try await db.collection(logsCollection).document(log.id).setData(data)
        }
    }

    func logsForAthlete(athleteId: String, limit: Int = 50) async throws -> [WorkoutLog] {
        let snapshot = try await db.collection(logsCollection)
            .whereField("athleteId", isEqualTo: athleteId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { logFromDoc($0, athleteId: athleteId) }
    }

    func logsForAthleteListener(athleteId: String, limit: Int = 50, onUpdate: @escaping ([WorkoutLog]) -> Void) -> ListenerRegistration {
        db.collection(logsCollection)
            .whereField("athleteId", isEqualTo: athleteId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot, error == nil else { return }
                let logs = snapshot.documents.compactMap { self.logFromDoc($0, athleteId: athleteId) }
                DispatchQueue.main.async { onUpdate(logs) }
            }
    }

    private func logFromDoc(_ doc: DocumentSnapshot, athleteId: String) -> WorkoutLog? {
        let data = doc.data()
        guard let workoutTitle = data?["workoutTitle"] as? String,
              let date = (data?["date"] as? Timestamp)?.dateValue(),
              let durationMinutes = data?["durationMinutes"] as? Int,
              let totalSets = data?["totalSets"] as? Int,
              let totalVolume = data?["totalVolume"] as? Double,
              let rating = data?["rating"] as? Int else { return nil }
        let feedbacksData = data?["exerciseFeedbacks"] as? [[String: Any]] ?? []
        let feedbacks: [ExerciseFeedback] = feedbacksData.compactMap { item in
            guard let id = item["id"] as? String,
                  let exerciseName = item["exerciseName"] as? String,
                  let difficulty = item["difficulty"] as? Int else { return nil }
            return ExerciseFeedback(
                id: id,
                exerciseName: exerciseName,
                difficulty: min(5, max(1, difficulty)),
                note: item["note"] as? String
            )
        }
        return WorkoutLog(
            id: doc.documentID,
            athleteId: athleteId,
            workoutTitle: workoutTitle,
            date: date,
            durationMinutes: durationMinutes,
            totalSets: totalSets,
            totalVolume: totalVolume,
            rating: rating,
            exerciseFeedbacks: feedbacks,
            status: WorkoutSessionStatus(rawValue: data?["status"] as? String ?? "completed") ?? .completed
        )
    }
}
