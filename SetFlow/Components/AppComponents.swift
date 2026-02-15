import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Haptics

enum HapticManager {
    static func impact() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
    
    static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
    
    static func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

// MARK: - Primary / Secondary Buttons

struct PrimaryActionButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            HapticManager.impact()
            action()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.lg)
            .background(
                AppTheme.Gradients.primary
                    .cornerRadius(AppTheme.Corners.lg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .appShadow(.floating)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isPressed)
    }
}

/// Use this inside `NavigationLink` labels (non-interactive).
struct PrimaryActionButtonLabel: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
            }
            Text(title)
                .font(AppTypography.callout)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(
            AppTheme.Gradients.primary
                .cornerRadius(AppTheme.Corners.lg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .appShadow(.floating)
    }
}

/// Backwards-compatible alias used in earlier views
struct PrimaryButton: View {
    let title: String
    var fullWidth: Bool = true
    var action: () -> Void
    
    var body: some View {
        PrimaryActionButton(title: title, fullWidth: fullWidth, action: action)
    }
}

/// Use this inside `NavigationLink` labels (non-interactive).
struct PrimaryButtonLabel: View {
    let title: String
    var fullWidth: Bool = true
    
    var body: some View {
        PrimaryActionButtonLabel(title: title, fullWidth: fullWidth)
    }
}

struct SecondaryButton: View {
    let title: String
    var fullWidth: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            Text(title)
                .font(AppTypography.callout)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, AppSpacing.md)
                .padding(.horizontal, AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                        .fill(Color.white.opacity(0.06))
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                                .strokeBorder(AppColors.border.opacity(0.4), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Write to coach (athlete)

struct WriteToCoachButton: View {
    let user: User
    @EnvironmentObject private var appState: AppState
    @State private var isSendingRequest = false
    @State private var showRequestSent = false
    @State private var showNoCoachAlert = false

    var body: some View {
        Button {
            if user.coachId == nil {
                showNoCoachAlert = true
                return
            }
            guard let coachId = user.coachId else { return }
            isSendingRequest = true
            Task {
                do {
                    try await appState.coachRequestService.sendWorkoutRequest(
                        athleteId: user.id,
                        athleteName: user.name,
                        coachId: coachId
                    )
                    await MainActor.run {
                        isSendingRequest = false
                        showRequestSent = true
                        HapticManager.success()
                    }
                } catch {
                    await MainActor.run {
                        isSendingRequest = false
                        HapticManager.impact()
                    }
                }
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if isSendingRequest {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(AppColors.accent)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                }
                Text("button_write_to_coach")
                    .font(AppTypography.callout)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(isSendingRequest)
        .alert(String(localized: "coach_request_sent_title"), isPresented: $showRequestSent) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("coach_request_sent")
        }
        .alert(String(localized: "coach_request_no_coach"), isPresented: $showNoCoachAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("coach_request_no_coach")
        }
    }
}

/// Use this inside `NavigationLink` labels (non-interactive).
struct SecondaryButtonLabel: View {
    let title: String
    var fullWidth: Bool = true
    
    var body: some View {
        Text(title)
            .font(AppTypography.callout)
            .fontWeight(.medium)
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                    .fill(Color.white.opacity(0.06))
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                            .strokeBorder(AppColors.border.opacity(0.4), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Divider Component

struct DividerView: View {
    let text: String
    
    init(_ text: String = "or") {
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
            
            Text(text.uppercased())
                .font(AppTypography.monoCaption)
                .foregroundColor(Color.white.opacity(0.6))
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
        }
    }
}

// MARK: - Email Password Form Field

struct FormTextField<FocusValue: Hashable>: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var errorMessage: String? = nil
    var submitLabel: SubmitLabel = .next
    var focusValue: FocusValue
    var focusedField: FocusState<FocusValue>.Binding
    var onCommit: (() -> Void)? = nil
    
    private var isFocused: Bool {
        focusedField.wrappedValue == focusValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title.uppercased())
                .font(AppTypography.monoCaption)
                .foregroundColor(Color.white.opacity(0.7))
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(submitLabel)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(submitLabel)
                }
            }
            .font(AppTypography.body)
            .foregroundColor(.white)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                    .fill(Color.white.opacity(isFocused ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                            .strokeBorder(
                                errorMessage != nil 
                                ? AppColors.danger.opacity(0.6)
                                : (isFocused ? Color.white.opacity(0.3) : Color.white.opacity(0.15)),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .focused(focusedField, equals: focusValue)
            .onSubmit {
                onCommit?()
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.danger)
                    .padding(.leading, AppSpacing.sm)
            }
        }
    }
}

// MARK: - Loading Button Label

struct LoadingButtonLabel: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var fullWidth: Bool = true
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Text(title)
                .font(AppTypography.callout)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(
            AppTheme.Gradients.primary
                .cornerRadius(AppTheme.Corners.lg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Corners.lg)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .appShadow(.floating)
        .opacity(isLoading ? 0.7 : 1.0)
    }
}

// MARK: - Skeletons

struct SkeletonBar: View {
    var width: CGFloat? = nil
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 8
    @State private var isPulsing = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppColors.progressBackground)
            .frame(width: width, height: height)
            .opacity(isPulsing ? 0.45 : 0.8)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

struct SkeletonCard: View {
    var body: some View {
        GlassCard(cornerRadius: AppTheme.Corners.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SkeletonBar(width: 140, height: 16)
                SkeletonBar(width: 220, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.sm)
        }
    }
}

// MARK: - Glass Card & Section Header

struct GlassCard<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = AppTheme.Corners.lg
    
    init(cornerRadius: CGFloat = AppTheme.Corners.lg,
         @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.Materials.glass)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColors.backgroundElevated.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                content()
            }
            .padding(AppSpacing.lg)
        }
        .appShadow(.softCard)
    }
}

/// Legacy wrapper for compatibility with earlier code
struct CardView<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GlassCard(content: content)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.accentSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Exercise Row & Pills

struct ExerciseSetPill: View {
    let label: String
    let icon: String?
    
    init(_ label: String, icon: String? = nil) {
        self.label = label
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(label)
                .font(AppTypography.monoCaption)
        }
        .foregroundColor(AppColors.textSecondary)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.backgroundElevated.opacity(0.7))
        )
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    /// If set, used for weight pill (e.g. "120 kg" or "265 lb"). Defaults to "\(weight) kg".
    var weightDisplay: String? = nil

    private var weightText: String {
        weightDisplay ?? "\(Int(exercise.weight)) kg"
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.accent.opacity(0.12))
                Image(systemName: exercise.iconName)
                    .foregroundColor(AppColors.accent)
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(AppTypography.body.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 6) {
                    ExerciseSetPill("\(exercise.sets)x\(exercise.reps)", icon: "number")
                    if exercise.requiresWeight {
                        ExerciseSetPill(weightText, icon: "scalemass")
                    }
                    ExerciseSetPill("\(exercise.restSeconds)s", icon: "timer")
                    if exercise.tutorialURL != nil {
                        ExerciseSetPill(String(localized: "exercise_video_pill"), icon: "play.rectangle")
                    }
                }
            }
            Spacer()
            if exercise.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Workout Hero Card

struct WorkoutHeroCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let progress: Double
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous)
                .fill(AppTheme.Gradients.primary)
                .overlay(AppTheme.Gradients.cardOverlay)
                .appShadow(.softCard)
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(subtitle.uppercased())
                    .font(AppTypography.monoCaption)
                    .foregroundColor(Color.white.opacity(0.8))
                
                Text(title)
                    .font(AppTypography.title1)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: AppSpacing.md) {
                    ProgressRing(progress: progress, lineWidth: 8)
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail)
                            .font(AppTypography.footnote)
                            .foregroundColor(Color.white.opacity(0.9))
                        Text(String(format: String(localized: "progress_complete_format"), Int(progress * 100)))
                            .font(AppTypography.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
    }
}

/// Legacy compact workout card used in lists
struct WorkoutCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let progress: Double
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.title2)
                Text(subtitle)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
                CustomProgressBar(progress: progress)
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Linear Progress Bar

struct CustomProgressBar: View {
    var progress: Double // 0...1
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.progressBackground)
                Capsule()
                    .fill(AppColors.accent)
                    .frame(width: proxy.size.width * CGFloat(max(0, min(1, progress))))
            }
            .frame(height: 8)
            .clipShape(Capsule())
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.35), value: progress)
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.progressBackground, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.01, min(1, progress)))
                .stroke(
                    AppTheme.Gradients.primary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

// MARK: - Weekly Calendar Strip

struct WeeklyCalendarStrip: View {
    @Binding var selectedDate: Date
    var markedDates: [Date] = []
    
    private var daysInWeek: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(daysInWeek, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    
                    Button {
                        selectedDate = date
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text(shortWeekday(for: date))
                                .font(AppTypography.caption)
                            Text(dayNumber(for: date))
                                .font(AppTypography.callout)
                                .fontWeight(.semibold)
                            Circle()
                                .fill(hasWorkout(on: date) ? AppColors.accentSecondary : Color.clear)
                                .frame(width: 5, height: 5)
                        }
                        .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                        .frame(width: 44, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                .fill(
                                    isSelected
                                    ? AnyShapeStyle(AppTheme.Gradients.primary)
                                    : AnyShapeStyle(AppColors.backgroundElevated.opacity(0.8))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.md, style: .continuous)
                                .strokeBorder(Color.white.opacity(isSelected ? 0.5 : 0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
        }
    }
    
    private func shortWeekday(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }
    
    private func dayNumber(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private func hasWorkout(on date: Date) -> Bool {
        markedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
}

// MARK: - Athlete Stat Tile

struct AthleteStatTile: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var icon: String? = nil
    
    var body: some View {
        GlassCard(cornerRadius: AppTheme.Corners.md) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(AppColors.accent.opacity(0.12))
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(AppTypography.monoCaption)
                        .foregroundColor(AppColors.textMuted)
                    Text(value)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Floating Start Workout Button

struct FloatingStartWorkoutButton: View {
    var action: () -> Void
    
    var body: some View {
        PrimaryActionButton(title: "Start workout", icon: "play.fill", fullWidth: false, action: action)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxxl)
    }
}

// MARK: - Bottom Sheet

struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        _isPresented = isPresented
        self.content = content
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                if isPresented {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                isPresented = false
                            }
                        }
                        .transition(.opacity)
                    
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 36, height: 4)
                            .padding(.top, AppSpacing.md)
                            .padding(.bottom, AppSpacing.sm)
                        content()
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, proxy.safeAreaInsets.bottom == 0 ? AppSpacing.lg : proxy.safeAreaInsets.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Materials.bottomBar)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isPresented)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews

struct AppComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    WorkoutHeroCard(
                        title: "Lower Body Strength",
                        subtitle: "Today • Week 3",
                        detail: "8 exercises • 24 sets",
                        progress: 0.4
                    )
                    
                    HStack(spacing: AppSpacing.md) {
                        AthleteStatTile(title: "Streak", value: "5", subtitle: "days", icon: "flame.fill")
                        AthleteStatTile(title: "Volume", value: "12.4k", subtitle: "kg this week", icon: "chart.bar.fill")
                    }
                    
                    ExerciseRow(exercise: MockData.sampleExercises.first!)
                    
                    WeeklyCalendarStrip(selectedDate: .constant(Date()))
                    
                    PrimaryActionButton(title: "Primary action", icon: "bolt.fill") {}
                    SecondaryButton(title: "Secondary", fullWidth: true) {}
                }
                .padding()
                .background(AppColors.background)
            }
            .preferredColorScheme(.light)
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    WorkoutHeroCard(
                        title: "Upper Body Push",
                        subtitle: "Tomorrow",
                        detail: "7 exercises • 21 sets",
                        progress: 0.7
                    )
                    FloatingStartWorkoutButton { }
                }
                .padding()
                .background(AppColors.background)
            }
            .preferredColorScheme(.dark)
        }
    }
}

