//
//  WorkoutManager.swift
//  SetFlow
//
//  Single source of truth for real-time Apple Watch workout metrics.
//  All displayed data (HR, calories, duration, state) comes from the Watch app via WatchConnectivity.
//  No UI; views bind to WorkoutManager only.
//

import Foundation
import Combine

// MARK: - Live Workout Metrics (from Apple Watch)

struct LiveWorkoutMetricsUpdate {
    var heartRate: Double?
    var calories: Double?
    var elapsedTime: TimeInterval?
    var workoutState: LiveWorkoutState?
}

// MARK: - Live Workout State

enum LiveWorkoutState: String, Equatable {
    case idle
    case active
    case paused
    case finished
}

// MARK: - Workout Manager

final class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()

    /// All values are driven by Apple Watch only (WatchConnectivity).
    @Published private(set) var currentHeartRate: Double?
    @Published private(set) var activeCalories: Double = 0
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var workoutState: LiveWorkoutState = .idle

    private let healthKitService: HealthKitService
    private let watchConnectivityManager: WatchConnectivityManager

    init(
        healthKitService: HealthKitService = HealthKitService.shared,
        watchConnectivityManager: WatchConnectivityManager = .shared
    ) {
        self.healthKitService = healthKitService
        self.watchConnectivityManager = watchConnectivityManager
        setupWatchReception()
    }

    /// Request HealthKit authorization (e.g. for future sync); does not affect bar data source.
    func requestAuthorization() async {
        await healthKitService.requestAuthorization()
    }

    private func setupWatchReception() {
        watchConnectivityManager.onLiveWorkoutUpdate = { [weak self] payload in
            DispatchQueue.main.async {
                self?.apply(payload)
            }
        }
    }

    private func apply(_ payload: [String: Any]) {
        let update = LiveWorkoutMetricsUpdate(
            heartRate: (payload["heartRate"] as? NSNumber).map { $0.doubleValue },
            calories: (payload["calories"] as? NSNumber).map { $0.doubleValue },
            elapsedTime: (payload["elapsedTime"] as? NSNumber).map { $0.doubleValue },
            workoutState: (payload["workoutState"] as? String).flatMap { LiveWorkoutState(rawValue: $0) }
        )
        apply(update)
    }

    private func apply(_ update: LiveWorkoutMetricsUpdate) {
        if let hr = update.heartRate { currentHeartRate = hr }
        if let cal = update.calories { activeCalories = cal }
        if let elapsed = update.elapsedTime { elapsedTime = elapsed }
        if let state = update.workoutState { workoutState = state }
    }

    /// Reset state when user explicitly ends or dismisses workout (optional).
    func resetToIdle() {
        currentHeartRate = nil
        activeCalories = 0
        elapsedTime = 0
        workoutState = .idle
    }
}
