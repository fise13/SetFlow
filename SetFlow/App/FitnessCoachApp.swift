import SwiftUI
import Combine
import FirebaseAuth

final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var needsProfileSetup: Bool = false
    /// True while loading profile from Firestore after sign-in. Prevents showing Coach/Athlete until we know the role.
    @Published var isLoadingProfile: Bool = false
    @Published var selectedAthlete: User?
    @Published var selectedWorkoutPlan: WorkoutPlan?
    @Published var selectedWorkoutDay: WorkoutDay?
    @Published var activeWorkoutLog: WorkoutLog?

    let authService = AuthService.shared
    let userService = UserService()
    let planService = WorkoutPlanService()
    let logService = WorkoutLogService()

    private var cancellables = Set<AnyCancellable>()

    init() {
        authService.$currentFirebaseUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] firebaseUser in
                Task { @MainActor in
                    await self?.syncUserFromAuth(firebaseUser)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func syncUserFromAuth(_ firebaseUser: FirebaseAuth.User?) async {
        guard let uid = firebaseUser?.uid else {
            currentUser = nil
            needsProfileSetup = false
            isLoadingProfile = false
            return
        }
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        do {
            let user = try await userService.getUser(id: uid)
            currentUser = user
            // Show role selection only when there's no profile (first-time registration).
            needsProfileSetup = (user == nil)
        } catch {
            currentUser = nil
            needsProfileSetup = true
        }
    }

    @MainActor
    func refetchCurrentUser() async {
        guard let uid = authService.uid else { return }
        do {
            currentUser = try await userService.getUser(id: uid)
            needsProfileSetup = (currentUser == nil)
        } catch {
            currentUser = nil
            needsProfileSetup = true
        }
    }

    func signOut() {
        try? authService.signOut()
        currentUser = nil
        needsProfileSetup = false
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.isLoadingProfile {
                loadingView
            } else if appState.needsProfileSetup {
                RoleSelectionView(appState: appState)
            } else if let user = appState.currentUser {
                switch user.role {
                case .athlete:
                    AthleteTabRootView(user: user, appState: appState)
                case .coach:
                    CoachTabRootView(coach: user, appState: appState)
                }
            } else {
                WelcomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading…")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

struct PopToHomeKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}
extension EnvironmentValues {
    var popToHome: (() -> Void)? {
        get { self[PopToHomeKey.self] }
        set { self[PopToHomeKey.self] = newValue }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppState())
    }
}
