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
    private static var activeActivityId: String?

    /// Start Live Activity when workout begins.
    static func start(
        workoutTitle: String,
        totalSets: Int,
        currentExerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSet: Int,
        setsForCurrentExercise: Int,
        repsForCurrentExercise: Int,
        weightForCurrentExercise: Double,
        requiresWeight: Bool,
        nextExerciseName: String?,
        completedSetsCount: Int,
        restTotalSeconds: Int,
        totalVolume: Double
    ) {
        Task { @MainActor in
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            await endAllActivities()
            let attrs = WorkoutActivityAttributes(
                workoutTitle: workoutTitle,
                totalSets: totalSets
            )
            let state = makeState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                repsForCurrentExercise: repsForCurrentExercise,
                weightForCurrentExercise: weightForCurrentExercise,
                requiresWeight: requiresWeight,
                nextExerciseName: nextExerciseName,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSets,
                restRemaining: 0,
                restTotalSeconds: max(0, restTotalSeconds),
                mode: "active",
                totalVolume: totalVolume
            )
            let created = try? Activity<WorkoutActivityAttributes>.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            activeActivityId = created?.id
            lastRestUpdate = .distantPast
        }
    }

    /// Update after set completed (before or during rest).
    static func updateForSetDone(
        currentExerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSet: Int,
        setsForCurrentExercise: Int,
        repsForCurrentExercise: Int,
        weightForCurrentExercise: Double,
        requiresWeight: Bool,
        nextExerciseName: String?,
        completedSetsCount: Int,
        totalSetsCount: Int,
        restRemaining: Int,
        restTotalSeconds: Int,
        totalVolume: Double
    ) {
        Task { @MainActor in
            guard let activity = activeActivity() else { return }
            let state = makeState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                repsForCurrentExercise: repsForCurrentExercise,
                weightForCurrentExercise: weightForCurrentExercise,
                requiresWeight: requiresWeight,
                nextExerciseName: nextExerciseName,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: restRemaining,
                restTotalSeconds: restTotalSeconds,
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
        repsForCurrentExercise: Int,
        weightForCurrentExercise: Double,
        requiresWeight: Bool,
        nextExerciseName: String?,
        completedSetsCount: Int,
        totalSetsCount: Int,
        restRemaining: Int,
        restTotalSeconds: Int,
        totalVolume: Double
    ) {
        Task { @MainActor in
            guard let activity = activeActivity() else { return }
            let state = makeState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                repsForCurrentExercise: repsForCurrentExercise,
                weightForCurrentExercise: weightForCurrentExercise,
                requiresWeight: requiresWeight,
                nextExerciseName: nextExerciseName,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: restRemaining,
                restTotalSeconds: restTotalSeconds,
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
        repsForCurrentExercise: Int,
        weightForCurrentExercise: Double,
        requiresWeight: Bool,
        nextExerciseName: String?,
        completedSetsCount: Int,
        totalSetsCount: Int,
        restRemaining: Int,
        restTotalSeconds: Int,
        totalVolume: Double
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastRestUpdate) >= throttleInterval else { return }
        lastRestUpdate = now
        Task { @MainActor in
            guard let activity = activeActivity() else { return }
            let state = makeState(
                currentExerciseName: currentExerciseName,
                currentExerciseIndex: currentExerciseIndex,
                totalExercises: totalExercises,
                currentSet: currentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                repsForCurrentExercise: repsForCurrentExercise,
                weightForCurrentExercise: weightForCurrentExercise,
                requiresWeight: requiresWeight,
                nextExerciseName: nextExerciseName,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: restRemaining,
                restTotalSeconds: restTotalSeconds,
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
            guard let activity = activeActivity() else { return }
            let state = WorkoutActivityAttributes.ContentState(
                currentExerciseName: "",
                currentExerciseIndex: 1,
                totalExercises: 1,
                currentSet: 0,
                setsForCurrentExercise: 0,
                completedSetsCount: completedSetsCount,
                totalSetsCount: totalSetsCount,
                restRemaining: 0,
                restTotalSeconds: 0,
                restEndDate: nil,
                mode: "completed",
                requiresWeight: false,
                repsForCurrentExercise: 0,
                weightForCurrentExercise: 0,
                nextExerciseName: nil,
                totalVolume: totalVolume
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
            await activity.end(nil, dismissalPolicy: .immediate)
            activeActivityId = nil
            lastRestUpdate = .distantPast
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
        activeActivityId = nil
        lastRestUpdate = .distantPast
    }

    @MainActor
    private static func activeActivity() -> Activity<WorkoutActivityAttributes>? {
        if let id = activeActivityId,
           let existing = Activity<WorkoutActivityAttributes>.activities.first(where: { $0.id == id }) {
            return existing
        }
        let fallback = Activity<WorkoutActivityAttributes>.activities.first
        activeActivityId = fallback?.id
        return fallback
    }

    private static func makeState(
        currentExerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSet: Int,
        setsForCurrentExercise: Int,
        repsForCurrentExercise: Int,
        weightForCurrentExercise: Double,
        requiresWeight: Bool,
        nextExerciseName: String?,
        completedSetsCount: Int,
        totalSetsCount: Int,
        restRemaining: Int,
        restTotalSeconds: Int,
        mode: String,
        totalVolume: Double
    ) -> WorkoutActivityAttributes.ContentState {
        let clampedRest = max(0, restRemaining)
        let clampedRestTotal = max(0, restTotalSeconds)
        return WorkoutActivityAttributes.ContentState(
            currentExerciseName: currentExerciseName,
            currentExerciseIndex: currentExerciseIndex,
            totalExercises: totalExercises,
            currentSet: currentSet,
            setsForCurrentExercise: setsForCurrentExercise,
            completedSetsCount: completedSetsCount,
            totalSetsCount: totalSetsCount,
            restRemaining: clampedRest,
            restTotalSeconds: clampedRestTotal,
            restEndDate: clampedRest > 0 ? Date().addingTimeInterval(TimeInterval(clampedRest)) : nil,
            mode: mode,
            requiresWeight: requiresWeight,
            repsForCurrentExercise: repsForCurrentExercise,
            weightForCurrentExercise: weightForCurrentExercise,
            nextExerciseName: nextExerciseName,
            totalVolume: totalVolume
        )
    }

}
