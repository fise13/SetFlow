//
//  SetFlowWorkoutLiveActivity.swift
//  SetFlowWidgetExtension
//
//  Live Activity UI for workout (Dynamic Island, Lock Screen).
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.2, *)
@main
struct SetFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        SetFlowWorkoutLiveActivity()
    }
}

@available(iOS 16.2, *)
struct SetFlowWorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomView(context: context)
                }
            } compactLeading: {
                compactLeadingView(context: context)
            } compactTrailing: {
                compactTrailingView(context: context)
            } minimal: {
                minimalView(context: context)
            }
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func LockScreenLiveActivityView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(context.attributes.workoutTitle)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text("\(state.completedSetsCount)/\(state.totalSetsCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            if state.mode == "rest" {
                HStack {
                    Text(String(localized: "live_activity_rest"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: String(localized: "rest_seconds_format"), state.restRemaining))
                        .font(.title2.bold().monospacedDigit())
                }
            } else if state.mode == "completed" {
                HStack {
                    Text(String(localized: "live_activity_completed"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                HStack {
                    Text(state.currentExerciseName)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: String(localized: "set_progress_format"), state.currentSet, state.setsForCurrentExercise))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Dynamic Island Expanded

    private func expandedLeadingView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        return VStack(alignment: .leading, spacing: 4) {
            Text(context.attributes.workoutTitle)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(state.currentExerciseName)
                .font(.subheadline.bold())
                .lineLimit(1)
        }
    }

    private func expandedTrailingView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        return VStack(alignment: .trailing, spacing: 4) {
            Text("\(state.completedSetsCount)/\(state.totalSetsCount)")
                .font(.headline.monospacedDigit())
            Text(String(localized: "live_stat_sets"))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func expandedCenterView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        if state.mode == "rest" {
            Text(String(format: String(localized: "rest_seconds_format"), state.restRemaining))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
        } else if state.mode == "completed" {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                Text(String(localized: "live_activity_completed"))
                    .font(.subheadline.bold())
            }
        } else {
            Text(String(localized: "live_activity_active"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func expandedBottomView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        return Text(String(format: String(localized: "exercise_progress_format"), state.currentExerciseIndex, state.totalExercises))
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    // MARK: - Dynamic Island Compact

    private func compactLeadingView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        return HStack(spacing: 4) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.caption)
            Text("\(state.completedSetsCount)/\(state.totalSetsCount)")
                .font(.subheadline.bold().monospacedDigit())
        }
    }

    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        if state.mode == "rest" {
            Text(String(format: String(localized: "rest_seconds_format"), state.restRemaining))
                .font(.subheadline.bold().monospacedDigit())
        } else if state.mode == "completed" {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
        } else {
            Text(state.currentExerciseName)
                .font(.caption)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func minimalView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        if state.mode == "rest" {
            Text(String(format: String(localized: "rest_seconds_format"), state.restRemaining))
                .font(.caption.bold().monospacedDigit())
        } else {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.caption)
        }
    }
}
