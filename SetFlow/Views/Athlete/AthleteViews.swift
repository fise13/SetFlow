import SwiftUI
import Combine
import FirebaseFirestore
#if canImport(Charts)
import Charts
#endif

// MARK: - Athlete Tabs

enum AthleteTab: String, CaseIterable {
    case home
    case workout
    case progress
    case profile
    
    var title: String {
        switch self {
        case .home: return String(localized: "tab_home")
        case .workout: return String(localized: "tab_workout")
        case .progress: return String(localized: "tab_progress")
        case .profile: return String(localized: "tab_profile")
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .workout: return "figure.strengthtraining.traditional"
        case .progress: return "chart.bar.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

struct AthleteTabRootView: View {
    let user: User
    @ObservedObject var appState: AppState
    @ObservedObject private var prefs = AppPreferences.shared

    @StateObject private var homeViewModel: AthleteHomeViewModel
    @State private var selectedTab: AthleteTab = .home
    @State private var showFirstRunOnboarding = false
    @State private var didEvaluateOnboarding = false

    init(user: User, appState: AppState) {
        self.user = user
        self.appState = appState
        _homeViewModel = StateObject(wrappedValue: AthleteHomeViewModel(user: user, planService: appState.planService, logService: appState.logService))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AthleteHomeView(viewModel: homeViewModel)
            }
            .tabItem { Label(AthleteTab.home.title, systemImage: AthleteTab.home.systemImage) }
            .tag(AthleteTab.home)

            NavigationStack {
                workoutTabContent
            }
            .environment(\.popToHome) { selectedTab = .home }
            .tabItem { Label(AthleteTab.workout.title, systemImage: AthleteTab.workout.systemImage) }
            .tag(AthleteTab.workout)

            NavigationStack {
                AthleteProgressView(logs: homeViewModel.history)
            }
            .tabItem { Label(AthleteTab.progress.title, systemImage: AthleteTab.progress.systemImage) }
            .tag(AthleteTab.progress)

            NavigationStack {
                AthleteProfileSettingsView(user: user, appState: appState)
            }
            .tabItem { Label(AthleteTab.profile.title, systemImage: AthleteTab.profile.systemImage) }
            .tag(AthleteTab.profile)
        }
        .tabViewStyle(.automatic)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            homeViewModel.load()
            NotificationScheduler.shared.requestAuthorization { _ in }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .home { homeViewModel.load() }
        }
        .onChange(of: homeViewModel.isLoading) { _, isLoading in
            if !isLoading {
                evaluateFirstRunOnboardingIfNeeded()
            }
        }
        .fullScreenCover(isPresented: $showFirstRunOnboarding) {
            AthleteFirstRunOnboardingView {
                prefs.markFirstRunOnboardingSeen(role: .athlete, userId: user.id)
                showFirstRunOnboarding = false
            }
        }
    }

    @ViewBuilder
    private var workoutTabContent: some View {
        if let today = homeViewModel.todayWorkout, !homeViewModel.isWorkoutLoggedToday(today) {
            WorkoutDetailView(workoutDay: today, athleteId: user.id)
        } else {
            workoutTabEmptyView
        }
    }

    @ViewBuilder
    private var workoutTabEmptyView: some View {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let nextWorkout = homeViewModel.upcomingWorkouts.first { day in
            let dayStart = Calendar.current.startOfDay(for: day.date)
            if dayStart > todayStart { return true }
            if dayStart == todayStart { return !homeViewModel.isWorkoutLoggedToday(day) }
            return false
        }
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                GlassCard {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textMuted)
                        Text(homeViewModel.todayWorkout != nil ? "no_workout_left_today_title" : "no_workout_today_title")
                            .font(AppTypography.title2)
                        Text(homeViewModel.todayWorkout != nil ? "no_workout_left_today_message" : "no_workout_today_message")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        if let nextWorkout {
                            NavigationLink {
                                WorkoutDetailView(workoutDay: nextWorkout, athleteId: user.id)
                            } label: {
                                SecondaryButtonLabel(title: String(localized: "button_open_next_workout"), fullWidth: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.lg)
                Spacer()
            }
        }
        .navigationTitle("nav_workout")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func evaluateFirstRunOnboardingIfNeeded() {
        guard !didEvaluateOnboarding else { return }
        didEvaluateOnboarding = true
        let alreadySeen = prefs.hasSeenFirstRunOnboarding(role: .athlete, userId: user.id)
        guard !alreadySeen else { return }
        if homeViewModel.history.isEmpty {
            showFirstRunOnboarding = true
        } else {
            prefs.markFirstRunOnboardingSeen(role: .athlete, userId: user.id)
        }
    }
}

struct AthleteTabBar: View {
    @Binding var selectedTab: AthleteTab
    
    var body: some View {
        GlassCard(cornerRadius: AppTheme.Corners.xl) {
            HStack(spacing: AppSpacing.lg) {
                ForEach(AthleteTab.allCases, id: \.self) { tab in
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
                                .fill(
                                    selectedTab == tab
                                    ? AppColors.accent.opacity(0.1)
                                    : Color.clear
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
    }
}

// MARK: - Athlete Home

final class AthleteHomeViewModel: ObservableObject {
    let user: User
    private let planService: WorkoutPlanService
    private let logService: WorkoutLogService
    private var planListener: ListenerRegistration?
    private var logListener: ListenerRegistration?

    @Published var plans: [WorkoutPlan] = []
    @Published var upcomingWorkouts: [WorkoutDay] = []
    @Published var history: [WorkoutLog] = []
    @Published var isLoading: Bool = true

    init(user: User, planService: WorkoutPlanService, logService: WorkoutLogService) {
        self.user = user
        self.planService = planService
        self.logService = logService
    }

    deinit {
        planListener?.remove()
        logListener?.remove()
    }

    var todayWorkout: WorkoutDay? {
        let today = Calendar.current.startOfDay(for: Date())
        let todayDays = upcomingWorkouts.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        return todayDays.first(where: { !isWorkoutLoggedToday($0) }) ?? todayDays.first
    }

    /// Consecutive days with at least one workout, ending today or yesterday.
    var streakDays: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let workoutDays = Set(
            history
                .filter { $0.status != .missed }
                .map { cal.startOfDay(for: $0.date) }
        )
        var count = 0
        var d = today
        while workoutDays.contains(d) {
            count += 1
            guard let next = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = next
        }
        return count
    }

    /// Total volume (kg) for the current calendar week.
    var volumeThisWeek: Double {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return 0 }
        return history
            .filter { $0.status != .missed }
            .filter { cal.startOfDay(for: $0.date) >= weekStart }
            .reduce(0) { $0 + $1.totalVolume }
    }

    /// Title of the next planned workout after today, or "Rest".
    var nextWorkoutTitle: String {
        let today = Calendar.current.startOfDay(for: Date())
        let next = upcomingWorkouts.first { Calendar.current.startOfDay(for: $0.date) > today }
        return next?.title ?? "Rest"
    }

    /// Progress 0...1 for today's workout if it was logged, else 0.
    var todayProgress: Double {
        guard let today = todayWorkout else { return 0 }
        return isWorkoutLoggedToday(today) ? 1 : 0
    }

    @MainActor
    func load() {
        planListener?.remove()
        logListener?.remove()
        if plans.isEmpty && history.isEmpty {
            isLoading = true
        }
        planListener = planService.plansForAthleteListener(athleteId: user.id) { [weak self] plans in
            self?.plans = plans
            let upcoming = plans.flatMap { $0.days }.sorted { $0.date < $1.date }
            self?.upcomingWorkouts = upcoming
            let todayCandidates = upcoming.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
            if let today = todayCandidates.first(where: { !(self?.isWorkoutLoggedToday($0) ?? false) }) ?? todayCandidates.first {
                WatchConnectivityManager.shared.sendTodayWorkout(today)
                let prefs = AppPreferences.shared
                if prefs.notificationsEnabled {
                    NotificationScheduler.shared.scheduleWorkoutReminderIfNeeded(workoutTitle: today.title, workoutDate: today.date, reminderHour: prefs.reminderHour)
                } else {
                    NotificationScheduler.shared.cancelWorkoutReminders()
                }
            } else {
                NotificationScheduler.shared.cancelWorkoutReminders()
            }
            self?.isLoading = false
        }
        logListener = logService.logsForAthleteListener(athleteId: user.id) { [weak self] logs in
            self?.history = logs
        }
    }

    func isWorkoutLoggedToday(_ workout: WorkoutDay) -> Bool {
        let cal = Calendar.current
        let todayLogs = history.filter {
            cal.isDate($0.date, inSameDayAs: Date()) && $0.status != .missed
        }

        if let matchedById = todayLogs
            .filter({ $0.workoutDayId == workout.id })
            .max(by: { $0.date < $1.date }) {
            return !isPlanUpdated(after: matchedById.date, for: workout)
        }

        if let legacyMatch = todayLogs
            .filter({ $0.workoutDayId == nil && $0.workoutTitle == workout.title })
            .max(by: { $0.date < $1.date }) {
            return !isPlanUpdated(after: legacyMatch.date, for: workout)
        }

        return false
    }

    private func isPlanUpdated(after logDate: Date, for workout: WorkoutDay) -> Bool {
        let byId = plans.first { plan in
            plan.days.contains(where: { $0.id == workout.id })
        }?.lastUpdatedAt

        let byLegacyMatch = plans.first { plan in
            plan.days.contains {
                Calendar.current.isDate($0.date, inSameDayAs: workout.date) && $0.title == workout.title
            }
        }?.lastUpdatedAt

        guard let updatedAt = byId ?? byLegacyMatch else { return false }
        return updatedAt > logDate
    }
}

struct AthleteHomeView: View {
    @ObservedObject var viewModel: AthleteHomeViewModel
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    AppColors.background,
                    AppColors.backgroundElevated
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                homeSkeleton
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        header
                        todayHero
                        weeklyStrip
                        quickStats
                        recentWorkouts
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("today")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    HistoryView(logs: viewModel.history)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
    }
    
    private var homeSkeleton: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    SkeletonBar(width: 180, height: 28)
                    SkeletonBar(width: 240, height: 14)
                }
                .padding(.horizontal, AppSpacing.lg)
                
                GlassCard(cornerRadius: AppTheme.Corners.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SkeletonBar(width: 160, height: 18)
                        SkeletonBar(width: 240, height: 12)
                        SkeletonBar(width: 120, height: 12)
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
                .padding(.horizontal, AppSpacing.lg)
                
                HStack(spacing: AppSpacing.md) {
                    SkeletonCard()
                    SkeletonCard()
                }
                .padding(.horizontal, AppSpacing.lg)
                
                SkeletonCard()
                    .padding(.horizontal, AppSpacing.lg)
                SkeletonCard()
                    .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Hi, \(viewModel.user.name.split(separator: " ").first ?? "Athlete")")
                .font(AppTypography.title1)
            Text("home_greeting_subtitle")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private var todayHero: some View {
        Group {
            if let today = viewModel.todayWorkout {
                if viewModel.isWorkoutLoggedToday(today) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("no_workout_left_today_title")
                                .font(AppTypography.headline)
                            Text("no_workout_left_today_message")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                } else {
                    WorkoutHeroCard(
                        title: today.title,
                        subtitle: String(format: String(localized: "today_focus_format"), today.focus.isEmpty ? String(localized: "workout_focus_not_set") : today.focus),
                        detail: "\(today.exercises.count) exercises",
                        progress: viewModel.todayProgress
                    )
                    .padding(.horizontal, AppSpacing.lg)
                }
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("no_workout_today")
                            .font(AppTypography.headline)
                        Text("no_workout_today_desc")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
    
    private var weeklyStrip: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: String(localized: "section_this_week"), actionTitle: nil, action: nil)
            WeeklyCalendarStrip(
                selectedDate: $selectedDate,
                markedDates: viewModel.upcomingWorkouts.map(\.date)
            )
            selectedDayWorkoutCard
        }
    }

    private var selectedDayWorkoutCard: some View {
        let selectedWorkout = viewModel.upcomingWorkouts.first {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
        return Group {
            if let workout = selectedWorkout {
                GlassCard(cornerRadius: AppTheme.Corners.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.title)
                                .font(AppTypography.headline)
                            Text(workout.focus.isEmpty ? String(localized: "workout_focus_not_set") : workout.focus)
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Text(String(format: String(localized: "exercises_count_format"), workout.exercises.count))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            } else {
                GlassCard(cornerRadius: AppTheme.Corners.md) {
                    Text("no_workout_selected_day")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
    
    private var quickStats: some View {
        let volume = prefs.displayVolume(kg: viewModel.volumeThisWeek)
        let streak = viewModel.streakDays == 0 ? "0" : "\(viewModel.streakDays)"
        let streakSubtitle = viewModel.streakDays == 1 ? "day" : "days"
        
        return HStack(spacing: AppSpacing.md) {
            AthleteStatTile(title: String(localized: "stat_streak"), value: streak, subtitle: streakSubtitle + " " + String(localized: "in_a_row"), icon: "flame.fill")
            AthleteStatTile(title: String(localized: "stat_volume"), value: volume, subtitle: String(localized: "this_week"), icon: "chart.bar.fill")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.sm)
        .overlay(
            HStack {
                Spacer()
                AthleteStatTile(title: String(localized: "stat_next"), value: viewModel.nextWorkoutTitle, subtitle: String(localized: "planned"), icon: "calendar.badge.clock")
                    .frame(width: 170)
            }
            .padding(.trailing, AppSpacing.lg),
            alignment: .bottom
        )
    }
    
    private var recentWorkouts: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text("section_recent")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                NavigationLink {
                    HistoryView(logs: viewModel.history)
                } label: {
                    Text("see_all")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.accentSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            
            if viewModel.history.isEmpty {
                GlassCard(cornerRadius: AppTheme.Corners.md) {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.textMuted)
                        Text("no_workouts_yet")
                            .font(AppTypography.headline)
                        Text("no_workouts_yet_desc")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.lg)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(viewModel.history.prefix(3))) { log in
                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(log.workoutTitle)
                                        .font(AppTypography.body.weight(.semibold))
                                    Text(dateString(log.date))
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    if log.status == .missed {
                                        Text("workout_status_missed")
                                            .font(AppTypography.footnote)
                                            .foregroundColor(AppColors.warning)
                                    } else {
                                        Text(String(format: String(localized: "duration_min_format"), log.durationMinutes))
                                            .font(AppTypography.footnote)
                                            .foregroundColor(AppColors.textSecondary)
                                        Text(String(repeating: "★", count: log.rating))
                                            .font(AppTypography.footnote)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AthleteFirstRunOnboardingView: View {
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.16), Color(red: 0.03, green: 0.13, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.white.opacity(0.14)))
                
                VStack(spacing: AppSpacing.md) {
                    Text("first_run_athlete_title")
                        .font(AppTypography.title1)
                        .foregroundColor(.white)
                    Text("first_run_athlete_message")
                        .font(AppTypography.body)
                        .foregroundColor(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                Spacer()
                PrimaryActionButton(title: String(localized: "first_run_athlete_action")) {
                    onContinue()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }
}

// MARK: - Workout Detail

struct WorkoutDetailView: View {
    let workoutDay: WorkoutDay
    var athleteId: String
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showAllExercises = false
    @State private var showRescheduleSheet = false
    @State private var showMakeupSheet = false
    @State private var selectedScheduleDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var isApplyingSchedule = false
    /// True when this workout was already completed today — no re-entry until coach adds/updates plan.
    @State private var isCompletedLock = false

    private var totalSets: Int {
        workoutDay.exercises.reduce(0) { $0 + $1.sets }
    }

    /// Rough estimate: ~2.5 min per set (work + rest).
    private var estimatedMinutes: Int {
        max(5, Int(Double(totalSets) * 2.5))
    }

    private var canStart: Bool {
        !workoutDay.exercises.isEmpty && !isCompletedLock
    }

    private var isToday: Bool {
        Calendar.current.isDate(workoutDay.date, inSameDayAs: Date())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if isCompletedLock {
                        completedLockBlock
                    }
                    preflightBlock
                    if !isCompletedLock {
                        schedulingBlock
                    }
                    if !workoutDay.exercises.isEmpty && !isCompletedLock {
                        SectionHeader(title: String(localized: "section_exercises"), actionTitle: nil, action: nil)
                        exercisesList
                    }
                    Spacer(minLength: 100)
                }
                .padding(.vertical, AppSpacing.lg)
            }
            if !isCompletedLock {
                startButtonOverlay
            }
        }
        .navigationTitle("nav_workout")
        .onAppear { checkCompletedLock() }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAllExercises) {
            NavigationStack {
                allExercisesSheet
            }
        }
        .sheet(isPresented: $showRescheduleSheet) {
            scheduleSheet(
                title: String(localized: "schedule_reschedule_title"),
                confirmTitle: String(localized: "schedule_reschedule_confirm"),
                action: { performReschedule(to: selectedScheduleDate) }
            )
        }
        .sheet(isPresented: $showMakeupSheet) {
            scheduleSheet(
                title: String(localized: "schedule_makeup_title"),
                confirmTitle: String(localized: "schedule_makeup_confirm"),
                action: { createMakeupSession(on: selectedScheduleDate) }
            )
        }
    }

    private var completedLockBlock: some View {
        GlassCard(cornerRadius: AppTheme.Corners.lg) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.success)
                Text("workout_completed_lock_title")
                    .font(AppTypography.title2)
                Text("workout_completed_lock_message")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func checkCompletedLock() {
        guard isToday else { return }
        Task {
            let logs = (try? await appState.logService.logsForAthlete(athleteId: athleteId, limit: 14)) ?? []
            let plans = (try? await appState.planService.plansForAthlete(athleteId: athleteId)) ?? []
            let cal = Calendar.current
            let todayLogs = logs.filter {
                cal.isDate($0.date, inSameDayAs: Date()) && $0.status != .missed
            }

            let matchedById = todayLogs
                .filter { $0.workoutDayId == workoutDay.id }
                .max(by: { $0.date < $1.date })

            let legacyMatch = todayLogs
                .filter { $0.workoutDayId == nil && $0.workoutTitle == workoutDay.title }
                .max(by: { $0.date < $1.date })

            let latest = matchedById ?? legacyMatch
            let planUpdate = plans.first {
                $0.days.contains(where: { $0.id == workoutDay.id })
            }?.lastUpdatedAt

            let found: Bool
            if let latest {
                if let planUpdate, planUpdate > latest.date {
                    found = false
                } else {
                    found = true
                }
            } else {
                found = false
            }
            await MainActor.run { isCompletedLock = found }
        }
    }

    private var preflightBlock: some View {
        GlassCard(cornerRadius: AppTheme.Corners.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(workoutDay.title)
                    .font(AppTypography.title2)
                Text(workoutDay.focus)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                HStack(spacing: AppSpacing.lg) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 12))
                        Text(String(format: String(localized: "preflight_sets_format"), totalSets))
                            .font(AppTypography.footnote)
                    }
                    .foregroundColor(AppColors.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(String(format: String(localized: "preflight_est_duration"), estimatedMinutes))
                            .font(AppTypography.footnote)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                if !workoutDay.exercises.isEmpty {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(workoutDay.exercises.prefix(4)) { exercise in
                            HStack(spacing: 4) {
                                Image(systemName: exercise.iconName)
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColors.accent.opacity(0.9))
                                Text(exercise.name)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppColors.accent.opacity(0.1)))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var exercisesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(workoutDay.exercises.prefix(3))) { exercise in
                exerciseRowWithVideo(exercise)
                Divider()
            }
            if workoutDay.exercises.count > 3 {
                Button {
                    showAllExercises = true
                } label: {
                    Text("button_view_all_exercises")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.accentSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var schedulingBlock: some View {
        GlassCard(cornerRadius: AppTheme.Corners.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("schedule_section_title")
                    .font(AppTypography.headline)
                Text("schedule_section_subtitle")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: AppSpacing.sm) {
                    SecondaryButton(title: String(localized: "schedule_reschedule_cta"), fullWidth: true) {
                        selectedScheduleDate = Calendar.current.date(byAdding: .day, value: 1, to: workoutDay.date) ?? Date()
                        showRescheduleSheet = true
                    }
                    SecondaryButton(title: String(localized: "schedule_makeup_cta"), fullWidth: true) {
                        selectedScheduleDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        showMakeupSheet = true
                    }
                }

                Button {
                    markWorkoutMissed()
                } label: {
                    Text("schedule_mark_missed")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .disabled(isApplyingSchedule)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func scheduleSheet(title: String, confirmTitle: String, action: @escaping () -> Void) -> some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: AppSpacing.lg) {
                    DatePicker(
                        "",
                        selection: $selectedScheduleDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                    PrimaryButton(title: confirmTitle) {
                        action()
                    }
                    .disabled(isApplyingSchedule)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button_cancel")) {
                        showRescheduleSheet = false
                        showMakeupSheet = false
                    }
                }
            }
        }
    }

    private func performReschedule(to date: Date) {
        isApplyingSchedule = true
        Task {
            await updatePlanDayDate(date)
            await MainActor.run {
                isApplyingSchedule = false
                showRescheduleSheet = false
                dismiss()
            }
        }
    }

    private func createMakeupSession(on date: Date) {
        isApplyingSchedule = true
        Task {
            do {
                let plans = try await appState.planService.plansForAthlete(athleteId: athleteId)
                guard var plan = plans.first else { return }
                let newDay = WorkoutDay(
                    id: UUID().uuidString,
                    title: "\(workoutDay.title) • \(String(localized: "schedule_makeup_suffix"))",
                    focus: workoutDay.focus,
                    date: Calendar.current.startOfDay(for: date),
                    exercises: workoutDay.exercises
                )
                plan.days.append(newDay)
                plan.days.sort { $0.date < $1.date }
                try await appState.planService.updatePlan(plan)
            } catch { }
            await MainActor.run {
                isApplyingSchedule = false
                showMakeupSheet = false
                dismiss()
            }
        }
    }

    private func markWorkoutMissed() {
        isApplyingSchedule = true
        Task {
            let missedLog = WorkoutLog(
                id: "temp-\(UUID().uuidString)",
                athleteId: athleteId,
                workoutTitle: workoutDay.title,
                workoutDayId: workoutDay.id,
                date: Date(),
                durationMinutes: 0,
                totalSets: 0,
                totalVolume: 0,
                rating: 0,
                exerciseFeedbacks: [],
                status: .missed
            )
            try? await appState.logService.saveLog(missedLog)
            await MainActor.run {
                isApplyingSchedule = false
                dismiss()
            }
        }
    }

    private func updatePlanDayDate(_ date: Date) async {
        do {
            let plans = try await appState.planService.plansForAthlete(athleteId: athleteId)
            guard var plan = plans.first,
                  let index = plan.days.firstIndex(where: { $0.id == workoutDay.id }) else { return }
            plan.days[index].date = Calendar.current.startOfDay(for: date)
            plan.days.sort { $0.date < $1.date }
            try await appState.planService.updatePlan(plan)
        } catch { }
    }

    private var allExercisesSheet: some View {
        List {
            ForEach(workoutDay.exercises) { exercise in
                exerciseRowWithVideo(exercise)
            }
        }
        .navigationTitle(workoutDay.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func exerciseRowWithVideo(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ExerciseRow(exercise: exercise, weightDisplay: AppPreferences.shared.displayWeight(kg: exercise.weight))
            if let tutorialURL = exercise.tutorialURL,
               let url = URL(string: tutorialURL),
               !tutorialURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                        Text("exercise_watch_technique")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.accentSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var startButtonOverlay: some View {
        VStack {
            Spacer()
            Group {
                if canStart {
                    NavigationLink {
                        LiveWorkoutView(workoutDay: workoutDay, athleteId: athleteId)
                    } label: {
                        PrimaryActionButtonLabel(title: String(localized: "button_start_workout"), icon: "play.fill")
                    }
                    .buttonStyle(.plain)
                } else {
                    GlassCard(cornerRadius: AppTheme.Corners.lg) {
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.warning)
                            Text("no_exercises_cant_start")
                                .font(AppTypography.headline)
                            Text("no_exercises_cant_start_desc")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.lg)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }
}

// MARK: - Live Workout

typealias LiveActivityCallback = () -> Void

final class LiveWorkoutViewModel: ObservableObject {
    @Published var currentExerciseIndex: Int = 0
    @Published var currentSet: Int = 1
    @Published var isResting: Bool = false
    @Published var restRemaining: Int = 60
    @Published var restTotalSeconds: Int = 60
    @Published var completedSetsCount: Int = 0
    @Published var totalVolume: Double = 0
    @Published var workoutStartTime: Date = Date()
    
    private var restTimer: Timer?
    private var restIsBetweenExercisesInternal: Bool = false
    private var restEndsAt: Date?
    
    let workoutDay: WorkoutDay

    /// Callbacks for Live Activity updates. Set by LiveWorkoutView.
    var onSetDone: LiveActivityCallback?
    var onExerciseChange: LiveActivityCallback?
    var onRestUpdate: LiveActivityCallback?
    var onComplete: LiveActivityCallback?
    var onEnd: LiveActivityCallback?
    
    init(workoutDay: WorkoutDay) {
        self.workoutDay = workoutDay
        restorePersistedStateIfAvailable()
    }
    
    var currentExercise: Exercise? {
        guard currentExerciseIndex < workoutDay.exercises.count else { return nil }
        return workoutDay.exercises[currentExerciseIndex]
    }
    
    var progress: Double {
        let totalSets = workoutDay.exercises.reduce(0) { $0 + $1.sets }
        return totalSets == 0 ? 0 : Double(completedSetsCount) / Double(totalSets)
    }
    
    var isWorkoutComplete: Bool {
        currentExerciseIndex >= workoutDay.exercises.count
    }

    var restIsBetweenExercises: Bool {
        restIsBetweenExercisesInternal
    }

    var totalSetsCount: Int {
        workoutDay.exercises.reduce(0) { $0 + $1.sets }
    }

    var setsRemaining: Int {
        totalSetsCount - completedSetsCount
    }

    var nextExerciseName: String? {
        let nextIndex = currentExerciseIndex + 1
        guard workoutDay.exercises.indices.contains(nextIndex) else { return nil }
        return workoutDay.exercises[nextIndex].name
    }
    
    @MainActor
    func doneSet() {
        guard let ex = currentExercise else { return }
        HapticManager.impact()
        completedSetsCount += 1
        if ex.requiresWeight {
            totalVolume += ex.weight * Double(ex.reps)
        }
        if currentSet >= ex.sets {
            if currentExerciseIndex + 1 < workoutDay.exercises.count {
                restIsBetweenExercisesInternal = true
                startRest(afterRest: { [weak self] in self?.advanceToNextExercise() })
            } else {
                currentExerciseIndex += 1
                clearPersistedState()
                onComplete?()
            }
        } else {
            currentSet += 1
            restIsBetweenExercisesInternal = false
            startRest(afterRest: { })
        }
        savePersistedState()
    }
    
    @MainActor
    private func startRest(afterRest: @escaping () -> Void) {
        guard let ex = currentExercise else {
            isResting = false
            restEndsAt = nil
            savePersistedState()
            afterRest()
            return
        }
        isResting = true
        restRemaining = ex.restSeconds
        restTotalSeconds = ex.restSeconds
        restEndsAt = Date().addingTimeInterval(TimeInterval(restRemaining))
        onSetDone?()
        startRestTimer(afterRest: afterRest)
        savePersistedState()
    }
    
    @MainActor
    private func tickRest(afterRest: @escaping () -> Void) {
        if let end = restEndsAt {
            restRemaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
        } else {
            restRemaining = max(0, restRemaining - 1)
        }
        onRestUpdate?()
        if restRemaining <= 3, restRemaining > 0 {
            HapticManager.countdownWarning()
            HapticManager.playCountdownTickSound()
        }
        if restRemaining <= 0 {
            restTimer?.invalidate()
            restTimer = nil
            isResting = false
            restEndsAt = nil
            HapticManager.success()
            HapticManager.playCountdownEndSound()
            afterRest()
        }
        savePersistedState()
    }
    
    @MainActor
    func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restRemaining = 0
        restEndsAt = nil
        if restIsBetweenExercisesInternal {
            advanceToNextExercise()
        } else {
            onSetDone?()
        }
        savePersistedState()
    }

    @MainActor
    func addRestSeconds(_ seconds: Int) {
        guard isResting else { return }
        restRemaining = min(300, restRemaining + seconds)
        restTotalSeconds = min(300, restTotalSeconds + seconds)
        restEndsAt = Date().addingTimeInterval(TimeInterval(restRemaining))
        onRestUpdate?()
        savePersistedState()
    }
    
    @MainActor
    private func advanceToNextExercise() {
        currentExerciseIndex += 1
        currentSet = 1
        onExerciseChange?()
        savePersistedState()
    }
    
    func buildLog(athleteId: String) -> WorkoutLog {
        let durationMinutes = max(1, Int(Date().timeIntervalSince(workoutStartTime) / 60))
        let feedbacks = workoutDay.exercises.map {
            ExerciseFeedback(
                id: $0.id,
                exerciseName: $0.name,
                difficulty: 3,
                note: nil
            )
        }
        return WorkoutLog(
            id: "temp-\(UUID().uuidString)",
            athleteId: athleteId,
            workoutTitle: workoutDay.title,
            workoutDayId: workoutDay.id,
            date: Date(),
            durationMinutes: durationMinutes,
            totalSets: completedSetsCount,
            totalVolume: totalVolume,
            rating: 5,
            exerciseFeedbacks: feedbacks
        )
    }

    @MainActor
    func resumeIfNeeded() {
        guard isResting else {
            return
        }
        if restEndsAt == nil, restRemaining > 0 {
            restEndsAt = Date().addingTimeInterval(TimeInterval(restRemaining))
        }
        let afterRest: () -> Void = { [weak self] in
            guard let self else { return }
            if self.restIsBetweenExercisesInternal {
                self.advanceToNextExercise()
            } else {
                self.onSetDone?()
            }
        }
        startRestTimer(afterRest: afterRest)
        tickRest(afterRest: afterRest)
    }

    @MainActor
    func syncRestStateWithClock() {
        guard isResting else { return }
        if let end = restEndsAt {
            restRemaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            if restRemaining <= 0 {
                isResting = false
                restTimer?.invalidate()
                restTimer = nil
                restEndsAt = nil
                if restIsBetweenExercisesInternal {
                    advanceToNextExercise()
                } else {
                    onSetDone?()
                }
            } else {
                onRestUpdate?()
            }
        }
        savePersistedState()
    }

    static func clearPersistedState(for workoutDayId: String?) {
        guard let workoutDayId, !workoutDayId.isEmpty else { return }
        UserDefaults.standard.removeObject(forKey: persistedKey(for: workoutDayId))
    }

    // MARK: - Persistence

    private struct PersistedLiveState: Codable {
        let workoutDayId: String
        let currentExerciseIndex: Int
        let currentSet: Int
        let isResting: Bool
        let restRemaining: Int
        let restTotalSeconds: Int
        let restIsBetweenExercises: Bool
        let restEndsAt: Date?
        let completedSetsCount: Int
        let totalVolume: Double
        let workoutStartTime: Date
    }

    private static func persistedKey(for workoutDayId: String) -> String {
        "liveWorkout.state.\(workoutDayId)"
    }

    private func savePersistedState() {
        let state = PersistedLiveState(
            workoutDayId: workoutDay.id,
            currentExerciseIndex: currentExerciseIndex,
            currentSet: currentSet,
            isResting: isResting,
            restRemaining: restRemaining,
            restTotalSeconds: restTotalSeconds,
            restIsBetweenExercises: restIsBetweenExercisesInternal,
            restEndsAt: restEndsAt,
            completedSetsCount: completedSetsCount,
            totalVolume: totalVolume,
            workoutStartTime: workoutStartTime
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.persistedKey(for: workoutDay.id))
        }
    }

    private func restorePersistedStateIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistedKey(for: workoutDay.id)),
              let state = try? JSONDecoder().decode(PersistedLiveState.self, from: data) else { return }
        currentExerciseIndex = min(max(0, state.currentExerciseIndex), max(0, workoutDay.exercises.count - 1))
        currentSet = max(1, state.currentSet)
        isResting = state.isResting
        restRemaining = max(0, state.restRemaining)
        restTotalSeconds = max(0, state.restTotalSeconds)
        restIsBetweenExercisesInternal = state.restIsBetweenExercises
        restEndsAt = state.restEndsAt
        completedSetsCount = max(0, state.completedSetsCount)
        totalVolume = max(0, state.totalVolume)
        workoutStartTime = state.workoutStartTime
    }

    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: Self.persistedKey(for: workoutDay.id))
    }

    @MainActor
    private func startRestTimer(afterRest: @escaping () -> Void) {
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickRest(afterRest: afterRest)
            }
        }
        if let restTimer {
            RunLoop.main.add(restTimer, forMode: .common)
        }
    }
}

struct LiveWorkoutView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @ObservedObject private var prefs = AppPreferences.shared
    @Environment(\.scenePhase) private var scenePhase
    let athleteId: String
    @State private var showSummary = false
    @State private var showEndWorkoutConfirmation = false

    init(workoutDay: WorkoutDay, athleteId: String) {
        self.viewModel = LiveWorkoutViewModel(workoutDay: workoutDay)
        self.athleteId = athleteId
    }

    private func startLiveActivityIfNeeded() {
        if #available(iOS 16.2, *) {
            guard let ex = viewModel.currentExercise else { return }
            WorkoutLiveActivityService.start(
                workoutTitle: viewModel.workoutDay.title,
                totalSets: viewModel.totalSetsCount,
                currentExerciseName: ex.name,
                currentExerciseIndex: viewModel.currentExerciseIndex + 1,
                totalExercises: viewModel.workoutDay.exercises.count,
                currentSet: viewModel.currentSet,
                setsForCurrentExercise: ex.sets,
                repsForCurrentExercise: ex.reps,
                weightForCurrentExercise: ex.weight,
                requiresWeight: ex.requiresWeight,
                nextExerciseName: viewModel.nextExerciseName,
                completedSetsCount: viewModel.completedSetsCount,
                restTotalSeconds: viewModel.restTotalSeconds,
                totalVolume: viewModel.totalVolume
            )
        }
    }

    private func updateLiveActivitySetDone() {
        if #available(iOS 16.2, *) {
            guard let ex = viewModel.currentExercise else { return }
            WorkoutLiveActivityService.updateForSetDone(
                currentExerciseName: ex.name,
                currentExerciseIndex: viewModel.currentExerciseIndex + 1,
                totalExercises: viewModel.workoutDay.exercises.count,
                currentSet: viewModel.currentSet,
                setsForCurrentExercise: ex.sets,
                repsForCurrentExercise: ex.reps,
                weightForCurrentExercise: ex.weight,
                requiresWeight: ex.requiresWeight,
                nextExerciseName: viewModel.nextExerciseName,
                completedSetsCount: viewModel.completedSetsCount,
                totalSetsCount: viewModel.totalSetsCount,
                restRemaining: viewModel.restRemaining,
                restTotalSeconds: viewModel.restTotalSeconds,
                totalVolume: viewModel.totalVolume
            )
        }
    }

    private func updateLiveActivityExerciseChange() {
        if #available(iOS 16.2, *) {
            guard let ex = viewModel.currentExercise else { return }
            WorkoutLiveActivityService.updateForExerciseChange(
                currentExerciseName: ex.name,
                currentExerciseIndex: viewModel.currentExerciseIndex + 1,
                totalExercises: viewModel.workoutDay.exercises.count,
                currentSet: viewModel.currentSet,
                setsForCurrentExercise: ex.sets,
                repsForCurrentExercise: ex.reps,
                weightForCurrentExercise: ex.weight,
                requiresWeight: ex.requiresWeight,
                nextExerciseName: viewModel.nextExerciseName,
                completedSetsCount: viewModel.completedSetsCount,
                totalSetsCount: viewModel.totalSetsCount,
                restRemaining: viewModel.restRemaining,
                restTotalSeconds: viewModel.restTotalSeconds,
                totalVolume: viewModel.totalVolume
            )
        }
    }

    private func updateLiveActivityRest() {
        if #available(iOS 16.2, *) {
            guard let ex = viewModel.currentExercise else { return }
            WorkoutLiveActivityService.updateRest(
                currentExerciseName: ex.name,
                currentExerciseIndex: viewModel.currentExerciseIndex + 1,
                totalExercises: viewModel.workoutDay.exercises.count,
                currentSet: viewModel.currentSet,
                setsForCurrentExercise: ex.sets,
                repsForCurrentExercise: ex.reps,
                weightForCurrentExercise: ex.weight,
                requiresWeight: ex.requiresWeight,
                nextExerciseName: viewModel.nextExerciseName,
                completedSetsCount: viewModel.completedSetsCount,
                totalSetsCount: viewModel.totalSetsCount,
                restRemaining: viewModel.restRemaining,
                restTotalSeconds: viewModel.restTotalSeconds,
                totalVolume: viewModel.totalVolume
            )
        }
    }

    private func completeLiveActivity() {
        if #available(iOS 16.2, *) {
            WorkoutLiveActivityService.complete(
                completedSetsCount: viewModel.completedSetsCount,
                totalSetsCount: viewModel.totalSetsCount,
                totalVolume: viewModel.totalVolume
            )
        }
    }

    private func endLiveActivityIfNeeded() {
        if #available(iOS 16.2, *) {
            WorkoutLiveActivityService.endIfNeeded()
        }
    }

    private func syncLiveActivityCurrentState() {
        if viewModel.isResting {
            updateLiveActivityRest()
        } else if viewModel.isWorkoutComplete {
            completeLiveActivity()
        } else {
            updateLiveActivityExerciseChange()
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if !viewModel.isWorkoutComplete {
                    liveStatusBar
                }
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        if viewModel.isWorkoutComplete {
                            workoutCompleteView
                        } else if let ex = viewModel.currentExercise {
                            exerciseContent(ex: ex)
                            if viewModel.isResting {
                                restSection(ex: ex)
                            }
                            actionButtons(ex: ex)
                        } else {
                            Text("no_exercises")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.top, AppSpacing.xxl)
                        }

                        if !viewModel.isWorkoutComplete && viewModel.completedSetsCount > 0 {
                            Button {
                                showEndWorkoutConfirmation = true
                            } label: {
                                Text("button_end_workout_early")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.vertical, AppSpacing.sm)
                            }
                            .padding(.bottom, AppSpacing.lg)
                        }
                    }
                }
            }
        }
        .navigationTitle("nav_live")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onSetDone = updateLiveActivitySetDone
            viewModel.onExerciseChange = updateLiveActivityExerciseChange
            viewModel.onRestUpdate = updateLiveActivityRest
            viewModel.onComplete = completeLiveActivity
            viewModel.resumeIfNeeded()
            startLiveActivityIfNeeded()
            syncLiveActivityCurrentState()
        }
        .onDisappear {
            viewModel.onSetDone = nil
            viewModel.onExerciseChange = nil
            viewModel.onRestUpdate = nil
            viewModel.onComplete = nil
            endLiveActivityIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.syncRestStateWithClock()
                syncLiveActivityCurrentState()
            }
            // Do not end Live Activity on .background — it should stay in Dynamic Island / Lock Screen
        }
        .navigationDestination(isPresented: $showSummary) {
            WorkoutSummaryView(log: viewModel.buildLog(athleteId: athleteId))
        }
        .confirmationDialog(String(localized: "end_workout_confirm_title"), isPresented: $showEndWorkoutConfirmation) {
            Button(String(localized: "button_end_workout_early"), role: .destructive) {
                completeLiveActivity()
                showSummary = true
            }
            Button(String(localized: "button_cancel"), role: .cancel) { }
        } message: {
            Text(String(format: String(localized: "end_workout_confirm_message"), viewModel.completedSetsCount))
        }
    }

    private var liveStatusBar: some View {
        GlassCard(cornerRadius: AppTheme.Corners.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.completedSetsCount)/\(viewModel.totalSetsCount)")
                        .font(AppTypography.headline)
                    Text("live_stat_sets")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text(String(format: String(localized: "exercise_progress_format"), viewModel.currentExerciseIndex + 1, viewModel.workoutDay.exercises.count))
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.setsRemaining)")
                        .font(AppTypography.headline)
                    Text("live_stat_remaining")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(width: 60, alignment: .trailing)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }

    private func exerciseContent(ex: Exercise) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Text(viewModel.workoutDay.title)
                .font(AppTypography.headline)
                .padding(.top, AppSpacing.lg)
            CardView {
                VStack(spacing: AppSpacing.lg) {
                    Text(ex.name)
                        .font(AppTypography.title2)
                    Text(exercisePrescriptionText(ex))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    ZStack {
                        Circle()
                            .stroke(AppColors.progressBackground, lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.progress))
                            .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                        VStack {
                            Text(String(format: String(localized: "set_progress_format"), viewModel.currentSet, ex.sets))
                                .font(AppTypography.headline)
                            Text("\(Int(viewModel.progress * 100))%")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func exercisePrescriptionText(_ exercise: Exercise) -> String {
        if exercise.requiresWeight {
            return "\(exercise.sets)x\(exercise.reps)  •  \(prefs.displayWeight(kg: exercise.weight))"
        }
        return "\(exercise.sets)x\(exercise.reps)"
    }

    private func restSection(ex: Exercise) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text(viewModel.restIsBetweenExercises ? String(localized: "rest_between_exercises") : String(localized: "rest_between_sets"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.accent)
                .textCase(.uppercase)
            Text(String(format: String(localized: "rest_seconds_format"), viewModel.restRemaining))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .monospacedDigit()
            CustomProgressBar(progress: Double(viewModel.restRemaining) / Double(max(1, ex.restSeconds)))
                .frame(height: 8)
                .padding(.horizontal, AppSpacing.xl)
            HStack(spacing: AppSpacing.md) {
                SecondaryButton(title: String(localized: "button_add_10_sec"), fullWidth: false) {
                    viewModel.addRestSeconds(10)
                }
                PrimaryButton(title: String(localized: "button_skip_rest"), fullWidth: true) {
                    viewModel.skipRest()
                }
            }
        }
        .padding(.vertical, AppSpacing.lg)
        .padding(.horizontal, AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Corners.lg, style: .continuous)
                .fill(AppColors.backgroundElevated.opacity(0.8))
        )
        .padding(.horizontal, AppSpacing.lg)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private func actionButtons(ex: Exercise) -> some View {
        Group {
            VStack(spacing: AppSpacing.sm) {
                if !viewModel.isResting {
                    PrimaryButton(title: String(localized: "button_done_set"), fullWidth: true) {
                        viewModel.doneSet()
                    }
                }
                if let tutorialURL = ex.tutorialURL,
                   let url = URL(string: tutorialURL),
                   !tutorialURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Link(destination: url) {
                        SecondaryButtonLabel(title: String(localized: "exercise_open_video"))
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
    }

    private var workoutCompleteView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.accent)
            Text("all_sets_complete")
                .font(AppTypography.title2)
            Text(String(format: String(localized: "sets_volume_format"), viewModel.completedSetsCount, prefs.displayVolume(kg: viewModel.totalVolume)))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            PrimaryButton(title: String(localized: "button_see_summary")) {
                showSummary = true
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

// MARK: - Workout Summary

struct WorkoutSummaryView: View {
    let log: WorkoutLog
    @EnvironmentObject private var appState: AppState
    @Environment(\.popToHome) private var popToHome
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var rating: Int
    @State private var exerciseFeedbacks: [ExerciseFeedback]
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSavedFeedback = false

    init(log: WorkoutLog) {
        self.log = log
        _rating = State(initialValue: log.rating)
        _exerciseFeedbacks = State(initialValue: log.exerciseFeedbacks)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.accent)
                        .symbolEffect(.bounce, value: showSavedFeedback)

                    Text("workout_complete")
                        .font(AppTypography.title1)

                    Text(log.workoutTitle)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    GlassCard(cornerRadius: AppTheme.Corners.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            summaryRow(label: String(localized: "summary_duration"), value: String(format: String(localized: "duration_min_format"), log.durationMinutes))
                            Divider()
                            summaryRow(label: String(localized: "summary_total_sets"), value: "\(log.totalSets)")
                            Divider()
                            summaryRow(label: String(localized: "summary_volume"), value: prefs.displayVolume(kg: log.totalVolume))
                            Divider()
                            HStack {
                                Text("summary_rating")
                                    .font(AppTypography.body)
                                Spacer()
                                ratingPicker
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Text("workout_all_done_message")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)

                    if !exerciseFeedbacks.isEmpty {
                        GlassCard(cornerRadius: AppTheme.Corners.lg) {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text("summary_exercise_feedback")
                                    .font(AppTypography.headline)
                                ForEach(Array(exerciseFeedbacks.enumerated()), id: \.element.id) { index, feedback in
                                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                        Text(feedback.exerciseName)
                                            .font(AppTypography.callout.weight(.semibold))
                                        HStack {
                                            Text("summary_difficulty")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Spacer()
                                            Stepper(value: Binding(
                                                get: { exerciseFeedbacks[index].difficulty },
                                                set: { exerciseFeedbacks[index].difficulty = min(5, max(1, $0)) }
                                            ), in: 1...5) {
                                                Text(String(format: String(localized: "difficulty_value_format"), exerciseFeedbacks[index].difficulty))
                                                    .font(AppTypography.caption)
                                                    .foregroundColor(AppColors.textPrimary)
                                            }
                                        }
                                        TextField(String(localized: "summary_exercise_note_placeholder"), text: Binding(
                                            get: { exerciseFeedbacks[index].note ?? "" },
                                            set: {
                                                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                                                exerciseFeedbacks[index].note = trimmed.isEmpty ? nil : trimmed
                                            }
                                        ))
                                        .font(AppTypography.footnote)
                                        .textInputAutocapitalization(.sentences)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                                .fill(AppColors.backgroundElevated.opacity(0.7))
                                        )
                                    }
                                    if index < exerciseFeedbacks.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    if let err = saveError {
                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            VStack(spacing: AppSpacing.sm) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppColors.danger)
                                    Text(String(localized: "save_error_title"))
                                        .font(AppTypography.headline)
                                }
                                Text(err)
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                SecondaryButton(title: String(localized: "save_error_retry"), fullWidth: true) {
                                    saveAndGoHome()
                                }
                            }
                            .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.vertical, AppSpacing.xl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSaving ? String(localized: "saving") : String(localized: "button_done")) {
                    saveAndGoHome()
                }
                .disabled(isSaving)
            }
        }
    }

    private var ratingPicker: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    HapticManager.selection()
                    rating = star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(star <= rating ? Color.yellow : AppColors.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func saveAndGoHome() {
        saveError = nil
        isSaving = true
        let logToSave = WorkoutLog(
            id: log.id,
            athleteId: log.athleteId,
            workoutTitle: log.workoutTitle,
            workoutDayId: log.workoutDayId,
            date: log.date,
            durationMinutes: log.durationMinutes,
            totalSets: log.totalSets,
            totalVolume: log.totalVolume,
            rating: rating,
            exerciseFeedbacks: exerciseFeedbacks,
            status: log.status
        )
        let service = appState.logService
        let coachRequestService = appState.coachRequestService
        let athleteUser = appState.currentUser
        let popHome = popToHome
        Task { @MainActor in
            do {
                try await service.saveLog(logToSave)
                LiveWorkoutViewModel.clearPersistedState(for: logToSave.workoutDayId)
                if let athlete = athleteUser,
                   let coachId = athlete.coachId {
                    try? await coachRequestService.sendWorkoutCompleted(
                        athleteId: athlete.id,
                        athleteName: athlete.name,
                        coachId: coachId,
                        workoutTitle: logToSave.workoutTitle,
                        rating: rating
                    )
                }
                HapticManager.success()
                showSavedFeedback = true
                try? await Task.sleep(nanoseconds: 400_000_000)
                popHome?()
            } catch {
                saveError = error.localizedDescription
            }
            isSaving = false
        }
    }
    
    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
            Spacer()
            Text(value)
                .font(AppTypography.body.weight(.semibold))
        }
    }
}

// MARK: - History

enum HistoryFilter: String, CaseIterable {
    case week
    case month
    case all

    var title: String {
        switch self {
        case .week: return String(localized: "history_filter_week")
        case .month: return String(localized: "history_filter_month")
        case .all: return String(localized: "history_filter_all")
        }
    }
}

struct HistoryView: View {
    let logs: [WorkoutLog]
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var filter: HistoryFilter = .week

    private var filteredLogs: [WorkoutLog] {
        let cal = Calendar.current
        let now = Date()
        switch filter {
        case .week:
            guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return logs }
            return logs.filter { cal.startOfDay(for: $0.date) >= weekStart }
        case .month:
            guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return logs }
            return logs.filter { cal.startOfDay(for: $0.date) >= monthStart }
        case .all:
            return logs
        }
    }

    private var filteredVolume: Double {
        filteredLogs.reduce(0) { $0 + $1.totalVolume }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    filterPicker
                    if logs.isEmpty {
                        historyEmptyState
                    } else {
                        if !filteredLogs.isEmpty {
                            historySummary
                        }
                        SectionHeader(title: String(localized: "section_history"), actionTitle: nil, action: nil)
                        if filteredLogs.isEmpty {
                            Text("no_workouts_logged_desc")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.lg)
                        } else {
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(filteredLogs) { log in
                                    historyLogCard(log: log)
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("nav_history")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filterPicker: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(HistoryFilter.allCases, id: \.self) { f in
                Button {
                    HapticManager.selection()
                    filter = f
                } label: {
                    Text(f.title)
                        .font(AppTypography.footnote)
                        .fontWeight(filter == f ? .semibold : .regular)
                        .foregroundColor(filter == f ? .white : AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Capsule()
                                .fill(filter == f ? AppColors.accent : AppColors.backgroundElevated.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var historySummary: some View {
        HStack(spacing: AppSpacing.lg) {
            GlassCard(cornerRadius: AppTheme.Corners.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: String(localized: "history_summary_workouts"), filteredLogs.count))
                        .font(AppTypography.title2)
                    Text(String(localized: "section_history"))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            GlassCard(cornerRadius: AppTheme.Corners.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: String(localized: "history_summary_volume"), prefs.displayVolume(kg: filteredVolume)))
                        .font(AppTypography.title2)
                    Text(String(localized: "total_volume"))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func historyLogCard(log: WorkoutLog) -> some View {
        GlassCard(cornerRadius: AppTheme.Corners.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString(log.date))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(log.workoutTitle)
                        .font(AppTypography.headline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if log.status == .missed {
                        Text("workout_status_missed")
                            .font(AppTypography.body.weight(.semibold))
                            .foregroundColor(AppColors.warning)
                    } else {
                        Text(prefs.displayVolume(kg: log.totalVolume))
                            .font(AppTypography.body.weight(.semibold))
                            .foregroundColor(AppColors.accent)
                        HStack(spacing: 2) {
                            Text(String(format: String(localized: "duration_min_format"), log.durationMinutes))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text("•")
                                .foregroundColor(AppColors.textMuted)
                            Text(String(repeating: "★", count: log.rating))
                                .font(AppTypography.caption)
                        }
                    }
                }
            }
        }
    }

    private var historyEmptyState: some View {
        GlassCard(cornerRadius: AppTheme.Corners.lg) {
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "figure.run")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.textMuted)
                Text("no_workouts_logged")
                    .font(AppTypography.title2)
                Text("no_workouts_logged_desc")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xxl)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Progress

struct AthleteProgressView: View {
    let logs: [WorkoutLog]
    @ObservedObject private var prefs = AppPreferences.shared

    private var streakDays: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let workoutDays = Set(logs.map { cal.startOfDay(for: $0.date) })
        var count = 0
        var d = today
        while workoutDays.contains(d) {
            count += 1
            guard let next = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = next
        }
        return count
    }

    private var maxVolumeLogged: Double {
        logs.map(\.totalVolume).max() ?? 0
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SectionHeader(
                        title: String(localized: "section_progress"),
                        subtitle: String(localized: "progress_subtitle")
                    )
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("training_volume")
                                .font(AppTypography.headline)
                            
                            #if canImport(Charts)
                            if logs.isEmpty {
                                Text("complete_workouts_for_chart")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                Chart {
                                    ForEach(logs.prefix(30)) { log in
                                        BarMark(
                                            x: .value("Date", log.date),
                                            y: .value("Volume", log.totalVolume)
                                        )
                                        .foregroundStyle(AppTheme.Gradients.primary)
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day, count: 2))
                                }
                                .frame(height: 200)
                            }
                            #else
                            Rectangle()
                                .fill(AppColors.progressBackground)
                                .frame(height: 200)
                                .cornerRadius(AppTheme.Corners.lg)
                                .overlay(
                                    Text(logs.isEmpty ? String(localized: "complete_workouts_for_chart") : String(localized: "volume_chart"))
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textSecondary)
                                )
                            #endif
                        }
                    }
                    
                    SectionHeader(
                        title: String(localized: "section_highlights"),
                        subtitle: String(localized: "highlights_subtitle")
                    )
                    
                    VStack(spacing: AppSpacing.md) {
                        AthleteStatTile(
                            title: String(localized: "current_streak"),
                            value: streakDays == 0 ? "—" : "\(streakDays)",
                            subtitle: streakDays == 1 ? String(localized: "day") : String(localized: "days_in_a_row"),
                            icon: "flame.fill"
                        )
                        AthleteStatTile(
                            title: String(localized: "heaviest_workout"),
                            value: maxVolumeLogged == 0 ? "—" : prefs.displayVolume(kg: maxVolumeLogged),
                            subtitle: String(localized: "single_session_volume"),
                            icon: "scalemass"
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("nav_progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile

struct AthleteProfileSettingsView: View {
    let user: User
    @ObservedObject var appState: AppState
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var showEditProfile = false
    @State private var showUnitsPicker = false
    @State private var showReminderTime = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    Button {
                        showEditProfile = true
                    } label: {
                        GlassCard {
                            HStack(spacing: AppSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.accent.opacity(0.2))
                                    Text(String(user.name.prefix(1)))
                                        .font(AppTypography.title1)
                                        .foregroundColor(AppColors.accent)
                                }
                                .frame(width: 56, height: 56)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(AppTypography.title2)
                                    Text("athlete_profile_edit_hint")
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "pencil.circle")
                                    .font(.title2)
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.lg)

                    SectionHeader(title: String(localized: "section_preferences"), actionTitle: nil, action: nil)

                    VStack(spacing: AppSpacing.md) {
                        Button {
                            showUnitsPicker = true
                        } label: {
                            GlassCard(cornerRadius: AppTheme.Corners.md) {
                                HStack {
                                    Text("units_label")
                                        .font(AppTypography.body)
                                    Spacer()
                                    Text(prefs.weightUnit.displayName)
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textSecondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            HStack {
                                Text("notifications_label")
                                    .font(AppTypography.body)
                                Spacer()
                                Toggle("", isOn: $prefs.notificationsEnabled)
                                    .labelsHidden()
                                    .tint(AppColors.accent)
                            }
                            .onChange(of: prefs.notificationsEnabled) { _, enabled in
                                if enabled {
                                    NotificationScheduler.shared.requestAuthorization { _ in }
                                }
                            }
                        }

                        if prefs.notificationsEnabled {
                            Button {
                                showReminderTime = true
                            } label: {
                                GlassCard(cornerRadius: AppTheme.Corners.md) {
                                    HStack {
                                        Text("reminder_time_label")
                                            .font(AppTypography.body)
                                        Spacer()
                                        Text(reminderTimeString)
                                            .font(AppTypography.body)
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

                    SectionHeader(title: String(localized: "section_account"), actionTitle: nil, action: nil)

                    VStack(spacing: AppSpacing.md) {
                        SecondaryButton(title: String(localized: "manage_subscription")) { }
                        SecondaryButton(title: String(localized: "sign_out")) {
                            appState.signOut()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: AppSpacing.xxxl)
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("nav_profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: user, appState: appState, onDismiss: { showEditProfile = false })
        }
        .sheet(isPresented: $showUnitsPicker) {
            UnitsPickerSheet(onDismiss: { showUnitsPicker = false })
        }
        .sheet(isPresented: $showReminderTime) {
            ReminderTimeSheet(onDismiss: { showReminderTime = false })
        }
    }

    private var reminderTimeString: String {
        let h = prefs.reminderHour
        if h == 0 { return "12:00 AM" }
        if h == 12 { return "12:00 PM" }
        return h < 12 ? "\(h):00 AM" : "\(h - 12):00 PM"
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    let user: User
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
                    TextField("placeholder_your_name", text: $name)
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
            .onAppear { name = user.name }
        }
    }

    private func save() {
        let newName = name.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty else { return }
        errorMessage = nil
        isSaving = true
        Task { @MainActor in
            do {
                try await appState.userService.updateUser(id: user.id, name: newName)
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

// MARK: - Units Picker Sheet

struct UnitsPickerSheet: View {
    let onDismiss: () -> Void
    @ObservedObject private var prefs = AppPreferences.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                List(WeightUnit.allCases, id: \.self) { unit in
                    Button {
                        prefs.weightUnit = unit
                        HapticManager.selection()
                        onDismiss()
                    } label: {
                        HStack {
                            Text(unit.displayName)
                                .font(AppTypography.body)
                            Spacer()
                            if prefs.weightUnit == unit {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("nav_units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button_done")) { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Reminder Time Sheet

struct ReminderTimeSheet: View {
    let onDismiss: () -> Void
    @ObservedObject private var prefs = AppPreferences.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: AppSpacing.xl) {
                    Text("reminder_daily_message")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Stepper(value: $prefs.reminderHour, in: 5...22) {
                        Text(String(format: String(localized: "reminder_hour_format"), prefs.reminderHour))
                            .font(AppTypography.headline)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    Spacer()
                }
                .padding(.top, AppSpacing.xl)
            }
            .navigationTitle("nav_reminder_time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button_done")) { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

struct AthleteViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                AthleteHomeView(
                    viewModel: AthleteHomeViewModel(
                        user: MockData.sampleAthlete,
                        planService: AppState().planService,
                        logService: AppState().logService
                    )
                )
            }
            .preferredColorScheme(.light)
            
            NavigationStack {
                WorkoutDetailView(workoutDay: MockData.todayWorkoutDay, athleteId: MockData.sampleAthlete.id)
            }
            .preferredColorScheme(.dark)

            NavigationStack {
                LiveWorkoutView(workoutDay: MockData.todayWorkoutDay, athleteId: MockData.sampleAthlete.id)
            }
            .preferredColorScheme(.light)

            NavigationStack {
                WorkoutSummaryView(log: MockData.sampleLogs.first!)
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.dark)
            
            NavigationStack {
                HistoryView(logs: MockData.sampleLogs)
            }
            .preferredColorScheme(.light)
            
            AthleteTabRootView(
                user: MockData.sampleAthlete,
                appState: AppState()
            )
            .preferredColorScheme(.dark)
        }
    }
}

