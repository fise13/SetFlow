import Foundation

struct MockData {
    static let sampleCoach = User(
        id: "coach-mock-id",
        name: "Alex Coach",
        role: .coach,
        coachId: nil
    )
    
    static let sampleAthlete = User(
        id: "athlete-mock-id",
        name: "Jamie Athlete",
        role: .athlete,
        coachId: "coach-mock-id"
    )
    
    static let sampleExercises: [Exercise] = [
        Exercise(id: UUID().uuidString, name: "Barbell Squat", sets: 4, reps: 6, weight: 80, restSeconds: 120, notes: "Focus on depth"),
        Exercise(id: UUID().uuidString, name: "Bench Press", sets: 4, reps: 8, weight: 60, restSeconds: 90, notes: nil),
        Exercise(id: UUID().uuidString, name: "Deadlift", sets: 3, reps: 5, weight: 100, restSeconds: 150, notes: "Keep tight core"),
        Exercise(id: UUID().uuidString, name: "Pull Ups", sets: 3, reps: 10, weight: 0, restSeconds: 90, notes: nil)
    ]
    
    static var todayWorkoutDay: WorkoutDay {
        WorkoutDay(
            id: UUID().uuidString,
            title: "Lower Body Strength",
            focus: "Strength",
            date: Date(),
            exercises: sampleExercises
        )
    }
    
    static var samplePlan: WorkoutPlan {
        WorkoutPlan(
            id: UUID().uuidString,
            name: "8-Week Strength Block",
            description: "Alternating upper / lower body days with progressive overload.",
            athleteId: sampleAthlete.id,
            coachId: sampleCoach.id,
            athlete: sampleAthlete,
            days: [
                todayWorkoutDay,
                WorkoutDay(
                    id: UUID().uuidString,
                    title: "Upper Body Push",
                    focus: "Hypertrophy",
                    date: Date().addingTimeInterval(60 * 60 * 24),
                    exercises: sampleExercises
                )
            ]
        )
    }
    
    static var samplePlans: [WorkoutPlan] {
        [samplePlan]
    }
    
    static var sampleLogs: [WorkoutLog] {
        (0..<7).map { offset in
            WorkoutLog(
                id: UUID().uuidString,
                athleteId: sampleAthlete.id,
                workoutTitle: "Workout \(offset + 1)",
                date: Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date(),
                durationMinutes: 45 + offset * 2,
                totalSets: 18 + offset,
                totalVolume: 12000 + Double(offset) * 500,
                rating: Int.random(in: 3...5)
            )
        }
    }
    
    static var sampleAthletes: [User] {
        [
            sampleAthlete,
            User(id: UUID().uuidString, name: "Taylor Runner", role: .athlete, coachId: "coach-mock-id"),
            User(id: UUID().uuidString, name: "Jordan Lifter", role: .athlete, coachId: "coach-mock-id")
        ]
    }
}

