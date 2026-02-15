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
            .keylineTint(keylineColor(for: context.state.mode))
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
                    Text(restProgressPercentText(state: state))
                        .font(.subheadline.bold().monospacedDigit())
                }
                ProgressView(value: restProgressValue(state: state), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.orange)
                if let next = state.nextExerciseName, !next.isEmpty {
                    Text("\(String(localized: "live_activity_next_exercise")): \(next)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
                HStack(spacing: 8) {
                    Text(exercisePrescription(state: state))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if state.totalVolume > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(volumeFormatted(state.totalVolume))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
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
            Text(state.mode == "rest" ? String(localized: "live_activity_rest") : state.currentExerciseName)
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
            if state.mode != "completed" && state.totalVolume > 0 {
                Text(volumeFormatted(state.totalVolume))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func expandedCenterView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        if state.mode == "rest" {
            VStack(spacing: 6) {
                Text(restProgressPercentText(state: state))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                ProgressView(value: restProgressValue(state: state), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.orange)
                    .frame(maxWidth: 140)
            }
        } else if state.mode == "completed" {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                Text(String(localized: "live_activity_completed"))
                    .font(.subheadline.bold())
            }
        } else {
            VStack(spacing: 2) {
                Text(String(format: String(localized: "set_progress_format"), state.currentSet, state.setsForCurrentExercise))
                    .font(.subheadline.bold().monospacedDigit())
                Text(exercisePrescription(state: state))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func expandedBottomView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        return VStack(spacing: 2) {
            Text(String(format: String(localized: "exercise_progress_format"), state.currentExerciseIndex, state.totalExercises))
                .font(.caption2)
                .foregroundColor(.secondary)
            if state.mode == "rest", let next = state.nextExerciseName, !next.isEmpty {
                Text("\(String(localized: "live_activity_next_exercise")): \(next)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text(exercisePrescription(state: state))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Dynamic Island Compact

    private func compactLeadingView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        return HStack(spacing: 4) {
            Image(systemName: state.mode == "rest" ? "pause.circle.fill" : "figure.strengthtraining.traditional")
                .font(.caption)
            Text("\(state.completedSetsCount)/\(state.totalSetsCount)")
                .font(.subheadline.bold().monospacedDigit())
        }
    }

    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        if state.mode == "rest" {
            restProgressPill(state: state)
        } else if state.mode == "completed" {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
        } else {
            Text(String(format: String(localized: "set_progress_format"), state.currentSet, state.setsForCurrentExercise))
                .font(.caption.bold().monospacedDigit())
        }
    }

    @ViewBuilder
    private func minimalView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        if state.mode == "rest" {
            Circle()
                .trim(from: 0, to: CGFloat(restProgressValue(state: state)))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(-90))
        } else if state.mode == "completed" {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
        } else {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.caption)
        }
    }

    private func restProgressPill(state: WorkoutActivityAttributes.ContentState) -> some View {
        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 28, height: 10)
            Capsule(style: .continuous)
                .fill(Color.orange)
                .frame(width: 28 * CGFloat(restProgressValue(state: state)), height: 10)
        }
    }

    /// 0 = rest just started, 1 = rest over (bar fills as time passes).
    private func restProgressValue(state: WorkoutActivityAttributes.ContentState) -> Double {
        let total = max(1, state.restTotalSeconds)
        let remaining: Int
        if let end = state.restEndDate, end > Date() {
            remaining = Int(ceil(end.timeIntervalSinceNow))
        } else {
            remaining = max(0, state.restRemaining)
        }
        let elapsed = total - remaining
        return min(1.0, max(0.0, Double(elapsed) / Double(total)))
    }

    private func restProgressPercentText(state: WorkoutActivityAttributes.ContentState) -> String {
        let percent = Int(restProgressValue(state: state) * 100)
        return "\(percent)%"
    }

    private func volumeFormatted(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1ft", kg / 1000)
        }
        return "\(Int(kg)) kg"
    }

    private func exercisePrescription(state: WorkoutActivityAttributes.ContentState) -> String {
        if state.requiresWeight {
            return "\(state.repsForCurrentExercise)x • \(Int(state.weightForCurrentExercise)) kg"
        }
        return "\(state.repsForCurrentExercise)x"
    }

    private func keylineColor(for mode: String) -> Color {
        switch mode {
        case "rest":
            return .orange
        case "completed":
            return .green
        default:
            return .blue
        }
    }
}
