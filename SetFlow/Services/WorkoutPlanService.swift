//
//  WorkoutPlanService.swift
//  SetFlow
//

import Foundation
import FirebaseFirestore

private let plansCollection = "workoutPlans"

final class WorkoutPlanService {
    private let db = Firestore.firestore()
    private let userService = UserService()

    private func planFromDoc(_ doc: DocumentSnapshot) throws -> WorkoutPlan? {
        guard doc.exists, let data = doc.data() else { return nil }
        let id = doc.documentID
        let name = data["name"] as? String ?? ""
        let description = data["description"] as? String ?? ""
        let athleteId = data["athleteId"] as? String ?? ""
        let coachId = data["coachId"] as? String ?? ""
        let daysData = data["days"] as? [[String: Any]] ?? []
        let days = daysData.compactMap { dayDict -> WorkoutDay? in
            guard let dayId = dayDict["id"] as? String,
                  let title = dayDict["title"] as? String,
                  let focus = dayDict["focus"] as? String else { return nil }
            let date = (dayDict["date"] as? Timestamp)?.dateValue() ?? Date()
            let exercisesData = dayDict["exercises"] as? [[String: Any]] ?? []
            let exercises = exercisesData.compactMap { exDict -> Exercise? in
                guard let exId = exDict["id"] as? String,
                      let exName = exDict["name"] as? String else { return nil }
                return Exercise(
                    id: exId,
                    name: exName,
                    sets: exDict["sets"] as? Int ?? 0,
                    reps: exDict["reps"] as? Int ?? 0,
                    weight: exDict["weight"] as? Double ?? 0,
                    restSeconds: exDict["restSeconds"] as? Int ?? 90,
                    notes: exDict["notes"] as? String,
                    isCompleted: exDict["isCompleted"] as? Bool ?? false
                )
            }
            return WorkoutDay(id: dayId, title: title, focus: focus, date: date, exercises: exercises)
        }
        let lastUpdatedAt = (data["lastUpdatedAt"] as? Timestamp)?.dateValue()
        return WorkoutPlan(id: id, name: name, description: description, athleteId: athleteId, coachId: coachId, athlete: nil, days: days, lastUpdatedAt: lastUpdatedAt)
    }

    func createPlan(name: String, description: String, athleteId: String, coachId: String, days: [WorkoutDay]) async throws -> WorkoutPlan {
        let ref = db.collection(plansCollection).document()
        let planId = ref.documentID
        let planData = planDocumentData(id: planId, name: name, description: description, athleteId: athleteId, coachId: coachId, days: days)
        try await ref.setData(planData)
        return WorkoutPlan(id: planId, name: name, description: description, athleteId: athleteId, coachId: coachId, athlete: nil, days: days)
    }

    func updatePlan(_ plan: WorkoutPlan) async throws {
        let data = planDocumentData(id: plan.id, name: plan.name, description: plan.description, athleteId: plan.athleteId, coachId: plan.coachId, days: plan.days)
        let updateData: [String: Any] = [
            "name": data["name"]!,
            "description": data["description"]!,
            "athleteId": data["athleteId"]!,
            "coachId": data["coachId"]!,
            "days": data["days"]!
        ]
        try await db.collection(plansCollection).document(plan.id).updateData(updateData)
    }

    func deletePlan(id: String) async throws {
        try await db.collection(plansCollection).document(id).delete()
    }

    func plansForAthlete(athleteId: String) async throws -> [WorkoutPlan] {
        let snapshot = try await db.collection(plansCollection)
            .whereField("athleteId", isEqualTo: athleteId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? planFromDoc($0) }
    }

    func plansForAthleteListener(athleteId: String, onUpdate: @escaping ([WorkoutPlan]) -> Void) -> ListenerRegistration {
        db.collection(plansCollection)
            .whereField("athleteId", isEqualTo: athleteId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot, error == nil else { return }
                let plans = snapshot.documents.compactMap { try? self.planFromDoc($0) }
                DispatchQueue.main.async { onUpdate(plans) }
            }
    }

    func plansForCoach(coachId: String) async throws -> [WorkoutPlan] {
        let snapshot = try await db.collection(plansCollection)
            .whereField("coachId", isEqualTo: coachId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        var plans = snapshot.documents.compactMap { try? planFromDoc($0) }
        for i in plans.indices {
            if let athlete = try? await userService.getUser(id: plans[i].athleteId) {
                plans[i] = WorkoutPlan(id: plans[i].id, name: plans[i].name, description: plans[i].description, athleteId: plans[i].athleteId, coachId: plans[i].coachId, athlete: athlete, days: plans[i].days, lastUpdatedAt: plans[i].lastUpdatedAt)
            }
        }
        return plans
    }

    private func planDocumentData(id: String, name: String, description: String, athleteId: String, coachId: String, days: [WorkoutDay], lastUpdatedAt: Date? = nil) -> [String: Any] {
        let daysArray = days.map { day -> [String: Any] in
            let exercisesArray = day.exercises.map { ex -> [String: Any] in
                [
                    "id": ex.id,
                    "name": ex.name,
                    "sets": ex.sets,
                    "reps": ex.reps,
                    "weight": ex.weight,
                    "restSeconds": ex.restSeconds,
                    "notes": ex.notes as Any,
                    "isCompleted": ex.isCompleted
                ]
            }
            return [
                "id": day.id,
                "title": day.title,
                "focus": day.focus,
                "date": Timestamp(date: day.date),
                "exercises": exercisesArray
            ]
        }
        var result: [String: Any] = [
            "name": name,
            "description": description,
            "athleteId": athleteId,
            "coachId": coachId,
            "days": daysArray,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let updated = lastUpdatedAt {
            result["lastUpdatedAt"] = Timestamp(date: updated)
        }
        return result
    }

    func markPlanUpdated(_ plan: WorkoutPlan) async throws {
        let now = Date()
        try await db.collection(plansCollection).document(plan.id).updateData(["lastUpdatedAt": Timestamp(date: now)])
    }
}
