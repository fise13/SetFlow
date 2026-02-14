import SwiftUI
import Combine
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
        case .home: return "Home"
        case .workout: return "Workout"
        case .progress: return "Progress"
        case .profile: return "Profile"
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
    let plans: [WorkoutPlan]
    
    @StateObject private var homeViewModel: AthleteHomeViewModel
    @State private var selectedTab: AthleteTab = .home
    
    init(user: User, plans: [WorkoutPlan]) {
        self.user = user
        self.plans = plans
        _homeViewModel = StateObject(wrappedValue: AthleteHomeViewModel(user: user, plans: plans))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    AthleteHomeView(viewModel: homeViewModel)
                }
                .tag(AthleteTab.home)
                
                NavigationStack {
                    if let today = homeViewModel.todayWorkout {
                        WorkoutDetailView(workoutDay: today)
                    } else {
                        Text("No workout scheduled for today.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .padding()
                            .navigationTitle("Workout")
                    }
                }
                .tag(AthleteTab.workout)
                
                NavigationStack {
                    AthleteProgressView(logs: homeViewModel.history)
                }
                .tag(AthleteTab.progress)
                
                NavigationStack {
                    AthleteProfileSettingsView(user: user)
                }
                .tag(AthleteTab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            AthleteTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
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
    @Published var plans: [WorkoutPlan]
    @Published var upcomingWorkouts: [WorkoutDay] = []
    @Published var history: [WorkoutLog] = MockData.sampleLogs
    
    init(user: User, plans: [WorkoutPlan]) {
        self.user = user
        self.plans = plans
        self.upcomingWorkouts = plans.flatMap { $0.days }.sorted { $0.date < $1.date }
    }
    
    var todayWorkout: WorkoutDay? {
        let today = Calendar.current.startOfDay(for: Date())
        return upcomingWorkouts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
}

struct AthleteHomeView: View {
    @ObservedObject var viewModel: AthleteHomeViewModel
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
                Text("Today")
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
            Text("Let’s get your training done.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private var todayHero: some View {
        Group {
            if let today = viewModel.todayWorkout {
                NavigationLink {
                    WorkoutDetailView(workoutDay: today)
                } label: {
                    WorkoutHeroCard(
                        title: today.title,
                        subtitle: "Today • \(today.focus)",
                        detail: "\(today.exercises.count) exercises",
                        progress: 0.35
                    )
                    .padding(.horizontal, AppSpacing.lg)
                }
                .buttonStyle(.plain)
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("No workout scheduled")
                            .font(AppTypography.headline)
                        Text("Your coach hasn’t planned anything for today.")
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
            SectionHeader(title: "This week", actionTitle: nil, action: nil)
            WeeklyCalendarStrip(selectedDate: $selectedDate)
        }
    }
    
    private var quickStats: some View {
        let volume = "\(Int(viewModel.history.first?.totalVolume ?? 12400)) kg"
        let streak = "5 days"
        let nextWorkout = viewModel.upcomingWorkouts.dropFirst().first?.title ?? "Rest"
        
        return HStack(spacing: AppSpacing.md) {
            AthleteStatTile(title: "Streak", value: streak, subtitle: "in a row", icon: "flame.fill")
            AthleteStatTile(title: "Volume", value: volume, subtitle: "this week", icon: "chart.bar.fill")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.sm)
        .overlay(
            HStack {
                Spacer()
                AthleteStatTile(title: "Next", value: nextWorkout, subtitle: "planned", icon: "calendar.badge.clock")
                    .frame(width: 170)
            }
            .padding(.trailing, AppSpacing.lg),
            alignment: .bottom
        )
    }
    
    private var recentWorkouts: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Recent", actionTitle: "See all") {
                // Navigation handled by toolbar History button
            }
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
                                Text("\(log.durationMinutes) min")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("★ \(log.rating)")
                                    .font(AppTypography.footnote)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
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
                        Text("\(workoutDay.exercises.count) exercises")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                SectionHeader(title: "Exercises", actionTitle: nil, action: nil)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(workoutDay.exercises) { exercise in
                            ExerciseRow(exercise: exercise)
                            Divider()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                
                NavigationLink {
                    LiveWorkoutView(workoutDay: workoutDay)
                } label: {
                    PrimaryButtonLabel(title: "Start workout")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Live Workout

final class LiveWorkoutViewModel: ObservableObject {
    @Published var currentExerciseIndex: Int = 0
    @Published var currentSet: Int = 1
    @Published var isResting: Bool = false
    @Published var restRemaining: Int = 60
    
    let workoutDay: WorkoutDay
    
    init(workoutDay: WorkoutDay) {
        self.workoutDay = workoutDay
    }
    
    var currentExercise: Exercise {
        workoutDay.exercises[currentExerciseIndex]
    }
    
    var progress: Double {
        let totalSets = workoutDay.exercises.reduce(0) { $0 + $1.sets }
        let completedSetsBefore = workoutDay.exercises.prefix(currentExerciseIndex).reduce(0) { $0 + $1.sets }
        let completed = completedSetsBefore + (currentSet - 1)
        return totalSets == 0 ? 0 : Double(completed) / Double(totalSets)
    }
}

struct LiveWorkoutView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @State private var animateRing: Bool = false
    
    init(workoutDay: WorkoutDay) {
        self.viewModel = LiveWorkoutViewModel(workoutDay: workoutDay)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    Text(viewModel.workoutDay.title)
                        .font(AppTypography.headline)
                    Text("Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.workoutDay.exercises.count)")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                CardView {
                    VStack(spacing: AppSpacing.lg) {
                        Text(viewModel.currentExercise.name)
                            .font(AppTypography.title2)
                        Text("\(viewModel.currentExercise.sets)x\(viewModel.currentExercise.reps)  •  \(Int(viewModel.currentExercise.weight)) kg")
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
                                Text("Set \(viewModel.currentSet)")
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
                        Text("Rest")
                            .font(AppTypography.headline)
                        Text("\(viewModel.restRemaining)s")
                            .font(AppTypography.largeTitle)
                        CustomProgressBar(progress: Double(viewModel.restRemaining) / Double(viewModel.currentExercise.restSeconds))
                            .frame(height: 12)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                HStack(spacing: AppSpacing.md) {
                    SecondaryButton(title: "Prev", fullWidth: true) {
                        // Placeholder navigation between exercises
                    }
                    PrimaryButton(title: viewModel.isResting ? "Skip rest" : "Done set", fullWidth: true) {
                        HapticManager.impact()
                        // Placeholder state machine
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                NavigationLink {
                    WorkoutSummaryView(
                        log: WorkoutLog(
                            id: UUID(),
                            workoutTitle: viewModel.workoutDay.title,
                            date: Date(),
                            durationMinutes: 52,
                            totalSets: viewModel.workoutDay.exercises.reduce(0) { $0 + $1.sets },
                            totalVolume: 14000,
                            rating: 5
                        )
                    )
                } label: {
                    Text("Finish workout")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, AppSpacing.sm)
                }
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle("Live")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Workout Summary

struct WorkoutSummaryView: View {
    let log: WorkoutLog
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Spacer(minLength: AppSpacing.xl)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.accent)
                    .padding(.bottom, AppSpacing.md)
                
                Text("Workout complete")
                    .font(AppTypography.title2)
                
                Text(log.workoutTitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                
                CardView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        summaryRow(label: "Duration", value: "\(log.durationMinutes) min")
                        summaryRow(label: "Total sets", value: "\(log.totalSets)")
                        summaryRow(label: "Volume", value: "\(Int(log.totalVolume)) kg")
                        summaryRow(label: "Rating", value: String(repeating: "★", count: log.rating))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
                
                PrimaryButton(title: "Back to home") {
                    HapticManager.success()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
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
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SectionHeader(title: "History", actionTitle: nil, action: nil)
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
                                Text("\(log.durationMinutes) min")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.vertical, AppSpacing.sm)
                            Divider()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    SectionHeader(title: "Progress", actionTitle: nil, action: nil)
                    CardView {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Weekly volume")
                                .font(AppTypography.headline)
                            Text("Placeholder graph – connect to real data later.")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            Rectangle()
                                .fill(AppColors.progressBackground)
                                .frame(height: 120)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                        .foregroundColor(AppColors.border)
                                )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("History")
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
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SectionHeader(
                        title: "Progress",
                        subtitle: "Volume over the last weeks"
                    )
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Training volume")
                                .font(AppTypography.headline)
                            
                            #if canImport(Charts)
                            Chart {
                                ForEach(logs) { log in
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
                            #else
                            Rectangle()
                                .fill(AppColors.progressBackground)
                                .frame(height: 200)
                                .cornerRadius(AppTheme.Corners.lg)
                                .overlay(
                                    Text("Charts placeholder\n(Charts framework not available)")
                                        .font(AppTypography.footnote)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(AppColors.textSecondary)
                                )
                            #endif
                        }
                    }
                    
                    SectionHeader(
                        title: "Highlights",
                        subtitle: "Streaks and personal records"
                    )
                    
                    VStack(spacing: AppSpacing.md) {
                        AthleteStatTile(
                            title: "Longest streak",
                            value: "9 days",
                            subtitle: "All time",
                            icon: "flame.fill"
                        )
                        AthleteStatTile(
                            title: "Heaviest set",
                            value: "180 kg",
                            subtitle: "Deadlift triple",
                            icon: "scalemass"
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile

struct AthleteProfileSettingsView: View {
    let user: User
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
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
                                Text("Athlete profile")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    SectionHeader(title: "Preferences", actionTitle: nil, action: nil)
                    
                    VStack(spacing: AppSpacing.md) {
                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            HStack {
                                Text("Units")
                                    .font(AppTypography.body)
                                Spacer()
                                Text("Kilograms")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        GlassCard(cornerRadius: AppTheme.Corners.md) {
                            HStack {
                                Text("Notifications")
                                    .font(AppTypography.body)
                                Spacer()
                                Text("Enabled")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    SectionHeader(title: "Account", actionTitle: nil, action: nil)
                    
                    VStack(spacing: AppSpacing.md) {
                        SecondaryButton(title: "Manage subscription") { }
                        SecondaryButton(title: "Sign out") { }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    Spacer(minLength: AppSpacing.xxxl)
                }
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
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
                        plans: MockData.samplePlans
                    )
                )
            }
            .preferredColorScheme(.light)
            
            NavigationStack {
                WorkoutDetailView(workoutDay: MockData.todayWorkoutDay)
            }
            .preferredColorScheme(.dark)
            
            NavigationStack {
                LiveWorkoutView(workoutDay: MockData.todayWorkoutDay)
            }
            .preferredColorScheme(.light)
            
            NavigationStack {
                WorkoutSummaryView(log: MockData.sampleLogs.first!)
            }
            .preferredColorScheme(.dark)
            
            NavigationStack {
                HistoryView(logs: MockData.sampleLogs)
            }
            .preferredColorScheme(.light)
            
            AthleteTabRootView(
                user: MockData.sampleAthlete,
                plans: MockData.samplePlans
            )
            .preferredColorScheme(.dark)
        }
    }
}

