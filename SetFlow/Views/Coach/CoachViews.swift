import SwiftUI
import Combine

// MARK: - Coach Tabs

enum CoachTab: String, CaseIterable {
    case athletes
    case programs
    case updates
    case profile
    
    var title: String {
        switch self {
        case .athletes: return "Athletes"
        case .programs: return "Programs"
        case .updates: return "Updates"
        case .profile: return "Profile"
        }
    }
    
    var systemImage: String {
        switch self {
        case .athletes: return "person.3.fill"
        case .programs: return "list.bullet.rectangle"
        case .updates: return "paperplane.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

struct CoachTabRootView: View {
    let coach: User
    @ObservedObject var appState: AppState

    @StateObject private var dashboardVM: CoachDashboardViewModel
    @State private var selectedTab: CoachTab = .athletes

    init(coach: User, appState: AppState) {
        self.coach = coach
        self.appState = appState
        _dashboardVM = StateObject(wrappedValue: CoachDashboardViewModel(coach: coach, userService: appState.userService))
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                CoachTabBar(selectedTab: $selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { dashboardVM.load() }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .athletes:
            NavigationStack { CoachDashboardView(viewModel: dashboardVM) }
        case .programs:
            NavigationStack { PlanBuilderView(appState: appState) }
        case .updates:
            NavigationStack { CoachUpdatesView() }
        case .profile:
            NavigationStack { CoachProfileView(coach: coach) }
        }
    }
}

struct CoachTabBar: View {
    @Binding var selectedTab: CoachTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CoachTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                        selectedTab = tab
                    }
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(selectedTab == tab ? AppColors.accent : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                            .fill(selectedTab == tab ? AppColors.accent.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.backgroundElevated)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .top
        )
    }
}

// MARK: - Coach Dashboard

final class CoachDashboardViewModel: ObservableObject {
    let coach: User
    private let userService: UserService

    @Published var athletes: [User] = []

    init(coach: User, userService: UserService) {
        self.coach = coach
        self.userService = userService
    }

    @MainActor
    func load() {
        Task {
            do {
                athletes = try await userService.athletesForCoach(coachId: coach.id)
            } catch {
                athletes = []
            }
        }
    }
}

struct CoachDashboardView: View {
    @ObservedObject var viewModel: CoachDashboardViewModel
    @State private var searchText: String = ""
    @State private var filterActiveOnly: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.lg) {
                SectionHeader(
                    title: "Athletes",
                    subtitle: "Manage everyone in one place",
                    actionTitle: "Add"
                ) { }
                .frame(maxWidth: .infinity, alignment: .leading)

                GlassCard(cornerRadius: AppTheme.Corners.md) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary)
                        TextField("Search athletes", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Text("Active")
                        .font(AppTypography.footnote)
                        .foregroundColor(filterActiveOnly ? AppColors.textPrimary : AppColors.textSecondary)
                    Toggle("", isOn: $filterActiveOnly)
                        .labelsHidden()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(filteredAthletes) { athlete in
                        NavigationLink {
                            AthleteProfileView(athlete: athlete)
                        } label: {
                            GlassCard(cornerRadius: AppTheme.Corners.lg) {
                                HStack {
                                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                        HStack(spacing: AppSpacing.sm) {
                                            Text(athlete.name)
                                                .font(AppTypography.headline)
                                            statusBadge
                                        }
                                        Text("Last workout: 2d ago • Volume: 14,200 kg")
                                            .font(AppTypography.footnote)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var filteredAthletes: [User] {
        viewModel.athletes.filter { athlete in
            (searchText.isEmpty || athlete.name.lowercased().contains(searchText.lowercased()))
        }
    }
    
    private var statusBadge: some View {
        Text("ACTIVE")
            .font(AppTypography.monoCaption)
            .foregroundColor(.white)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(LinearGradient(
                        colors: [AppColors.accent, AppColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
    }
}

// MARK: - Athlete Profile

struct AthleteProfileView: View {
    let athlete: User
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(athlete.name)
                                    .font(AppTypography.title2)
                                Text("Connected • 8-week strength block")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        SectionHeader(title: "Progress", actionTitle: nil, action: nil)
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text("Summary")
                                    .font(AppTypography.headline)
                                Text("Placeholder charts and stats. Replace with real data later.")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                Rectangle()
                                    .fill(AppColors.progressBackground)
                                    .frame(height: 140)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        SectionHeader(title: "Plan", actionTitle: nil, action: nil)
                        NavigationLink {
                            PlanBuilderView(appState: appState)
                        } label: {
                            CardView {
                                HStack {
                                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                        Text("8-Week Strength Block")
                                            .font(AppTypography.headline)
                                        Text("3 days / week • Last updated 3d ago")
                                            .font(AppTypography.footnote)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
            .navigationTitle("Athlete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Plan Builder

struct PlanBuilderView: View {
    @ObservedObject var appState: AppState
    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            SectionHeader(
                title: "Weekly schedule",
                subtitle: "Drag to reorder training days",
                actionTitle: nil,
                action: nil
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(weekDays, id: \.self) { day in
                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            HStack {
                                Image(systemName: "line.3.horizontal.circle")
                                    .foregroundColor(AppColors.textSecondary)
                                Text(day)
                                    .font(AppTypography.body)
                                Spacer()
                                Text("Lower Body Strength")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
            .frame(maxWidth: .infinity)
            NavigationLink {
                WorkoutEditorView()
            } label: {
                PrimaryActionButtonLabel(title: "Edit Monday workout", icon: "slider.horizontal.3")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("Plan builder")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Workout Editor

struct WorkoutEditorView: View {
    @State private var exercises: [Exercise] = MockData.sampleExercises

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                SectionHeader(
                    title: "Workout day",
                    subtitle: "Tap an exercise to edit"
                )

                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(exercises) { exercise in
                            NavigationLink {
                                ExerciseEditorView(exercise: exercise)
                            } label: {
                                GlassCard(cornerRadius: AppTheme.Corners.md) {
                                    ExerciseRow(exercise: exercise)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
                }

                NavigationLink {
                    SendUpdateView()
                } label: {
                    PrimaryActionButtonLabel(title: "Send update to athlete", icon: "paperplane.fill")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle("Workout editor")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Exercise Editor

struct ExerciseEditorView: View {
    @State var exercise: Exercise

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    SectionHeader(title: "Exercise", subtitle: "Fine-tune sets, reps and load")

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Name")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("Bench Press", text: $exercise.name)
                                .font(AppTypography.body)
                                .padding(.vertical, AppSpacing.sm)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(AppColors.border.opacity(0.5)),
                                    alignment: .bottom
                                )
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Sets & reps")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)

                            HStack(spacing: AppSpacing.lg) {
                                CustomStepper(label: "Sets", value: $exercise.sets, range: 1...10)
                                CustomStepper(label: "Reps", value: $exercise.reps, range: 1...20)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Load & rest")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)

                            HStack(spacing: AppSpacing.lg) {
                                CustomStepper(label: "Weight (kg)", value: Binding(
                                    get: { Int(exercise.weight) },
                                    set: { exercise.weight = Double($0) }
                                ), range: 0...300, step: 2)

                                CustomStepper(label: "Rest (s)", value: $exercise.restSeconds, range: 30...300, step: 15)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Notes")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("Coaching notes", text: Binding(
                                get: { exercise.notes ?? "" },
                                set: { exercise.notes = $0.isEmpty ? nil : $0 }
                            ))
                                .font(AppTypography.body)
                        }
                    }

                    Spacer(minLength: AppSpacing.xxxl)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Custom Stepper

struct CustomStepper<Value: Strideable>: View where Value.Stride == Int {
    let label: String
    @Binding var value: Value
    let range: ClosedRange<Value>
    var step: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: AppSpacing.sm) {
                Button {
                    let newValue = value.advanced(by: -step)
                    if newValue >= range.lowerBound { value = newValue }
                    HapticManager.selection()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(AppColors.backgroundElevated)
                        )
                }
                .buttonStyle(.plain)

                Text(verbatim: String(describing: value))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .frame(minWidth: 44)

                Button {
                    let newValue = value.advanced(by: step)
                    if newValue <= range.upperBound { value = newValue }
                    HapticManager.selection()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(AppColors.accent)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Send Update

struct SendUpdateView: View {
    @State private var isSending: Bool = false
    @State private var didSend: Bool = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                Image(systemName: didSend ? "paperplane.circle.fill" : "paperplane.circle")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.accent)
                    .scaleEffect(didSend ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: didSend)
                Text(didSend ? "Update sent" : "Send update to athlete")
                    .font(AppTypography.title2)
                Text("This will notify the athlete that their plan has changed.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                Spacer()
                PrimaryButton(title: didSend ? "Done" : "Send update") {
                    if !didSend {
                        isSending = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            HapticManager.success()
                            isSending = false
                            didSend = true
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
            if isSending {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationBarBackButtonHidden(didSend)
    }
}

// MARK: - Updates + Profile Shells

struct CoachUpdatesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                SectionHeader(
                    title: "Recent updates",
                    subtitle: "What your athletes will see next"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Change log")
                            .font(AppTypography.headline)
                        Text("Preview of sent updates will appear here. For now this is a static mock.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CoachProfileView: View {
    let coach: User
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                GlassCard {
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accentSecondary.opacity(0.2))
                            Text(String(coach.name.prefix(1)))
                                .font(AppTypography.title1)
                                .foregroundColor(AppColors.accentSecondary)
                        }
                        .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(coach.name)
                                .font(AppTypography.title2)
                            Text("Coach workspace")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                SectionHeader(title: "Workspace", actionTitle: nil, action: nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: AppSpacing.md) {
                    SecondaryButton(title: "Billing & subscription") { }
                    SecondaryButton(title: "Export data") { }
                    SecondaryButton(title: "Sign out") {
                        appState.signOut()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

struct CoachViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                CoachDashboardView(
                    viewModel: CoachDashboardViewModel(
                        coach: MockData.sampleCoach,
                        userService: UserService()
                    )
                )
            }
            .preferredColorScheme(.light)

            NavigationStack {
                AthleteProfileView(athlete: MockData.sampleAthlete)
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.dark)

            NavigationStack {
                PlanBuilderView(appState: AppState())
            }
            .preferredColorScheme(.light)

            NavigationStack {
                WorkoutEditorView()
            }
            .preferredColorScheme(.dark)

            NavigationStack {
                ExerciseEditorView(exercise: MockData.sampleExercises.first!)
            }
            .preferredColorScheme(.light)

            NavigationStack {
                SendUpdateView()
            }
            .preferredColorScheme(.dark)

            CoachTabRootView(
                coach: MockData.sampleCoach,
                appState: AppState()
            )
            .preferredColorScheme(.dark)
        }
    }
}
