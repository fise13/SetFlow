import Foundation

enum UserRole: String, Codable, CaseIterable {
    case coach
    case athlete
}

struct User: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var role: UserRole
    var coachId: String?
}

struct Exercise: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var restSeconds: Int
    var notes: String?
    var isCompleted: Bool = false
}

struct WorkoutDay: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var focus: String
    var date: Date
    var exercises: [Exercise]
}

struct WorkoutPlan: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var description: String
    var athleteId: String
    var coachId: String
    var athlete: User?
    var days: [WorkoutDay]

    enum CodingKeys: String, CodingKey {
        case id, name, description, athleteId, coachId, days
    }

    init(id: String, name: String, description: String, athleteId: String, coachId: String, athlete: User?, days: [WorkoutDay]) {
        self.id = id
        self.name = name
        self.description = description
        self.athleteId = athleteId
        self.coachId = coachId
        self.athlete = athlete
        self.days = days
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decode(String.self, forKey: .description)
        athleteId = try c.decode(String.self, forKey: .athleteId)
        coachId = try c.decode(String.self, forKey: .coachId)
        days = try c.decode([WorkoutDay].self, forKey: .days)
        athlete = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encode(athleteId, forKey: .athleteId)
        try c.encode(coachId, forKey: .coachId)
        try c.encode(days, forKey: .days)
    }
}

struct WorkoutLog: Identifiable, Hashable, Codable {
    let id: String
    var athleteId: String
    var workoutTitle: String
    var date: Date
    var durationMinutes: Int
    var totalSets: Int
    var totalVolume: Double
    var rating: Int // 1-5
}

