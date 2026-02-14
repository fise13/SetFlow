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
            NavigationStack { PlanProgramsEntryView(appState: appState) }
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
    @State private var plan: WorkoutPlan?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(athlete.name)
                                    .font(AppTypography.title2)
                                Text(plan != nil ? "Connected • \(plan!.days.count) workout days" : "Connected")
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
                            PlanBuilderView(athlete: athlete, appState: appState)
                        } label: {
                            CardView {
                                HStack {
                                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                        Text(plan?.name ?? "Create plan")
                                            .font(AppTypography.headline)
                                        Text(planSummaryText)
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
        .onAppear { loadPlan() }
    }

    private var planSummaryText: String {
        guard let p = plan else { return "Tap to create or edit plan" }
        let dayCount = p.days.count
        let lastUpdated = p.lastUpdatedAt.map { relativeDate($0) } ?? "Not yet updated"
        return "\(dayCount) days / week • Last updated \(lastUpdated)"
    }

    private func relativeDate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "yesterday" }
        if days < 7 { return "\(days)d ago" }
        return "\(days / 7)w ago"
    }

    private func loadPlan() {
        guard let coachId = appState.currentUser?.id else { return }
        Task {
            do {
                let plans = try await appState.planService.plansForCoach(coachId: coachId)
                await MainActor.run {
                    plan = plans.first { $0.athleteId == athlete.id }
                }
            } catch {
                await MainActor.run { plan = nil }
            }
        }
    }
}

// MARK: - Plan Programs Entry (athlete picker for Programs tab)

struct PlanProgramsEntryView: View {
    @ObservedObject var appState: AppState
    @State private var athletes: [User] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            if isLoading {
                ProgressView()
            } else if athletes.isEmpty {
                VStack(spacing: AppSpacing.lg) {
                    Text("No athletes yet")
                        .font(AppTypography.title2)
                    Text("Generate an invite code from Profile and share it with athletes to connect.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(athletes) { athlete in
                            NavigationLink {
                                PlanBuilderView(athlete: athlete, appState: appState)
                            } label: {
                                GlassCard(cornerRadius: AppTheme.Corners.md) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(athlete.name)
                                                .font(AppTypography.headline)
                                            Text("Tap to manage plan")
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
                    .padding(.vertical, AppSpacing.lg)
                }
            }
        }
        .navigationTitle("Programs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        guard let coach = appState.currentUser, coach.role == .coach else { return }
        isLoading = true
        Task {
            do {
                athletes = try await appState.userService.athletesForCoach(coachId: coach.id)
            } catch {
                athletes = []
            }
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Plan Builder

struct PlanBuilderView: View {
    let athlete: User
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: PlanBuilderViewModel

    init(athlete: User, appState: AppState) {
        self.athlete = athlete
        self.appState = appState
        _viewModel = StateObject(wrappedValue: PlanBuilderViewModel(
            athlete: athlete,
            coachId: appState.currentUser?.id ?? "",
            planService: appState.planService
        ))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                SectionHeader(
                    title: "Weekly schedule",
                    subtitle: viewModel.plan != nil ? "Tap a day to edit exercises" : "Create a plan to get started",
                    actionTitle: viewModel.plan != nil ? "Add day" : "Create plan",
                    action: viewModel.plan != nil ? { viewModel.addDay() } : { viewModel.createPlan() }
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let plan = viewModel.plan {
                    ScrollView {
                        VStack(spacing: AppSpacing.sm) {
                            ForEach(Array(plan.days.enumerated()), id: \.element.id) { index, day in
                                NavigationLink {
                                    WorkoutEditorView(
                                        plan: plan,
                                        dayIndex: index,
                                        planService: appState.planService,
                                        onSave: { updatedPlan in viewModel.updatePlan(updatedPlan) }
                                    )
                                } label: {
                                    GlassCard(cornerRadius: AppTheme.Corners.md) {
                                        HStack {
                                            Image(systemName: "line.3.horizontal.circle")
                                                .foregroundColor(AppColors.textSecondary)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(day.title)
                                                    .font(AppTypography.body)
                                                Text(dayDateString(day.date))
                                                    .font(AppTypography.footnote)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            Spacer()
                                            Text("\(day.exercises.count) exercises")
                                                .font(AppTypography.footnote)
                                                .foregroundColor(AppColors.textSecondary)
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                    Text("No plan yet")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    PrimaryButton(title: "Create plan") {
                        viewModel.createPlan()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    Spacer()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
        }
        .navigationTitle(planTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    private var planTitle: String {
        viewModel.plan?.name ?? "Plan for \(athlete.name)"
    }

    private func dayDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}

// MARK: - Plan Builder View Model

final class PlanBuilderViewModel: ObservableObject {
    let athlete: User
    let coachId: String
    private let planService: WorkoutPlanService

    @Published var plan: WorkoutPlan?
    @Published var isLoading = false

    init(athlete: User, coachId: String, planService: WorkoutPlanService) {
        self.athlete = athlete
        self.coachId = coachId
        self.planService = planService
    }

    @MainActor
    func load() {
        isLoading = true
        Task {
            do {
                let plans = try await planService.plansForCoach(coachId: coachId)
                plan = plans.first { $0.athleteId == athlete.id }
            } catch {
                plan = nil
            }
            isLoading = false
        }
    }

    @MainActor
    func createPlan() {
        guard !coachId.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let calendar = Calendar.current
                let startOfToday = calendar.startOfDay(for: Date())
                let defaultDay = WorkoutDay(
                    id: UUID().uuidString,
                    title: "Workout 1",
                    focus: "Full body",
                    date: startOfToday,
                    exercises: []
                )
                let newPlan = try await planService.createPlan(
                    name: "\(self.athlete.name)'s Plan",
                    description: "",
                    athleteId: self.athlete.id,
                    coachId: self.coachId,
                    days: [defaultDay]
                )
                plan = newPlan
            } catch { }
            isLoading = false
        }
    }

    func addDay() {
        guard var p = plan else { return }
        let lastDate = p.days.last?.date ?? Date()
        let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDate) ?? Date()
        let newDay = WorkoutDay(
            id: UUID().uuidString,
            title: "Workout \(p.days.count + 1)",
            focus: "",
            date: nextDate,
            exercises: []
        )
        p.days.append(newDay)
        updatePlan(p)
    }

    func updatePlan(_ p: WorkoutPlan) {
        plan = p
        Task {
            try? await planService.updatePlan(p)
        }
    }
}

// MARK: - Workout Editor

struct WorkoutEditorView: View {
    let plan: WorkoutPlan
    let dayIndex: Int
    let planService: WorkoutPlanService
    let onSave: (WorkoutPlan) -> Void

    @State private var workoutDay: WorkoutDay

    init(plan: WorkoutPlan, dayIndex: Int, planService: WorkoutPlanService, onSave: @escaping (WorkoutPlan) -> Void) {
        self.plan = plan
        self.dayIndex = dayIndex
        self.planService = planService
        self.onSave = onSave
        _workoutDay = State(initialValue: plan.days[dayIndex])
    }

    private var updatedPlan: WorkoutPlan {
        var p = plan
        if dayIndex < p.days.count {
            p.days[dayIndex] = workoutDay
        }
        return p
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                SectionHeader(
                    title: "Workout day",
                    subtitle: "Tap an exercise to edit • Date sets when this workout is scheduled"
                )

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Date")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                DatePicker("", selection: Binding(
                                    get: { workoutDay.date },
                                    set: {
                                        workoutDay = WorkoutDay(id: workoutDay.id, title: workoutDay.title, focus: workoutDay.focus, date: $0, exercises: workoutDay.exercises)
                                        onSave(updatedPlan)
                                    }
                                ), displayedComponents: .date)
                                .labelsHidden()
                            }
                        }

                        SectionHeader(title: "Exercises", actionTitle: "Add", action: addExercise)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: AppSpacing.sm) {
                            ForEach(Array(workoutDay.exercises.enumerated()), id: \.element.id) { index, exercise in
                                NavigationLink {
                                    ExerciseEditorView(
                                        exercise: workoutDay.exercises[index],
                                        onSave: { updated in
                                            workoutDay.exercises[index] = updated
                                            onSave(updatedPlan)
                                        }
                                    )
                                } label: {
                                    GlassCard(cornerRadius: AppTheme.Corners.md) {
                                        ExerciseRow(exercise: exercise)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
                }

                NavigationLink {
                    SendUpdateView(plan: updatedPlan, planService: planService)
                } label: {
                    PrimaryActionButtonLabel(title: "Send update to athlete", icon: "paperplane.fill")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle(workoutDay.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { onSave(updatedPlan) }
    }

    private func addExercise() {
        let newEx = Exercise(
            id: UUID().uuidString,
            name: "New exercise",
            sets: 3,
            reps: 10,
            weight: 0,
            restSeconds: 90,
            notes: nil
        )
        workoutDay.exercises.append(newEx)
        onSave(updatedPlan)
    }
}

// MARK: - Exercise Editor

struct ExerciseEditorView: View {
    let onSave: (Exercise) -> Void
    @State private var exercise: Exercise

    init(exercise: Exercise, onSave: @escaping (Exercise) -> Void) {
        self.onSave = onSave
        _exercise = State(initialValue: exercise)
    }

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
        .onDisappear { onSave(exercise) }
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
    let plan: WorkoutPlan
    let planService: WorkoutPlanService
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
                        sendUpdate()
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

    private func sendUpdate() {
        isSending = true
        Task {
            do {
                try await planService.markPlanUpdated(plan)
                await MainActor.run {
                    HapticManager.success()
                    didSend = true
                }
            } catch { }
            await MainActor.run { isSending = false }
        }
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
    @State private var showEditProfile = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Button {
                    showEditProfile = true
                } label: {
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
                                Text("Coach workspace • Tap to edit")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "pencil.circle")
                                .font(.title2)
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                SectionHeader(title: "Workspace", actionTitle: nil, action: nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: AppSpacing.md) {
                    NavigationLink {
                        CoachInviteCodeView(coach: coach, inviteCodeService: appState.inviteCodeService)
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(AppColors.accent)
                            Text("Generate invite code")
                                .font(AppTypography.callout)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .padding(.horizontal, AppSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                                        .strokeBorder(AppColors.border.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
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
        .sheet(isPresented: $showEditProfile) {
            CoachEditProfileSheet(coach: coach, appState: appState, onDismiss: { showEditProfile = false })
        }
    }
}

// MARK: - Coach Edit Profile Sheet

struct CoachEditProfileSheet: View {
    let coach: User
    @ObservedObject var appState: AppState
    let onDismiss: () -> Void
    @State private var name: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    Text("Name")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    TextField("Your name", text: $name)
                        .textContentType(.name)
                        .font(AppTypography.body)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(RoundedRectangle(cornerRadius: AppTheme.Corners.md).fill(AppColors.backgroundElevated))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Corners.md).strokeBorder(AppColors.border, lineWidth: 1))

                    if let err = errorMessage {
                        Text(err)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.danger)
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { name = coach.name }
        }
    }

    private func save() {
        let newName = name.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty else { return }
        errorMessage = nil
        isSaving = true
        Task { @MainActor in
            do {
                try await appState.userService.updateUser(id: coach.id, name: newName)
                await appState.refetchCurrentUser()
                HapticManager.success()
                onDismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - Coach Invite Code Generator

struct CoachInviteCodeView: View {
    let coach: User
    let inviteCodeService: InviteCodeService
    @State private var generatedCode: String?
    @State private var expiresAt: Date?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    SectionHeader(
                        title: "Invite athletes",
                        subtitle: "Generate a code. Athletes enter it when signing up. Valid for 24 hours."
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let code = generatedCode, let expires = expiresAt {
                        GlassCard {
                            VStack(spacing: AppSpacing.lg) {
                                Text(code)
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .tracking(4)
                                Text("Expires \(formattedExpiry(expires))")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.danger)
                            .padding(.horizontal)
                    }

                    PrimaryButton(title: generatedCode == nil ? "Generate code" : "Generate new code") {
                        generateCode()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.vertical, AppSpacing.xl)
            }
            if isGenerating {
                ProgressView()
            }
        }
        .navigationTitle("Invite code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateCode() {
        guard !isGenerating else { return }
        isGenerating = true
        errorMessage = nil
        Task {
            do {
                let code = try await inviteCodeService.generateCode(coachId: coach.id)
                let expires = Date().addingTimeInterval(24 * 3600)
                await MainActor.run {
                    generatedCode = code
                    expiresAt = expires
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run { isGenerating = false }
        }
    }

    private func formattedExpiry(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                        PlanBuilderView(athlete: MockData.sampleAthlete, appState: AppState())
                    }
                    .preferredColorScheme(.light)

            NavigationStack {
                WorkoutEditorView(
                    plan: WorkoutPlan(id: "preview", name: "Preview", description: "", athleteId: MockData.sampleAthlete.id, coachId: MockData.sampleCoach.id, athlete: nil, days: [MockData.todayWorkoutDay]),
                    dayIndex: 0,
                    planService: WorkoutPlanService(),
                    onSave: { _ in }
                )
            }
            .preferredColorScheme(.dark)

                    NavigationStack {
                        ExerciseEditorView(exercise: MockData.sampleExercises.first!, onSave: { _ in })
                    }
                    .preferredColorScheme(.light)

                    NavigationStack {
                        SendUpdateView(plan: WorkoutPlan(id: "preview", name: "Preview", description: "", athleteId: "", coachId: "", athlete: nil, days: []), planService: WorkoutPlanService())
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
