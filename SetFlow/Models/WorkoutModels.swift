import Foundation

enum UserRole: String, Codable, CaseIterable {
    case coach
    case athlete
}

struct User: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var role: UserRole
}

struct Exercise: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var restSeconds: Int
    var notes: String?
    var isCompleted: Bool = false
}

struct WorkoutDay: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var focus: String
    var date: Date
    var exercises: [Exercise]
}

struct WorkoutPlan: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var description: String
    var athlete: User
    var days: [WorkoutDay]
}

struct WorkoutLog: Identifiable, Hashable, Codable {
    let id: UUID
    var workoutTitle: String
    var date: Date
    var durationMinutes: Int
    var totalSets: Int
    var totalVolume: Double
    var rating: Int // 1-5
}

