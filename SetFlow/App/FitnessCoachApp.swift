import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var selectedAthlete: User?
    @Published var selectedWorkoutPlan: WorkoutPlan?
    @Published var selectedWorkoutDay: WorkoutDay?
    @Published var activeWorkoutLog: WorkoutLog?
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            if let user = appState.currentUser {
                switch user.role {
                case .athlete:
                    AthleteTabRootView(user: user, plans: MockData.samplePlans)
                case .coach:
                    CoachTabRootView(coach: user, athletes: MockData.sampleAthletes)
                }
            } else {
                WelcomeView()
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppState())
    }
}

