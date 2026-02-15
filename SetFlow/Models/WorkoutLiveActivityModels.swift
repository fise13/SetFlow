//
//  WorkoutLiveActivityModels.swift
//  SetFlow
//
//  Shared with Widget Extension for Live Activity / Dynamic Island.
//

import Foundation
import ActivityKit

/// Attributes for workout Live Activity. Static data.
public struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Current exercise display name
        public var currentExerciseName: String
        /// 1-based exercise index
        public var currentExerciseIndex: Int
        /// Total exercises
        public var totalExercises: Int
        /// Current set (1-based) within current exercise
        public var currentSet: Int
        /// Total sets for current exercise
        public var setsForCurrentExercise: Int
        /// Total completed sets so far
        public var completedSetsCount: Int
        /// Total sets in workout
        public var totalSetsCount: Int
        /// Rest seconds remaining (0 = not resting)
        public var restRemaining: Int
        /// Total rest seconds for current rest segment
        public var restTotalSeconds: Int
        /// Rest countdown end date for precise lock screen timer rendering
        public var restEndDate: Date?
        /// "active" | "rest" | "completed"
        public var mode: String
        /// True when current exercise uses weight
        public var requiresWeight: Bool
        /// Target reps for current set context
        public var repsForCurrentExercise: Int
        /// Target weight for current set context
        public var weightForCurrentExercise: Double
        /// Optional next exercise name (shown while resting)
        public var nextExerciseName: String?
        /// Total volume lifted so far (kg)
        public var totalVolume: Double
    }

    /// Workout title (static)
    public var workoutTitle: String
    /// Total sets in workout (static)
    public var totalSets: Int
}
