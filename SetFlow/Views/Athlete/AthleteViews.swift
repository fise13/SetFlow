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

    @StateObject private var homeViewModel: AthleteHomeViewModel
    @State private var selectedTab: AthleteTab = .home

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
    }

    @ViewBuilder
    private var workoutTabContent: some View {
        if let today = homeViewModel.todayWorkout {
            WorkoutDetailView(workoutDay: today, athleteId: user.id)
        } else {
            workoutTabEmptyView
        }
    }

    private var workoutTabEmptyView: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                GlassCard {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textMuted)
                        Text("no_workout_today_title")
                            .font(AppTypography.title2)
                        Text("no_workout_today_message")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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
        return upcomingWorkouts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    /// Consecutive days with at least one workout, ending today or yesterday.
    var streakDays: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let workoutDays = Set(history.map { cal.startOfDay(for: $0.date) })
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
        let cal = Calendar.current
        let hasLoggedToday = history.contains { cal.isDate($0.date, inSameDayAs: Date()) && $0.workoutTitle == today.title }
        return hasLoggedToday ? 1 : 0
    }

    @MainActor
    func load() {
        planListener?.remove()
        logListener?.remove()
        planListener = planService.plansForAthleteListener(athleteId: user.id) { [weak self] plans in
            self?.plans = plans
            let upcoming = plans.flatMap { $0.days }.sorted { $0.date < $1.date }
            self?.upcomingWorkouts = upcoming
            if let today = upcoming.first(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
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
        }
        logListener = logService.logsForAthleteListener(athleteId: user.id) { [weak self] logs in
            self?.history = logs
        }
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
                NavigationLink {
                    WorkoutDetailView(workoutDay: today, athleteId: viewModel.user.id)
                } label: {
                    WorkoutHeroCard(
                        title: today.title,
                        subtitle: String(format: String(localized: "today_focus_format"), today.focus),
                        detail: "\(today.exercises.count) exercises",
                        progress: viewModel.todayProgress
                    )
                    .padding(.horizontal, AppSpacing.lg)
                }
                .buttonStyle(.plain)
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
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
            WeeklyCalendarStrip(selectedDate: $selectedDate)
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

// MARK: - Workout Detail

struct WorkoutDetailView: View {
    let workoutDay: WorkoutDay
    var athleteId: String

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(workoutDay.title)
                            .font(AppTypography.title2)
                        Text(workoutDay.focus)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        Text(String(format: String(localized: "exercises_count_format"), workoutDay.exercises.count))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                SectionHeader(title: String(localized: "section_exercises"), actionTitle: nil, action: nil)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(workoutDay.exercises) { exercise in
                            ExerciseRow(exercise: exercise, weightDisplay: AppPreferences.shared.displayWeight(kg: exercise.weight))
                            Divider()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                NavigationLink {
                    LiveWorkoutView(workoutDay: workoutDay, athleteId: athleteId)
                } label: {
                    PrimaryButtonLabel(title: String(localized: "button_start_workout"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle("nav_workout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Live Workout

final class LiveWorkoutViewModel: ObservableObject {
    @Published var currentExerciseIndex: Int = 0
    @Published var currentSet: Int = 1
    @Published var isResting: Bool = false
    @Published var restRemaining: Int = 60
    @Published var completedSetsCount: Int = 0
    @Published var totalVolume: Double = 0
    @Published var workoutStartTime: Date = Date()
    
    private var restTimer: Timer?
    private var restIsBetweenExercises: Bool = false
    
    let workoutDay: WorkoutDay
    
    init(workoutDay: WorkoutDay) {
        self.workoutDay = workoutDay
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
    
    @MainActor
    func doneSet() {
        guard let ex = currentExercise else { return }
        HapticManager.impact()
        completedSetsCount += 1
        totalVolume += ex.weight * Double(ex.reps)
        if currentSet >= ex.sets {
            if currentExerciseIndex + 1 < workoutDay.exercises.count {
                restIsBetweenExercises = true
                startRest(afterRest: { [weak self] in self?.advanceToNextExercise() })
            } else {
                currentExerciseIndex += 1
            }
        } else {
            currentSet += 1
            restIsBetweenExercises = false
            startRest(afterRest: { })
        }
    }
    
    @MainActor
    private func startRest(afterRest: @escaping () -> Void) {
        guard let ex = currentExercise else {
            isResting = false
            afterRest()
            return
        }
        isResting = true
        restRemaining = ex.restSeconds
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickRest(afterRest: afterRest)
            }
        }
        RunLoop.main.add(restTimer!, forMode: .common)
    }
    
    @MainActor
    private func tickRest(afterRest: @escaping () -> Void) {
        restRemaining -= 1
        if restRemaining <= 3, restRemaining > 0 {
            HapticManager.impact()
        }
        if restRemaining <= 0 {
            restTimer?.invalidate()
            restTimer = nil
            isResting = false
            HapticManager.success()
            afterRest()
        }
    }
    
    @MainActor
    func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        if restIsBetweenExercises {
            advanceToNextExercise()
        }
    }
    
    @MainActor
    private func advanceToNextExercise() {
        currentExerciseIndex += 1
        currentSet = 1
    }
    
    func buildLog(athleteId: String) -> WorkoutLog {
        let durationMinutes = max(1, Int(Date().timeIntervalSince(workoutStartTime) / 60))
        return WorkoutLog(
            id: "temp-\(UUID().uuidString)",
            athleteId: athleteId,
            workoutTitle: workoutDay.title,
            date: Date(),
            durationMinutes: durationMinutes,
            totalSets: completedSetsCount,
            totalVolume: totalVolume,
            rating: 5
        )
    }
}

struct LiveWorkoutView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @ObservedObject private var prefs = AppPreferences.shared
    let athleteId: String
    @State private var showSummary = false

    init(workoutDay: WorkoutDay, athleteId: String) {
        self.viewModel = LiveWorkoutViewModel(workoutDay: workoutDay)
        self.athleteId = athleteId
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                if viewModel.isWorkoutComplete {
                    workoutCompleteView
                } else if let ex = viewModel.currentExercise {
                    VStack(spacing: AppSpacing.sm) {
                        Text(viewModel.workoutDay.title)
                            .font(AppTypography.headline)
                        Text(String(format: String(localized: "exercise_progress_format"), viewModel.currentExerciseIndex + 1, viewModel.workoutDay.exercises.count))
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    CardView {
                        VStack(spacing: AppSpacing.lg) {
                            Text(ex.name)
                                .font(AppTypography.title2)
                            Text("\(ex.sets)x\(ex.reps)  •  \(prefs.displayWeight(kg: ex.weight))")
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
                    .padding(.horizontal, AppSpacing.lg)

                    if viewModel.isResting {
                        VStack(spacing: AppSpacing.sm) {
                            Text("rest_label")
                                .font(AppTypography.headline)
                            Text(String(format: String(localized: "rest_seconds_format"), viewModel.restRemaining))
                                .font(AppTypography.largeTitle)
                            CustomProgressBar(progress: Double(viewModel.restRemaining) / Double(ex.restSeconds))
                                .frame(height: 12)
                                .padding(.horizontal, AppSpacing.lg)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    HStack(spacing: AppSpacing.md) {
                        if viewModel.isResting {
                            PrimaryButton(title: String(localized: "button_skip_rest"), fullWidth: true) {
                                viewModel.skipRest()
                            }
                        } else {
                            PrimaryButton(title: String(localized: "button_done_set"), fullWidth: true) {
                                viewModel.doneSet()
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                } else {
                    Text("no_exercises")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }

                if !viewModel.isWorkoutComplete && viewModel.completedSetsCount > 0 {
                    Button {
                        showSummary = true
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
        .navigationTitle("nav_live")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSummary) {
            WorkoutSummaryView(log: viewModel.buildLog(athleteId: athleteId))
        }
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
    @State private var isSaving = false
    @State private var saveError: String?

    init(log: WorkoutLog) {
        self.log = log
        _rating = State(initialValue: log.rating)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Spacer(minLength: AppSpacing.xl)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.accent)
                    .padding(.bottom, AppSpacing.md)

                Text("workout_complete")
                    .font(AppTypography.title2)

                Text(log.workoutTitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        summaryRow(label: String(localized: "summary_duration"), value: String(format: String(localized: "duration_min_format"), log.durationMinutes))
                        summaryRow(label: String(localized: "summary_total_sets"), value: "\(log.totalSets)")
                        summaryRow(label: String(localized: "summary_volume"), value: prefs.displayVolume(kg: log.totalVolume))
                        HStack {
                            Text("summary_rating")
                                .font(AppTypography.body)
                            Spacer()
                            ratingPicker
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                if let err = saveError {
                    Text(err)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.danger)
                        .padding(.horizontal)
                }

                Spacer()

                PrimaryButton(title: isSaving ? String(localized: "saving") : String(localized: "button_save_go_home"), fullWidth: true) {
                    saveAndGoHome()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
                .disabled(isSaving)
            }
        }
        .navigationBarBackButtonHidden(true)
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
            date: log.date,
            durationMinutes: log.durationMinutes,
            totalSets: log.totalSets,
            totalVolume: log.totalVolume,
            rating: rating
        )
        let service = appState.logService
        let popHome = popToHome
        Task { @MainActor in
            do {
                try await service.saveLog(logToSave)
                HapticManager.success()
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

struct HistoryView: View {
    let logs: [WorkoutLog]
    @ObservedObject private var prefs = AppPreferences.shared

    private var volumeThisWeek: Double {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return 0 }
        return logs
            .filter { cal.startOfDay(for: $0.date) >= weekStart }
            .reduce(0) { $0 + $1.totalVolume }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SectionHeader(title: String(localized: "section_history"), actionTitle: nil, action: nil)
                    if logs.isEmpty {
                        GlassCard {
                            VStack(spacing: AppSpacing.sm) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppColors.textMuted)
                                Text("no_workouts_logged")
                                    .font(AppTypography.headline)
                                Text("no_workouts_logged_desc")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.xl)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(logs) { log in
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
                                        Text(String(format: String(localized: "duration_min_format"), log.durationMinutes))
                                            .font(AppTypography.footnote)
                                            .foregroundColor(AppColors.textSecondary)
                                        Text(String(repeating: "★", count: log.rating))
                                            .font(AppTypography.footnote)
                                    }
                                }
                                .padding(.vertical, AppSpacing.sm)
                                Divider()
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    if !logs.isEmpty {
                        SectionHeader(title: String(localized: "section_this_week"), subtitle: String(localized: "total_volume"), actionTitle: nil, action: nil)
                        CardView {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(prefs.displayVolume(kg: volumeThisWeek))
                                    .font(AppTypography.title2)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("nav_history")
        .navigationBarTitleDisplayMode(.inline)
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

