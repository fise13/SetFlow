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
    var lastSeenAt: Date? = nil
}

struct Exercise: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var restSeconds: Int
    var notes: String?
    var tutorialURL: String? = nil
    var category: ExerciseCategory = .freeWeights
    var catalogId: String? = nil
    var isCompleted: Bool = false
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case machine
    case freeWeights
    case cable
    case bodyweight
    case cardio
    case mobility
    case other

    var icon: String {
        switch self {
        case .machine: return "rectangle.stack.fill"
        case .freeWeights: return "dumbbell"
        case .cable: return "link"
        case .bodyweight: return "figure.strengthtraining.functional"
        case .cardio: return "figure.run"
        case .mobility: return "figure.walk"
        case .other: return "figure.strengthtraining.traditional"
        }
    }

    var requiresWeight: Bool {
        switch self {
        case .cardio, .mobility: return false
        case .machine, .freeWeights, .cable, .bodyweight, .other: return true
        }
    }
}

struct ExerciseCatalogItem: Identifiable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let aliases: [String]
}

enum ExerciseCatalog {
    static let items: [ExerciseCatalogItem] = [
        // Chest / Push
        .init(id: "bench_press", name: "Жим штанги лежа", category: .freeWeights, aliases: ["bench press", "жим лежа"]),
        .init(id: "incline_bench_press", name: "Жим штанги на наклонной скамье", category: .freeWeights, aliases: ["incline bench press"]),
        .init(id: "dumbbell_bench_press", name: "Жим гантелей лежа", category: .freeWeights, aliases: ["dumbbell bench press"]),
        .init(id: "incline_dumbbell_press", name: "Жим гантелей на наклонной", category: .freeWeights, aliases: ["incline dumbbell press"]),
        .init(id: "hammer_chest_press", name: "Жим в хаммере", category: .machine, aliases: ["hammer chest press"]),
        .init(id: "machine_chest_press", name: "Жим в тренажере", category: .machine, aliases: ["machine chest press"]),
        .init(id: "pec_deck", name: "Бабочка (Pec Deck)", category: .machine, aliases: ["pec deck", "butterfly"]),
        .init(id: "cable_fly", name: "Сведение рук в кроссовере", category: .cable, aliases: ["cable fly", "crossover fly"]),
        .init(id: "push_up", name: "Отжимания", category: .bodyweight, aliases: ["push up", "push-up"]),
        .init(id: "dip", name: "Отжимания на брусьях", category: .bodyweight, aliases: ["dips", "parallel bar dip"]),

        // Shoulders
        .init(id: "overhead_press_barbell", name: "Жим штанги стоя", category: .freeWeights, aliases: ["overhead press", "military press"]),
        .init(id: "seated_dumbbell_press", name: "Жим гантелей сидя", category: .freeWeights, aliases: ["seated dumbbell shoulder press"]),
        .init(id: "machine_shoulder_press", name: "Жим плечами в тренажере", category: .machine, aliases: ["machine shoulder press"]),
        .init(id: "lateral_raise_dumbbell", name: "Разведение гантелей в стороны", category: .freeWeights, aliases: ["lateral raise"]),
        .init(id: "rear_delt_fly", name: "Разведения на заднюю дельту", category: .machine, aliases: ["rear delt fly", "reverse fly"]),
        .init(id: "face_pull", name: "Тяга к лицу (Face Pull)", category: .cable, aliases: ["face pull"]),

        // Back
        .init(id: "pull_up", name: "Подтягивания", category: .bodyweight, aliases: ["pull-up", "pull up"]),
        .init(id: "chin_up", name: "Подтягивания обратным хватом", category: .bodyweight, aliases: ["chin up", "chin-up"]),
        .init(id: "lat_pulldown", name: "Тяга верхнего блока", category: .cable, aliases: ["lat pulldown"]),
        .init(id: "seated_row_cable", name: "Тяга горизонтального блока", category: .cable, aliases: ["seated cable row"]),
        .init(id: "barbell_row", name: "Тяга штанги в наклоне", category: .freeWeights, aliases: ["barbell row"]),
        .init(id: "dumbbell_row", name: "Тяга гантели в наклоне", category: .freeWeights, aliases: ["one arm dumbbell row"]),
        .init(id: "tbar_row", name: "Тяга Т-грифа", category: .machine, aliases: ["t-bar row"]),
        .init(id: "hyperextension", name: "Гиперэкстензия", category: .bodyweight, aliases: ["back extension", "hyperextension"]),
        .init(id: "deadlift", name: "Становая тяга", category: .freeWeights, aliases: ["deadlift"]),
        .init(id: "romanian_deadlift", name: "Румынская тяга", category: .freeWeights, aliases: ["romanian deadlift", "rdl"]),

        // Legs
        .init(id: "back_squat", name: "Приседания со штангой", category: .freeWeights, aliases: ["barbell squat", "back squat"]),
        .init(id: "front_squat", name: "Фронтальные приседания", category: .freeWeights, aliases: ["front squat"]),
        .init(id: "goblet_squat", name: "Гоблет-присед", category: .freeWeights, aliases: ["goblet squat"]),
        .init(id: "smith_squat", name: "Приседания в Смите", category: .machine, aliases: ["smith machine squat"]),
        .init(id: "leg_press", name: "Жим ногами", category: .machine, aliases: ["leg press"]),
        .init(id: "hack_squat", name: "Гакк-присед", category: .machine, aliases: ["hack squat"]),
        .init(id: "lunge", name: "Выпады", category: .freeWeights, aliases: ["lunges", "lunge"]),
        .init(id: "bulgarian_split_squat", name: "Болгарские выпады", category: .freeWeights, aliases: ["bulgarian split squat"]),
        .init(id: "leg_extension", name: "Разгибание ног в тренажере", category: .machine, aliases: ["leg extension"]),
        .init(id: "leg_curl", name: "Сгибание ног в тренажере", category: .machine, aliases: ["leg curl"]),
        .init(id: "hip_thrust", name: "Ягодичный мост со штангой", category: .freeWeights, aliases: ["barbell hip thrust"]),
        .init(id: "glute_bridge_machine", name: "Ягодичный мост в тренажере", category: .machine, aliases: ["hip thrust machine"]),
        .init(id: "calf_raise", name: "Подъемы на носки", category: .machine, aliases: ["calf raises"]),
        .init(id: "seated_calf_raise", name: "Подъемы на носки сидя", category: .machine, aliases: ["seated calf raise"]),

        // Arms
        .init(id: "barbell_curl", name: "Сгибание рук со штангой", category: .freeWeights, aliases: ["barbell curl"]),
        .init(id: "dumbbell_curl", name: "Сгибание рук с гантелями", category: .freeWeights, aliases: ["dumbbell curl"]),
        .init(id: "hammer_curl", name: "Молотки с гантелями", category: .freeWeights, aliases: ["hammer curl"]),
        .init(id: "preacher_curl", name: "Сгибание на скамье Скотта", category: .machine, aliases: ["preacher curl"]),
        .init(id: "cable_curl", name: "Сгибание рук на блоке", category: .cable, aliases: ["cable curl"]),
        .init(id: "close_grip_bench", name: "Жим узким хватом", category: .freeWeights, aliases: ["close-grip bench press"]),
        .init(id: "triceps_pushdown", name: "Разгибание рук на верхнем блоке", category: .cable, aliases: ["triceps pushdown"]),
        .init(id: "overhead_triceps_extension", name: "Разгибание рук из-за головы", category: .freeWeights, aliases: ["overhead triceps extension"]),
        .init(id: "triceps_dip_machine", name: "Отжимания в тренажере на трицепс", category: .machine, aliases: ["assisted dip machine"]),

        // Core / Mobility
        .init(id: "plank", name: "Планка", category: .bodyweight, aliases: ["plank"]),
        .init(id: "side_plank", name: "Боковая планка", category: .bodyweight, aliases: ["side plank"]),
        .init(id: "crunch", name: "Скручивания", category: .bodyweight, aliases: ["crunches", "crunch"]),
        .init(id: "hanging_leg_raise", name: "Подъем ног в висе", category: .bodyweight, aliases: ["hanging leg raise"]),
        .init(id: "cable_crunch", name: "Скручивания на блоке", category: .cable, aliases: ["cable crunch"]),
        .init(id: "russian_twist", name: "Русские скручивания", category: .bodyweight, aliases: ["russian twist"]),
        .init(id: "dead_bug", name: "Dead Bug", category: .mobility, aliases: ["dead bug"]),
        .init(id: "bird_dog", name: "Bird Dog", category: .mobility, aliases: ["bird dog"]),
        .init(id: "cat_cow", name: "Кошка-корова", category: .mobility, aliases: ["cat cow"]),

        // Cardio
        .init(id: "treadmill_run", name: "Беговая дорожка", category: .cardio, aliases: ["treadmill", "running treadmill"]),
        .init(id: "elliptical", name: "Эллипс", category: .cardio, aliases: ["elliptical trainer"]),
        .init(id: "rowing_machine", name: "Гребной тренажер", category: .cardio, aliases: ["rowing machine", "erg"]),
        .init(id: "stationary_bike", name: "Велотренажер", category: .cardio, aliases: ["stationary bike", "exercise bike"]),
        .init(id: "air_bike", name: "Air Bike", category: .cardio, aliases: ["assault bike", "air bike"]),
        .init(id: "stairmaster", name: "Степпер (Stairmaster)", category: .cardio, aliases: ["stairmaster", "stepmill"]),
        .init(id: "jump_rope", name: "Скакалка", category: .cardio, aliases: ["jump rope", "skipping rope"]),
        .init(id: "walking", name: "Ходьба", category: .cardio, aliases: ["walking"]),
        .init(id: "running", name: "Бег", category: .cardio, aliases: ["running"])
    ]

    static func suggestions(for query: String, limit: Int = 10) -> [ExerciseCatalogItem] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }
        let startsWithMatches = items.filter { item in
            normalize(item.name).hasPrefix(normalizedQuery)
                || item.aliases.contains(where: { normalize($0).hasPrefix(normalizedQuery) })
        }
        let containsMatches = items.filter { item in
            normalize(item.name).contains(normalizedQuery)
                || item.aliases.contains(where: { normalize($0).contains(normalizedQuery) })
        }
        var merged: [ExerciseCatalogItem] = []
        for item in startsWithMatches + containsMatches where !merged.contains(item) {
            merged.append(item)
        }
        return Array(merged.prefix(limit))
    }

    static func exactMatch(for text: String) -> ExerciseCatalogItem? {
        let target = normalize(text)
        guard !target.isEmpty else { return nil }
        return items.first { item in
            normalize(item.name) == target || item.aliases.contains(where: { normalize($0) == target })
        }
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}

extension Exercise {
    var iconName: String {
        category.icon
    }

    var requiresWeight: Bool {
        category.requiresWeight
    }
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
    var lastUpdatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, athleteId, coachId, days, lastUpdatedAt
    }

    init(id: String, name: String, description: String, athleteId: String, coachId: String, athlete: User?, days: [WorkoutDay], lastUpdatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.athleteId = athleteId
        self.coachId = coachId
        self.athlete = athlete
        self.days = days
        self.lastUpdatedAt = lastUpdatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decode(String.self, forKey: .description)
        athleteId = try c.decode(String.self, forKey: .athleteId)
        coachId = try c.decode(String.self, forKey: .coachId)
        days = try c.decode([WorkoutDay].self, forKey: .days)
        lastUpdatedAt = try? c.decodeIfPresent(Date.self, forKey: .lastUpdatedAt)
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
        try? c.encodeIfPresent(lastUpdatedAt, forKey: .lastUpdatedAt)
    }
}

struct WorkoutTemplate: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var workoutTitle: String
    var focus: String
    var exercises: [Exercise]
    var createdAt: Date
}

struct WorkoutLog: Identifiable, Hashable, Codable {
    let id: String
    var athleteId: String
    var workoutTitle: String
    /// Source workout day id to disambiguate updated/duplicated workouts
    var workoutDayId: String? = nil
    var date: Date
    var durationMinutes: Int
    var totalSets: Int
    var totalVolume: Double
    var rating: Int // 1-5
    var exerciseFeedbacks: [ExerciseFeedback] = []
    var status: WorkoutSessionStatus = .completed
}

struct ExerciseFeedback: Identifiable, Hashable, Codable {
    let id: String
    var exerciseName: String
    /// 1...5 perceived difficulty
    var difficulty: Int
    /// Optional athlete note for coach ("next time 50kg", etc.)
    var note: String?
}

enum WorkoutSessionStatus: String, Codable {
    case completed
    case missed
    case makeup
}

