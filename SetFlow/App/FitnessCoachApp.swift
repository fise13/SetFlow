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
    @Published var showSignUpSheet: Bool = false
    var pendingDisplayName: String?

    let authService = AuthService.shared
    let userService = UserService()
    let planService = WorkoutPlanService()
    let logService = WorkoutLogService()
    let inviteCodeService = InviteCodeService()
    let coachRequestService = CoachRequestService()

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
            if let user {
                try? await userService.updateLastSeen(userId: uid)
                var updated = user
                updated.lastSeenAt = Date()
                currentUser = updated
            } else {
                currentUser = nil
            }
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
            let fetched = try await userService.getUser(id: uid)
            if fetched != nil {
                try? await userService.updateLastSeen(userId: uid)
            }
            currentUser = fetched
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
        pendingDisplayName = nil
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        rootContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fullScreenCover(isPresented: Binding(
                get: { appState.showSignUpSheet },
                set: { appState.showSignUpSheet = $0 }
            )) {
                SignUpView(appState: appState)
            }
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
            if appState.isLoadingProfile {
                loadingView
            } else if appState.needsProfileSetup {
                NavigationStack {
                    RoleSelectionView(appState: appState)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let user = appState.currentUser {
                switch user.role {
                case .athlete:
                    AthleteTabRootView(user: user, appState: appState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .coach:
                    CoachTabRootView(coach: user, appState: appState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                NavigationStack {
                    WelcomeView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .id(appState.currentUser?.id ?? (appState.needsProfileSetup ? "setup" : "guest"))
    }

    private var loadingView: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("loading")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
