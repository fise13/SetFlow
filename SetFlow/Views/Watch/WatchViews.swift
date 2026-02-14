import SwiftUI

// MARK: - Watch Workout List

struct WatchWorkoutListView: View {
    let workouts: [WorkoutDay]
    
    var body: some View {
        List(workouts) { workout in
            NavigationLink(destination: WatchWorkoutLiveView(workout: workout)) {
                VStack(alignment: .leading) {
                    Text(workout.title)
                        .font(.headline)
                    Text(String(format: String(localized: "watch_exercises_count"), workout.exercises.count))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(String(localized: "watch_nav_workouts"))
    }
}

// MARK: - Watch Live Workout

struct WatchWorkoutLiveView: View {
    let workout: WorkoutDay
    @State private var currentExerciseIndex: Int = 0
    @State private var currentSet: Int = 1
    
    var body: some View {
        VStack(spacing: 8) {
            Text(workout.title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            let exercise = workout.exercises[currentExerciseIndex]
            
            Text(exercise.name)
                .font(.headline)
                .lineLimit(2)
            
            Text(String(format: String(localized: "watch_set_format"), currentSet, exercise.sets))
                .font(.caption2)
            
            Text(String(format: String(localized: "watch_reps_kg"), exercise.reps, Int(exercise.weight)))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            NavigationLink(destination: WatchRestTimerView(restSeconds: exercise.restSeconds)) {
                Text(String(localized: "watch_done"))
                    .font(.headline)
            }
        }
        .padding()
        .navigationTitle(String(localized: "watch_nav_live"))
    }
}

// MARK: - Watch Rest Timer

struct WatchRestTimerView: View {
    let restSeconds: Int
    @State private var remaining: Int
    
    init(restSeconds: Int) {
        self.restSeconds = restSeconds
        _remaining = State(initialValue: restSeconds)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(String(localized: "watch_nav_rest"))
                .font(.headline)
            Text(String(format: String(localized: "rest_seconds_format"), remaining))
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            ProgressView(value: Double(restSeconds - remaining), total: Double(restSeconds))
                .progressViewStyle(.linear)
            
            Spacer()
            
            NavigationLink(destination: WatchWorkoutFinishView()) {
                Text(String(localized: "watch_skip"))
            }
        }
        .padding()
        .onAppear {
            // Simple animation placeholder instead of real timer
            withAnimation(.easeInOut(duration: 0.3)) { }
        }
        .navigationTitle(String(localized: "watch_nav_rest"))
    }
}

// MARK: - Watch Workout Finish

struct WatchWorkoutFinishView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            Text(String(localized: "watch_done"))
                .font(.headline)
        }
        .padding()
        .navigationTitle(String(localized: "watch_nav_finish"))
    }
}

// MARK: - Previews

struct WatchViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                WatchWorkoutListView(workouts: [MockData.todayWorkoutDay])
            }
            NavigationStack {
                WatchWorkoutLiveView(workout: MockData.todayWorkoutDay)
            }
            NavigationStack {
                WatchRestTimerView(restSeconds: 60)
            }
            NavigationStack {
                WatchWorkoutFinishView()
            }
        }
    }
}

