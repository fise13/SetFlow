//
//  HealthKitService.swift
//  SetFlow
//
//  HealthKit authorization and optional live metrics. All HealthKit access here; no UI.
//

import Foundation
import Combine
#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - Live metrics payload (for publisher)

struct HealthKitLiveMetrics {
    var heartRate: Double?
    var activeCalories: Double
    var elapsedTime: TimeInterval
}

// MARK: - HealthKit Service

final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private(set) var liveMetricsPublisher = PassthroughSubject<HealthKitLiveMetrics, Never>()

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var workoutStartDate: Date?
    #endif

    private init() {}

    func requestAuthorization() async {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKWorkoutType.workoutType()
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
        } catch {}
        #endif
    }

    /// Start observing live heart rate and active energy (e.g. when Watch writes to Health).
    /// Call when workout is known to be active; optional.
    func startLiveObserversIfNeeded() {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let heartRateType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: nil, options: .strictStartDate)
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, anchor, _ in
            self?.processHeartRateSamples(samples as? [HKQuantitySample])
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples as? [HKQuantitySample])
        }
        store.execute(query)
        anchoredQuery = query
        #endif
    }

    #if canImport(HealthKit)
    private func processHeartRateSamples(_ samples: [HKQuantitySample]?) {
        guard let sample = samples?.last else { return }
        let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        let elapsed = Date().timeIntervalSince(sample.startDate)
        liveMetricsPublisher.send(HealthKitLiveMetrics(
            heartRate: bpm,
            activeCalories: 0,
            elapsedTime: max(0, elapsed)
        ))
    }
    #endif

    // MARK: - Historical data for Progress screen

    /// Daily active energy (kcal) from Health for the last N days. Used by Progress tab.
    func fetchActiveEnergyByDay(lastDays: Int = 30) async -> [(date: Date, calories: Double)] {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let type = HKQuantityType(.activeEnergyBurned)
        let cal = Calendar.current
        let end = Date()
        guard let start = cal.date(byAdding: .day, value: -lastDays, to: end) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let anchor = cal.startOfDay(for: end)
        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, result, error in
                guard let result = result else {
                    continuation.resume(returning: [])
                    return
                }
                var data: [(date: Date, calories: Double)] = []
                result.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let value = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    if value > 0 {
                        data.append((date: statistics.startDate, calories: value))
                    }
                }
                continuation.resume(returning: data.sorted { $0.date < $1.date })
            }
            store.execute(query)
        }
        #else
        return []
        #endif
    }

    /// Total active energy (kcal) from Health over the last N days.
    func fetchTotalActiveEnergy(lastDays: Int = 30) async -> Double {
        let byDay = await fetchActiveEnergyByDay(lastDays: lastDays)
        return byDay.reduce(0) { $0 + $1.calories }
    }

    /// Number of workout sessions from Health in the last N days (HKWorkout).
    func fetchWorkoutCount(lastDays: Int = 30) async -> Int {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        let type = HKWorkoutType.workoutType()
        let cal = Calendar.current
        let end = Date()
        guard let start = cal.date(byAdding: .day, value: -lastDays, to: end) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                continuation.resume(returning: samples?.count ?? 0)
            }
            store.execute(query)
        }
        #else
        return 0
        #endif
    }
}
