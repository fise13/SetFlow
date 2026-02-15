//
//  WorkoutLiveActivityService.swift
//  SetFlow
//
//  Manages Live Activity for workout session (Dynamic Island, Lock Screen).
//

import Foundation
import ActivityKit

@available(iOS 16.2, *)
enum WorkoutLiveActivityService {
    private static let throttleInterval: TimeInterval = 1.0
    private static var lastRestUpdate: Date = .distantPast

    /// Start Live Activity when workout begins.
    static func start(
        workoutTitle: String,
        totalSets: Int,
        currentExerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSet: Int,
        setsForCurrentExercise: Int,
        completedSetsCount: Int,
        totalVolume: Double
    ) {
        Task { @MainActor in
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            await endAllActivities()
            let attrs = WorkoutActivityAttributes(
                workoutTitle: workoutTitle,
                totalSets: totalSets
            )
            let state = WorkoutActivityAttributes.ContentState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSets,
                restRemaining: 0,
                mode: "active",
                totalVolume: totalVolume
            )
            try? Activity<WorkoutActivityAttributes>.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        }
    }

    /// Update after set completed (before or during rest).
    static func updateForSetDone(
        currentExerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSet: Int,
        setsForCurrentExercise: Int,
        completedSetsCount: Int,
        totalSetsCount: Int,
        restRemaining: Int,
        totalVolume: Double
    ) {
        Task { @MainActor in
            guard let activity = Activity<WorkoutActivityAttributes>.activities.first else { return }
            let state = WorkoutActivityAttributes.ContentState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: restRemaining,
                mode: restRemaining > 0 ? "rest" : "active",
                totalVolume: totalVolume
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    /// Update when moving to next exercise.
    static func updateForExerciseChange(
        currentExerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSet: Int,
        setsForCurrentExercise: Int,
        completedSetsCount: Int,
        totalSetsCount: Int,
        restRemaining: Int,
        totalVolume: Double
    ) {
        Task { @MainActor in
            guard let activity = Activity<WorkoutActivityAttributes>.activities.first else { return }
            let state = WorkoutActivityAttributes.ContentState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: restRemaining,
                mode: restRemaining > 0 ? "rest" : "active",
                totalVolume: totalVolume
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    /// Update rest countdown. Throttled to once per second.
    static func updateRest(
        currentExerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSet: Int,
        setsForCurrentExercise: Int,
        completedSetsCount: Int,
        totalSetsCount: Int,
        restRemaining: Int,
        totalVolume: Double
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastRestUpdate) >= throttleInterval else { return }
        lastRestUpdate = now
        Task { @MainActor in
            guard let activity = Activity<WorkoutActivityAttributes>.activities.first else { return }
            let state = WorkoutActivityAttributes.ContentState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: restRemaining,
                mode: "rest",
                totalVolume: totalVolume
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    /// Mark workout complete.
    static func complete(
        completedSetsCount: Int,
        totalSetsCount: Int,
        totalVolume: Double
    ) {
        Task { @MainActor in
            guard let activity = Activity<WorkoutActivityAttributes>.activities.first else { return }
            let state = WorkoutActivityAttributes.ContentState(
                currentExerciseName: "",
                currentExerciseIndex: 1,
                totalExercises: 1,
                currentSet: 0,
                setsForCurrentExercise: 0,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: 0,
                mode: "completed",
                totalVolume: totalVolume
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
            await activity.end(nil, dismissalPolicy: .after(Date().addingTimeInterval(5)))
        }
    }

    /// End activity if any is running (e.g. user left screen).
    static func endIfNeeded() {
        Task { @MainActor in
            await endAllActivities()
        }
    }

    @MainActor
    private static func endAllActivities() async {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

}
