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
        let data: [String: Any] = [
            "athleteId": log.athleteId,
            "workoutTitle": log.workoutTitle,
            "date": Timestamp(date: log.date),
            "durationMinutes": log.durationMinutes,
            "totalSets": log.totalSets,
            "totalVolume": log.totalVolume,
            "rating": log.rating
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
        return snapshot.documents.compactMap { doc -> WorkoutLog? in
            let data = doc.data()
            guard let workoutTitle = data["workoutTitle"] as? String,
                  let date = (data["date"] as? Timestamp)?.dateValue(),
                  let durationMinutes = data["durationMinutes"] as? Int,
                  let totalSets = data["totalSets"] as? Int,
                  let totalVolume = data["totalVolume"] as? Double,
                  let rating = data["rating"] as? Int else { return nil }
            return WorkoutLog(
                id: doc.documentID,
                athleteId: athleteId,
                workoutTitle: workoutTitle,
                date: date,
                durationMinutes: durationMinutes,
                totalSets: totalSets,
                totalVolume: totalVolume,
                rating: rating
            )
        }
    }
}
