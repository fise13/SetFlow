import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Coach Tabs

enum CoachTab: String, CaseIterable {
    case athletes
    case programs
    case signals
    case profile
    
    var title: String {
        switch self {
        case .athletes: return String(localized: "tab_athletes")
        case .programs: return String(localized: "tab_programs")
        case .signals: return String(localized: "tab_signals")
        case .profile: return String(localized: "tab_profile")
        }
    }
    
    var systemImage: String {
        switch self {
        case .athletes: return "person.3.fill"
        case .programs: return "list.bullet.rectangle"
        case .signals: return "waveform.path.ecg"
        case .profile: return "person.crop.circle"
        }
    }
}

struct CoachTabRootView: View {
    let coach: User
    @ObservedObject var appState: AppState
    @ObservedObject private var prefs = AppPreferences.shared

    @StateObject private var dashboardVM: CoachDashboardViewModel
    @State private var selectedTab: CoachTab = .athletes
    @State private var showFirstRunOnboarding = false
    @State private var didEvaluateOnboarding = false

    init(coach: User, appState: AppState) {
        self.coach = coach
        self.appState = appState
        _dashboardVM = StateObject(wrappedValue: CoachDashboardViewModel(
            coach: coach,
            userService: appState.userService,
            planService: appState.planService,
            logService: appState.logService
        ))
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
        .onChange(of: dashboardVM.isLoading) { _, isLoading in
            if !isLoading {
                evaluateFirstRunOnboardingIfNeeded()
            }
        }
        .sheet(isPresented: $showFirstRunOnboarding) {
            CoachFirstRunOnboardingView(
                onContinue: {
                    prefs.markFirstRunOnboardingSeen(role: .coach, userId: coach.id)
                    showFirstRunOnboarding = false
                },
                onSkip: { neverShowAgain in
                    if neverShowAgain {
                        prefs.markFirstRunOnboardingSeen(role: .coach, userId: coach.id)
                    }
                    showFirstRunOnboarding = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .athletes:
            NavigationStack { CoachDashboardView(viewModel: dashboardVM) }
        case .programs:
            NavigationStack { PlanProgramsEntryView(appState: appState) }
        case .signals:
            NavigationStack { CoachSignalsView(appState: appState) }
        case .profile:
            NavigationStack { CoachProfileView(coach: coach) }
        }
    }
    
    private func evaluateFirstRunOnboardingIfNeeded() {
        guard !didEvaluateOnboarding else { return }
        didEvaluateOnboarding = true
        let alreadySeen = prefs.hasSeenFirstRunOnboarding(role: .coach, userId: coach.id)
        guard !alreadySeen else { return }
        showFirstRunOnboarding = true
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
    private let planService: WorkoutPlanService
    private let logService: WorkoutLogService

    @Published var athletes: [User] = []
    @Published var isLoading: Bool = true
    @Published var trainedToday: [User] = []
    @Published var missedToday: [User] = []
    @Published var inactiveAthletes: [User] = []
    @Published var sentFeedback: [User] = []

    init(coach: User, userService: UserService, planService: WorkoutPlanService, logService: WorkoutLogService) {
        self.coach = coach
        self.userService = userService
        self.planService = planService
        self.logService = logService
    }

    @MainActor
    func load() {
        isLoading = true
        Task {
            do {
                athletes = try await userService.athletesForCoach(coachId: coach.id)
                let plans = try await planService.plansForCoach(coachId: coach.id)
                let today = Calendar.current.startOfDay(for: Date())
                var trained: [User] = []
                var missed: [User] = []
                var inactive: [User] = []
                var feedback: [User] = []

                for athlete in athletes {
                    let athletePlanDays = plans
                        .first(where: { $0.athleteId == athlete.id })?
                        .days ?? []
                    let hasWorkoutToday = athletePlanDays.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
                    let logs = (try? await logService.logsForAthlete(athleteId: athlete.id, limit: 20)) ?? []
                    let trainedTodayFlag = logs.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
                    if trainedTodayFlag { trained.append(athlete) }
                    if hasWorkoutToday && !trainedTodayFlag { missed.append(athlete) }

                    if let lastSeen = athlete.lastSeenAt {
                        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastSeen), to: today).day ?? 0
                        if days >= 3 { inactive.append(athlete) }
                    } else {
                        inactive.append(athlete)
                    }

                    let sentFeedbackFlag = logs.contains { log in
                        log.exerciseFeedbacks.contains {
                            ($0.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) || $0.difficulty != 3
                        }
                    }
                    if sentFeedbackFlag { feedback.append(athlete) }
                }

                trainedToday = trained
                missedToday = missed
                inactiveAthletes = inactive
                sentFeedback = feedback
            } catch {
                athletes = []
                trainedToday = []
                missedToday = []
                inactiveAthletes = []
                sentFeedback = []
            }
            isLoading = false
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
                    title: String(localized: "section_athletes"),
                    subtitle: String(localized: "athletes_subtitle"),
                    actionTitle: String(localized: "button_add")
                ) { }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    TextField(String(localized: "search_athletes_placeholder"), text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                        .fill(AppColors.backgroundElevated.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                .strokeBorder(AppColors.border.opacity(0.5), lineWidth: 1)
                        )
                )
                .appShadow(.softCard)
                .frame(maxWidth: .infinity)

                HStack {
                    Text("filter_active")
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
                    if viewModel.isLoading {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonCard()
                        }
                    } else {
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
                                            Text(String(localized: "last_workout_volume_format"))
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
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("nav_dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var filteredAthletes: [User] {
        viewModel.athletes.filter { athlete in
            (searchText.isEmpty || athlete.name.lowercased().contains(searchText.lowercased()))
        }
    }
    
    private var statusBadge: some View {
        Text("active_badge")
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

// MARK: - Coach Signals

struct CoachSignalsView: View {
    @ObservedObject var appState: AppState
    @State private var athletes: [User] = []
    @State private var trainedToday: [User] = []
    @State private var missedToday: [User] = []
    @State private var inactiveAthletes: [User] = []
    @State private var sentFeedback: [User] = []
    @State private var isLoading = false
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SectionHeader(
                    title: String(localized: "coach_dashboard_signals_title"),
                    subtitle: String(localized: "coach_signals_subtitle")
                )
                signalSection(title: String(localized: "coach_dashboard_trained_today"), athletes: trainedToday)
                signalSection(title: String(localized: "coach_dashboard_missed_today"), athletes: missedToday)
                signalSection(title: String(localized: "coach_dashboard_inactive"), athletes: inactiveAthletes)
                signalSection(title: String(localized: "coach_dashboard_sent_feedback"), athletes: sentFeedback)

                SectionHeader(
                    title: String(localized: "coach_full_athlete_list_title"),
                    subtitle: String(format: String(localized: "coach_full_athlete_list_count"), athletes.count)
                )

                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    TextField(String(localized: "search_athletes_placeholder"), text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                        .fill(AppColors.backgroundElevated.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                .strokeBorder(AppColors.border.opacity(0.5), lineWidth: 1)
                        )
                )

                if isLoading {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonCard()
                    }
                } else if filteredAthletes.isEmpty {
                    GlassCard(cornerRadius: AppTheme.Corners.md) {
                        Text("coach_dashboard_none")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    ForEach(filteredAthletes) { athlete in
                        NavigationLink {
                            AthleteProfileView(athlete: athlete)
                        } label: {
                            GlassCard(cornerRadius: AppTheme.Corners.md) {
                                HStack {
                                    Text(athlete.name)
                                        .font(AppTypography.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("tab_signals")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    private var filteredAthletes: [User] {
        athletes.filter { athlete in
            searchText.isEmpty || athlete.name.lowercased().contains(searchText.lowercased())
        }
    }

    private func signalSection(title: String, athletes: [User]) -> some View {
        GlassCard(cornerRadius: AppTheme.Corners.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.callout.weight(.semibold))
                if athletes.isEmpty {
                    Text("coach_dashboard_none")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    ForEach(athletes) { athlete in
                        NavigationLink {
                            AthleteProfileView(athlete: athlete)
                        } label: {
                            HStack {
                                Text(athlete.name)
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func load() async {
        guard let coach = appState.currentUser, coach.role == .coach else { return }
        await MainActor.run { isLoading = true }
        do {
            let loadedAthletes = try await appState.userService.athletesForCoach(coachId: coach.id)
            let plans = try await appState.planService.plansForCoach(coachId: coach.id)
            let today = Calendar.current.startOfDay(for: Date())

            var trained: [User] = []
            var missed: [User] = []
            var inactive: [User] = []
            var feedback: [User] = []

            for athlete in loadedAthletes {
                let logs = (try? await appState.logService.logsForAthlete(athleteId: athlete.id, limit: 20)) ?? []
                let hasWorkoutToday = plans
                    .first(where: { $0.athleteId == athlete.id })?
                    .days.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) ?? false
                let trainedTodayFlag = logs.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }

                if trainedTodayFlag { trained.append(athlete) }
                if hasWorkoutToday && !trainedTodayFlag { missed.append(athlete) }

                if let lastSeen = athlete.lastSeenAt {
                    let daysSinceOpen = Calendar.current.dateComponents(
                        [.day],
                        from: Calendar.current.startOfDay(for: lastSeen),
                        to: today
                    ).day ?? 0
                    if daysSinceOpen >= 3 { inactive.append(athlete) }
                } else {
                    inactive.append(athlete)
                }

                let sentFeedbackFlag = logs.contains { log in
                    log.exerciseFeedbacks.contains {
                        ($0.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) || $0.difficulty != 3
                    }
                }
                if sentFeedbackFlag { feedback.append(athlete) }
            }

            await MainActor.run {
                athletes = loadedAthletes
                trainedToday = trained
                missedToday = missed
                inactiveAthletes = inactive
                sentFeedback = feedback
                isLoading = false
            }
        } catch {
            await MainActor.run {
                athletes = []
                trainedToday = []
                missedToday = []
                inactiveAthletes = []
                sentFeedback = []
                isLoading = false
            }
        }
    }
}

// MARK: - Athlete Profile

struct AthleteProfileView: View {
    let athlete: User
    @EnvironmentObject private var appState: AppState
    @State private var plan: WorkoutPlan?
    @State private var logs: [WorkoutLog] = []
    @State private var isLoadingSummary = false

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

                        SectionHeader(title: String(localized: "section_progress_coach"), actionTitle: nil, action: nil)
                        CardView {
                            if isLoadingSummary {
                                HStack {
                                    ProgressView()
                                    Text("loading")
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            } else if logs.isEmpty {
                                Text("coach_athlete_summary_empty")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                VStack(alignment: .leading, spacing: AppSpacing.md) {
                                    Text("summary_label")
                                        .font(AppTypography.headline)
                                    HStack(spacing: AppSpacing.md) {
                                        summaryMetric(title: String(localized: "coach_summary_workouts"), value: "\(logs.count)")
                                        summaryMetric(title: String(localized: "coach_summary_avg_rating"), value: avgRatingText)
                                        summaryMetric(title: String(localized: "coach_summary_last"), value: lastWorkoutText)
                                    }
                                    if let note = latestAthleteNote {
                                        Text(String(format: String(localized: "coach_summary_note_format"), note))
                                            .font(AppTypography.footnote)
                                            .foregroundColor(AppColors.accentSecondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        if !logs.isEmpty {
                            SectionHeader(title: String(localized: "coach_section_recent_workouts"), actionTitle: nil, action: nil)
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(Array(logs.prefix(5).enumerated()), id: \.element.id) { _, log in
                                    GlassCard(cornerRadius: AppTheme.Corners.md) {
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            HStack {
                                                Text(log.workoutTitle)
                                                    .font(AppTypography.headline)
                                                Spacer()
                                                Text(relativeDate(log.date))
                                                    .font(AppTypography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            Text(String(format: String(localized: "coach_summary_overview_format"), log.totalSets, Int(log.totalVolume), log.rating))
                                                .font(AppTypography.footnote)
                                                .foregroundColor(AppColors.textSecondary)
                                            if !log.exerciseFeedbacks.isEmpty {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    ForEach(log.exerciseFeedbacks.prefix(3)) { feedback in
                                                        HStack {
                                                            Text(feedback.exerciseName)
                                                                .font(AppTypography.caption)
                                                            Spacer()
                                                            Text(String(format: String(localized: "difficulty_value_format"), feedback.difficulty))
                                                                .font(AppTypography.caption)
                                                                .foregroundColor(AppColors.textMuted)
                                                        }
                                                        if let note = feedback.note, !note.isEmpty {
                                                            Text(note)
                                                                .font(AppTypography.caption)
                                                                .foregroundColor(AppColors.accentSecondary)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }

                        SectionHeader(title: String(localized: "section_plan"), actionTitle: nil, action: nil)
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
            .navigationTitle("nav_athlete")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadPlan()
            loadSummary()
        }
    }

    private var planSummaryText: String {
        guard let p = plan else { return "Tap to create or edit plan" }
        let dayCount = p.days.count
        let lastUpdated = p.lastUpdatedAt.map { relativeDate($0) } ?? "Not yet updated"
        return "\(dayCount) days / week • Last updated \(lastUpdated)"
    }

    private var avgRatingText: String {
        guard !logs.isEmpty else { return "—" }
        let avg = Double(logs.map(\.rating).reduce(0, +)) / Double(logs.count)
        return String(format: "%.1f", avg)
    }

    private var lastWorkoutText: String {
        guard let latest = logs.first else { return "—" }
        return relativeDate(latest.date)
    }

    private var latestAthleteNote: String? {
        logs
            .flatMap(\.exerciseFeedbacks)
            .compactMap(\.note)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
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

    private func loadSummary() {
        isLoadingSummary = true
        Task {
            do {
                let list = try await appState.logService.logsForAthlete(athleteId: athlete.id, limit: 20)
                await MainActor.run {
                    logs = list
                    isLoadingSummary = false
                }
            } catch {
                await MainActor.run {
                    logs = []
                    isLoadingSummary = false
                }
            }
        }
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonCard()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.lg)
                }
            } else if athletes.isEmpty {
                VStack(spacing: AppSpacing.lg) {
                    Text("no_athletes_yet")
                        .font(AppTypography.title2)
                    Text("no_athletes_desc")
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
                                            Text("tap_to_manage_plan")
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
        .navigationTitle("nav_programs")
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

struct CoachFirstRunOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: (_ neverShowAgain: Bool) -> Void
    @State private var neverShowAgain = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("first_run_coach_title")
                                    .font(AppTypography.title2)
                                Text("first_run_coach_message")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        featureItem(
                            icon: "calendar.badge.plus",
                            title: String(localized: "first_run_coach_feature_plans_title"),
                            subtitle: String(localized: "first_run_coach_feature_plans_subtitle")
                        )
                        featureItem(
                            icon: "dumbbell.fill",
                            title: String(localized: "first_run_coach_feature_exercises_title"),
                            subtitle: String(localized: "first_run_coach_feature_exercises_subtitle")
                        )
                        featureItem(
                            icon: "paperplane.fill",
                            title: String(localized: "first_run_coach_feature_updates_title"),
                            subtitle: String(localized: "first_run_coach_feature_updates_subtitle")
                        )
                        featureItem(
                            icon: "chart.line.uptrend.xyaxis",
                            title: String(localized: "first_run_coach_feature_summary_title"),
                            subtitle: String(localized: "first_run_coach_feature_summary_subtitle")
                        )

                        Toggle(isOn: $neverShowAgain) {
                            Text("first_run_coach_never_show_again")
                                .font(AppTypography.footnote)
                        }
                        .tint(AppColors.accent)
                        .padding(.top, AppSpacing.sm)

                        HStack(spacing: AppSpacing.sm) {
                            SecondaryButton(title: String(localized: "first_run_coach_skip")) {
                                onSkip(neverShowAgain)
                            }
                            PrimaryButton(title: String(localized: "first_run_coach_action")) {
                                onContinue()
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.lg)
                }
            }
            .navigationTitle("first_run_coach_nav_title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func featureItem(icon: String, title: String, subtitle: String) -> some View {
        GlassCard(cornerRadius: AppTheme.Corners.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(AppColors.accent.opacity(0.14)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.callout.weight(.semibold))
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Plan Builder

struct PlanBuilderView: View {
    let athlete: User
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: PlanBuilderViewModel
    @State private var selectedWeekOffset: Int = 0
    @State private var visibleWeekCount: Int = 1

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
                    title: String(localized: "section_weekly_schedule"),
                    subtitle: viewModel.plan != nil ? String(localized: "weekly_schedule_subtitle") : "Create a plan to get started",
                    actionTitle: viewModel.plan != nil ? String(localized: "button_add_workout_day") : "Create plan",
                    action: viewModel.plan != nil ? { viewModel.addDay(inWeekOffset: selectedWeekOffset) } : { viewModel.createPlan() }
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let plan = viewModel.plan {
                    weekTabs
                    ScrollView {
                        VStack(spacing: AppSpacing.sm) {
                            ForEach(viewModel.daysForWeek(offset: selectedWeekOffset), id: \.day.id) { item in
                                let index = item.index
                                let day = item.day
                                HStack(spacing: AppSpacing.sm) {
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
                                                Text(String(format: String(localized: "exercises_count_format"), day.exercises.count))
                                                    .font(AppTypography.footnote)
                                                    .foregroundColor(AppColors.textSecondary)
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        viewModel.deleteDay(at: index)
                                        HapticManager.impact()
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(AppColors.danger)
                                            .frame(width: 38, height: 38)
                                            .background(
                                                Circle()
                                                    .fill(AppColors.danger.opacity(0.12))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text("button_delete_day"))
                                }
                            }
                            if viewModel.daysForWeek(offset: selectedWeekOffset).isEmpty {
                                GlassCard(cornerRadius: AppTheme.Corners.md) {
                                    Text("no_days_in_selected_week")
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                    Text("no_plan_yet")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    PrimaryButton(title: String(localized: "button_create_plan")) {
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
        .onChange(of: viewModel.plan?.days.count ?? 0) { _, _ in
            recalculateWeekVisibility()
        }
    }

    private var planTitle: String {
        viewModel.plan?.name ?? "Plan for \(athlete.name)"
    }

    private func dayDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    private var weekTabs: some View {
        VStack(spacing: AppSpacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<visibleWeekCount, id: \.self) { offset in
                        Button {
                            selectedWeekOffset = offset
                            HapticManager.selection()
                        } label: {
                            Text(String(format: String(localized: "week_number_format"), offset + 1))
                                .font(AppTypography.footnote)
                                .foregroundColor(selectedWeekOffset == offset ? .white : AppColors.textSecondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(selectedWeekOffset == offset ? AppColors.accent : AppColors.backgroundElevated.opacity(0.7))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        visibleWeekCount += 1
                        selectedWeekOffset = visibleWeekCount - 1
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("button_add_week")
                        }
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.accentSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppColors.backgroundElevated.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func recalculateWeekVisibility() {
        let needed = max(1, viewModel.maxExistingWeekOffset + 1)
        if visibleWeekCount < needed {
            visibleWeekCount = needed
        }
        if selectedWeekOffset >= visibleWeekCount {
            selectedWeekOffset = visibleWeekCount - 1
        }
    }
}

// MARK: - Plan Builder View Model

final class PlanBuilderViewModel: ObservableObject {
    let athlete: User
    let coachId: String
    private let planService: WorkoutPlanService

    @Published var plan: WorkoutPlan?
    @Published var isLoading = false

    private var weekAnchorDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var maxExistingWeekOffset: Int {
        guard let plan else { return 0 }
        let calendar = Calendar.current
        return plan.days
            .map { weekOffset(for: $0.date, calendar: calendar) }
            .max() ?? 0
    }

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

    func addDay(inWeekOffset weekOffset: Int) {
        guard var p = plan else { return }
        let calendar = Calendar.current
        let start = weekStart(for: weekOffset, calendar: calendar)
        let existingDates = Set(
            p.days.map { calendar.startOfDay(for: $0.date) }
        )
        let preferredOffsets = [0, 2, 4, 1, 3, 5, 6]
        let chosenDate: Date = preferredOffsets
            .compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
            .first(where: { !existingDates.contains(calendar.startOfDay(for: $0)) })
            ?? (calendar.date(byAdding: .day, value: 6, to: start) ?? start)

        let defaults = defaultWorkoutInfo(for: p.days.count + 1)
        let newDay = WorkoutDay(
            id: UUID().uuidString,
            title: defaults.title,
            focus: defaults.focus,
            date: chosenDate,
            exercises: []
        )
        p.days.append(newDay)
        p.days.sort { $0.date < $1.date }
        updatePlan(p)
    }

    func updatePlan(_ p: WorkoutPlan) {
        plan = p
        Task {
            try? await planService.updatePlan(p)
        }
    }

    func deleteDay(at index: Int) {
        guard var p = plan, p.days.indices.contains(index) else { return }
        p.days.remove(at: index)
        updatePlan(p)
    }

    func daysForWeek(offset: Int) -> [(index: Int, day: WorkoutDay)] {
        guard let plan else { return [] }
        let calendar = Calendar.current
        return Array(plan.days.enumerated())
            .filter { weekOffset(for: $0.element.date, calendar: calendar) == offset }
            .map { (index: $0.offset, day: $0.element) }
            .sorted { $0.day.date < $1.day.date }
    }

    private func weekStart(for offset: Int, calendar: Calendar) -> Date {
        let todayStart = calendar.startOfDay(for: weekAnchorDate)
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: todayStart)) ?? todayStart
        return calendar.date(byAdding: .day, value: max(0, offset) * 7, to: currentWeekStart) ?? currentWeekStart
    }

    private func weekOffset(for date: Date, calendar: Calendar) -> Int {
        let start = weekStart(for: 0, calendar: calendar)
        let targetWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        let days = calendar.dateComponents([.day], from: start, to: targetWeekStart).day ?? 0
        return max(0, days / 7)
    }

    private func defaultWorkoutInfo(for number: Int) -> (title: String, focus: String) {
        let templates = [
            (String(localized: "workout_title_upper_body"), String(localized: "workout_focus_upper_body")),
            (String(localized: "workout_title_lower_body"), String(localized: "workout_focus_lower_body")),
            (String(localized: "workout_title_full_body"), String(localized: "workout_focus_full_body"))
        ]
        let template = templates[(number - 1) % templates.count]
        return (template.0, template.1)
    }
}

// MARK: - Workout Editor

struct WorkoutEditorView: View {
    let plan: WorkoutPlan
    let dayIndex: Int
    let planService: WorkoutPlanService
    let onSave: (WorkoutPlan) -> Void

    @State private var workoutDay: WorkoutDay
    @State private var workoutTitleInput: String
    @State private var titleSuggestions: [String] = []

    private let workoutTitleOptions: [String] = [
        String(localized: "workout_title_upper_body"),
        String(localized: "workout_title_lower_body"),
        String(localized: "workout_title_full_body"),
        String(localized: "workout_title_push"),
        String(localized: "workout_title_pull"),
        String(localized: "workout_title_legs"),
        String(localized: "workout_title_cardio"),
        String(localized: "workout_title_recovery")
    ]

    private let focusOptions: [String] = [
        String(localized: "workout_focus_chest_triceps"),
        String(localized: "workout_focus_back_biceps"),
        String(localized: "workout_focus_shoulders"),
        String(localized: "workout_focus_legs_glutes"),
        String(localized: "workout_focus_core"),
        String(localized: "workout_focus_full_body"),
        String(localized: "workout_focus_cardio"),
        String(localized: "workout_focus_mobility")
    ]

    init(plan: WorkoutPlan, dayIndex: Int, planService: WorkoutPlanService, onSave: @escaping (WorkoutPlan) -> Void) {
        self.plan = plan
        self.dayIndex = dayIndex
        self.planService = planService
        self.onSave = onSave
        let day = plan.days[dayIndex]
        _workoutDay = State(initialValue: day)
        _workoutTitleInput = State(initialValue: day.title)
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
                    title: String(localized: "workout_day_title"),
                    subtitle: String(localized: "workout_day_subtitle")
                )

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("workout_name_label")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                TextField(String(localized: "workout_name_placeholder"), text: $workoutTitleInput)
                                    .font(AppTypography.body)
                                    .padding(.vertical, AppSpacing.sm)
                                    .overlay(
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(AppColors.border.opacity(0.5)),
                                        alignment: .bottom
                                    )
                                    .onChange(of: workoutTitleInput) { _, newValue in
                                        workoutDay.title = newValue
                                        titleSuggestions = filteredWorkoutTitleSuggestions(for: newValue)
                                        onSave(updatedPlan)
                                    }

                                if !titleSuggestions.isEmpty {
                                    VStack(spacing: AppSpacing.xs) {
                                        ForEach(titleSuggestions, id: \.self) { suggestion in
                                            Button {
                                                workoutTitleInput = suggestion
                                                workoutDay.title = suggestion
                                                titleSuggestions = []
                                                onSave(updatedPlan)
                                                HapticManager.selection()
                                            } label: {
                                                HStack {
                                                    Text(suggestion)
                                                        .font(AppTypography.footnote)
                                                        .foregroundColor(AppColors.textPrimary)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                                        .fill(AppColors.backgroundElevated.opacity(0.6))
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("workout_focus_label")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                Menu {
                                    ForEach(focusOptions, id: \.self) { focus in
                                        Button(focus) {
                                            workoutDay.focus = focus
                                            onSave(updatedPlan)
                                            HapticManager.selection()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(workoutDay.focus.isEmpty ? String(localized: "workout_focus_placeholder") : workoutDay.focus)
                                            .font(AppTypography.body)
                                            .foregroundColor(workoutDay.focus.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding(.vertical, AppSpacing.sm)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                            .fill(AppColors.backgroundElevated.opacity(0.6))
                                    )
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("date_label")
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

                        SectionHeader(title: String(localized: "section_exercises"), actionTitle: String(localized: "button_add"), action: addExercise)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: AppSpacing.sm) {
                            ForEach(Array(workoutDay.exercises.enumerated()), id: \.element.id) { index, exercise in
                                HStack(spacing: AppSpacing.sm) {
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

                                    Button {
                                        deleteExercise(at: index)
                                        HapticManager.impact()
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(AppColors.danger)
                                            .frame(width: 38, height: 38)
                                            .background(
                                                Circle()
                                                    .fill(AppColors.danger.opacity(0.12))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text("button_delete_exercise"))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
                }

                NavigationLink {
                    SendUpdateView(plan: updatedPlan, planService: planService)
                } label: {
                    PrimaryActionButtonLabel(title: String(localized: "button_send_update"), icon: "paperplane.fill")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle(workoutDay.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            titleSuggestions = filteredWorkoutTitleSuggestions(for: workoutTitleInput)
        }
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
            notes: nil,
            tutorialURL: nil,
            category: .other,
            catalogId: nil
        )
        workoutDay.exercises.append(newEx)
        onSave(updatedPlan)
    }

    private func deleteExercise(at index: Int) {
        guard workoutDay.exercises.indices.contains(index) else { return }
        workoutDay.exercises.remove(at: index)
        onSave(updatedPlan)
    }

    private func filteredWorkoutTitleSuggestions(for query: String) -> [String] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return [] }
        let starts = workoutTitleOptions.filter { $0.lowercased().hasPrefix(normalized) }
        let contains = workoutTitleOptions.filter { $0.lowercased().contains(normalized) && !starts.contains($0) }
        return Array((starts + contains).prefix(5))
    }
}

// MARK: - Exercise Editor

struct ExerciseEditorView: View {
    let onSave: (Exercise) -> Void
    @State private var exercise: Exercise
    @State private var nameInput: String
    @State private var suggestions: [ExerciseCatalogItem] = []
    @State private var isNameExactMatch: Bool = true

    init(exercise: Exercise, onSave: @escaping (Exercise) -> Void) {
        self.onSave = onSave
        _exercise = State(initialValue: exercise)
        _nameInput = State(initialValue: exercise.name)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    SectionHeader(title: String(localized: "exercise_section_title"), subtitle: String(localized: "exercise_section_subtitle"))

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("edit_profile_name_label")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            TextField(String(localized: "placeholder_exercise_name"), text: $nameInput)
                                .font(AppTypography.body)
                                .textInputAutocapitalization(.sentences)
                                .padding(.vertical, AppSpacing.sm)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(AppColors.border.opacity(0.5)),
                                    alignment: .bottom
                                )
                                .onChange(of: nameInput) { _, newValue in
                                    exercise.name = newValue
                                    refreshSuggestions(for: newValue)
                                }
                            if !suggestions.isEmpty {
                                VStack(spacing: AppSpacing.xs) {
                                    ForEach(suggestions) { item in
                                        Button {
                                            applyCatalogItem(item)
                                            HapticManager.selection()
                                        } label: {
                                            HStack(spacing: AppSpacing.sm) {
                                                Image(systemName: item.category.icon)
                                                    .foregroundColor(AppColors.accent)
                                                Text(item.name)
                                                    .font(AppTypography.footnote)
                                                    .foregroundColor(AppColors.textPrimary)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                                    .fill(AppColors.backgroundElevated.opacity(0.6))
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            if !isNameExactMatch {
                                Text("exercise_name_not_exact_hint")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.warning)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("form_sets_reps")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)

                            HStack(spacing: AppSpacing.lg) {
                                CustomStepper(label: String(localized: "stepper_sets"), value: $exercise.sets, range: 1...10)
                                CustomStepper(label: String(localized: "stepper_reps"), value: $exercise.reps, range: 1...20)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("form_load_rest")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)

                            HStack(spacing: AppSpacing.lg) {
                                if exercise.requiresWeight {
                                    CustomStepper(label: String(localized: "stepper_weight_kg"), value: Binding(
                                        get: { Int(exercise.weight) },
                                        set: { exercise.weight = Double($0) }
                                    ), range: 0...300, step: 2)
                                } else {
                                    Text("exercise_weight_not_required")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                CustomStepper(label: String(localized: "stepper_rest_s"), value: $exercise.restSeconds, range: 30...300, step: 15)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("exercise_video_link_label")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            TextField(String(localized: "exercise_video_link_placeholder"), text: Binding(
                                get: { exercise.tutorialURL ?? "" },
                                set: { exercise.tutorialURL = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                            ))
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .font(AppTypography.body)
                            Text("exercise_video_link_optional_hint")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("form_notes")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            TextField(String(localized: "placeholder_coaching_notes"), text: Binding(
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
        .navigationTitle("nav_exercise")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshSuggestions(for: exercise.name)
        }
        .onDisappear { onSave(exercise) }
    }

    private func refreshSuggestions(for text: String) {
        suggestions = ExerciseCatalog.suggestions(for: text)
        if let exact = ExerciseCatalog.exactMatch(for: text) {
            isNameExactMatch = true
            applyCatalogItem(exact, updateInput: false)
        } else {
            isNameExactMatch = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if !isNameExactMatch {
                exercise.catalogId = nil
                exercise.category = .other
            }
        }
    }

    private func applyCatalogItem(_ item: ExerciseCatalogItem, updateInput: Bool = true) {
        exercise.name = item.name
        exercise.catalogId = item.id
        exercise.category = item.category
        if !exercise.requiresWeight {
            exercise.weight = 0
        }
        if updateInput {
            nameInput = item.name
            suggestions = []
        }
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
                Text(didSend ? String(localized: "update_sent") : String(localized: "button_send_update"))
                    .font(AppTypography.title2)
                Text("send_update_notify_message")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                Spacer()
                PrimaryButton(title: didSend ? String(localized: "button_done") : String(localized: "button_send_update_short")) {
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
    @EnvironmentObject private var appState: AppState
    @State private var requests: [CoachRequest] = []
    @State private var recentWorkoutLogs: [(athleteName: String, log: WorkoutLog)] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                athleteRequestsSection
                SectionHeader(
                    title: String(localized: "section_recent_updates"),
                    subtitle: String(localized: "recent_updates_subtitle")
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                recentWorkoutSummarySection
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("nav_updates")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadRequests()
            await loadRecentWorkoutSummaries()
        }
        .task {
            await loadRequests()
            await loadRecentWorkoutSummaries()
        }
    }

    private var athleteRequestsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("section_athlete_requests")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(AppSpacing.lg)
                    Spacer()
                }
            } else if requests.isEmpty {
                GlassCard(cornerRadius: AppTheme.Corners.md) {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.textMuted)
                        Text("no_athlete_requests")
                            .font(AppTypography.headline)
                        Text("no_athlete_requests_subtitle")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                }
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(requests) { req in
                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                if req.type == "workout_completed" {
                                    Text(String(format: String(localized: "athlete_completed_workout_title"), req.athleteName))
                                        .font(AppTypography.headline)
                                    Text(String(format: String(localized: "athlete_completed_workout_subtitle"), req.workoutTitle ?? "Workout", req.rating ?? 0))
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textSecondary)
                                } else {
                                    Text(String(format: String(localized: "athlete_request_workout_title"), req.athleteName))
                                        .font(AppTypography.headline)
                                    Text("athlete_request_workout_subtitle")
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Text(requestDateString(req.createdAt))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                        }
                    }
                }
            }
        }
    }

    private func requestDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private var recentWorkoutSummarySection: some View {
        Group {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, AppSpacing.md)
            } else if recentWorkoutLogs.isEmpty {
                GlassCard {
                    Text("coach_no_workout_summaries")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(recentWorkoutLogs.prefix(6).enumerated()), id: \.offset) { entry in
                        let item = entry.element
                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(item.athleteName)
                                    .font(AppTypography.headline)
                                Text(item.log.workoutTitle)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(String(format: String(localized: "coach_summary_overview_format"), item.log.totalSets, Int(item.log.totalVolume), item.log.rating))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textMuted)
                                if let note = item.log.exerciseFeedbacks.first(where: { ($0.note ?? "").isEmpty == false })?.note {
                                    Text(String(format: String(localized: "coach_summary_note_format"), note))
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.accentSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private func loadRequests() async {
        guard let coach = appState.currentUser, coach.role == .coach else { return }
        await MainActor.run { isLoading = true }
        do {
            let list = try await appState.coachRequestService.fetchRequests(coachId: coach.id)
            await MainActor.run { requests = list }
        } catch {
            await MainActor.run { requests = [] }
        }
        await MainActor.run { isLoading = false }
    }

    private func loadRecentWorkoutSummaries() async {
        guard let coach = appState.currentUser, coach.role == .coach else { return }
        do {
            let athletes = try await appState.userService.athletesForCoach(coachId: coach.id)
            var collected: [(athleteName: String, log: WorkoutLog)] = []
            for athlete in athletes {
                if let latest = (try await appState.logService.logsForAthlete(athleteId: athlete.id, limit: 1)).first {
                    collected.append((athleteName: athlete.name, log: latest))
                }
            }
            collected.sort { $0.log.date > $1.log.date }
            await MainActor.run {
                recentWorkoutLogs = collected
            }
        } catch {
            await MainActor.run {
                recentWorkoutLogs = []
            }
        }
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
                                Text("coach_edit_hint")
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
                SectionHeader(title: String(localized: "section_workspace"), actionTitle: nil, action: nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: AppSpacing.md) {
                    NavigationLink {
                        CoachInviteCodeView(coach: coach, inviteCodeService: appState.inviteCodeService)
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(AppColors.accent)
                            Text("generate_invite_code")
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
                    SecondaryButton(title: String(localized: "billing_subscription")) { }
                    SecondaryButton(title: String(localized: "export_data")) { }
                    SecondaryButton(title: String(localized: "sign_out")) {
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
        .navigationTitle("nav_profile")
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
                    Text("edit_profile_name_label")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    TextField(String(localized: "placeholder_your_name"), text: $name)
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
            .navigationTitle("edit_profile_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button_cancel")) { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button_save")) { save() }
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
    @State private var didCopyCode = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    SectionHeader(
                        title: String(localized: "invite_athletes_title"),
                        subtitle: String(localized: "invite_athletes_subtitle")
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let code = generatedCode, let expires = expiresAt {
                        GlassCard {
                            VStack(spacing: AppSpacing.lg) {
                                Text(code)
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .tracking(4)
                                Text(String(format: String(localized: "expires_format"), formattedExpiry(expires)))
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                SecondaryButton(
                                    title: didCopyCode
                                        ? String(localized: "button_copied")
                                        : String(localized: "button_copy_code")
                                ) {
                                    copyGeneratedCode(code)
                                }
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

                    PrimaryButton(title: generatedCode == nil ? String(localized: "button_generate_code") : String(localized: "button_generate_new_code")) {
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
        .navigationTitle("nav_invite_code_coach")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateCode() {
        guard !isGenerating else { return }
        isGenerating = true
        didCopyCode = false
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

    private func copyGeneratedCode(_ code: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = code
        #endif
        didCopyCode = true
        HapticManager.success()
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
                        userService: UserService(),
                        planService: WorkoutPlanService(),
                        logService: WorkoutLogService()
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
