import SwiftUI
import FirebaseAuth
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Onboarding Flow

struct WelcomeView: View {
    @State private var currentPage: Int = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.16),
                    Color(red: 0.03, green: 0.13, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingSlide(
                        title: String(localized: "onboarding_title_train"),
                        subtitle: String(localized: "onboarding_subtitle_train"),
                        icon: "figure.strengthtraining.traditional",
                        accentGradient: AppTheme.Gradients.primary
                    )
                    .tag(0)
                    
                    OnboardingSlide(
                        title: String(localized: "onboarding_title_focus"),
                        subtitle: String(localized: "onboarding_subtitle_focus"),
                        icon: "timer",
                        accentGradient: AppTheme.Gradients.warm
                    )
                    .tag(1)
                    
                    OnboardingSlide(
                        title: String(localized: "onboarding_title_coaches"),
                        subtitle: String(localized: "onboarding_subtitle_coaches"),
                        icon: "person.3.sequence.fill",
                        accentGradient: AppTheme.Gradients.primary
                    )
                    .tag(2)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                onboardingPager
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
    }
    
    private var onboardingPager: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.25))
                        .frame(width: index == currentPage ? 22 : 6, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                }
            }
            
            if currentPage < 2 {
                PrimaryActionButton(title: String(localized: "button_continue")) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        currentPage = min(currentPage + 1, 2)
                    }
                }
            } else {
                NavigationLink {
                    SignInView()
                } label: {
                    PrimaryActionButtonLabel(title: String(localized: "button_get_started"), icon: "arrow.right")
                }
                .buttonStyle(.plain)
            }
            
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    currentPage = 2
                }
            } label: {
                Text(currentPage == 2 ? " " : String(localized: "skip_to_sign_in"))
                    .font(AppTypography.footnote)
                    .foregroundColor(Color.white.opacity(0.7))
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
    }
}

struct OnboardingSlide: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentGradient: LinearGradient
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous)
                    .fill(accentGradient)
                    .overlay(AppTheme.Gradients.cardOverlay)
                    .frame(height: 260)
                    .appShadow(.softCard)
                
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                    
                    Text("brand_name")
                        .font(AppTypography.monoCaption)
                        .foregroundColor(Color.white.opacity(0.8))
                    
                    Text(title)
                        .font(AppTypography.title1)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            
            Text(subtitle)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
        }
    }
}

// MARK: - Sign In

enum SignInMethod {
    case apple
    case email
}

struct SignInView: View {
    @EnvironmentObject private var appState: AppState
    @State private var signInMethod: SignInMethod? = nil
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var generalError: String? = nil
    @State private var showForgotPasswordSheet: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with decorative elements
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacing
                        Spacer()
                            .frame(height: max(40, geometry.safeAreaInsets.top))
                        
                        // Logo/Branding Section
                        logoSection
                            .padding(.top, AppSpacing.xxl)
                            .padding(.bottom, AppSpacing.xl)
                        
                        // Header Section
                        headerSection
                            .padding(.bottom, AppSpacing.xxl)
                        
                        // Sign In Methods
                        signInMethodsSection
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, AppSpacing.lg)
                        
                        // Email/Password Form (if email method selected)
                        if signInMethod == .email {
                            emailPasswordForm
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.bottom, AppSpacing.lg)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Sign Up Option
                        signUpSection
                            .padding(.bottom, AppSpacing.lg)
                        
                        // Terms & Privacy
                        termsSection
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, max(AppSpacing.lg, geometry.safeAreaInsets.bottom))
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                #if os(iOS)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                #endif
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: signInMethod)
        .sheet(isPresented: $showForgotPasswordSheet) {
            ForgotPasswordSheet(onDismiss: { showForgotPasswordSheet = false })
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            AppTheme.Gradients.primary
                .ignoresSafeArea()
            
            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 200, height: 200)
                .offset(x: 180, y: 300)
            
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 150, height: 150)
                .offset(x: 120, y: -100)
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("brand_name")
                .font(AppTypography.monoCaption)
                .foregroundColor(Color.white.opacity(0.8))
                .tracking(2)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("signin_welcome_back")
                .font(AppTypography.largeTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("signin_subtitle")
                .font(AppTypography.body)
                .foregroundColor(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
    }
    
    // MARK: - Sign In Methods Section
    
    private var signInMethodsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Sign in with Apple
            Button {
                HapticManager.impact()
                signInMethod = .apple
                handleAppleSignIn()
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("signin_continue_apple")
                        .font(AppTypography.callout)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .padding(.horizontal, AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Corners.lg, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.lg, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .appShadow(.subtle)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            
            // Divider
            DividerView()
                .padding(.vertical, AppSpacing.sm)
            
            // Sign in with Email button
            Button {
                HapticManager.selection()
                withAnimation {
                    signInMethod = signInMethod == .email ? nil : .email
                }
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("signin_continue_email")
                        .font(AppTypography.callout)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .padding(.horizontal, AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Corners.lg, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Corners.lg, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }
    
    // MARK: - Email Password Form
    
    private var emailPasswordForm: some View {
        VStack(spacing: AppSpacing.lg) {
            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    FormTextField(
                        title: String(localized: "form_email"),
                        text: $email,
                        placeholder: String(localized: "placeholder_email"),
                        keyboardType: .emailAddress,
                        errorMessage: emailError,
                        submitLabel: .next,
                        focusValue: Field.email,
                        focusedField: $focusedField
                    ) {
                        focusedField = .password
                    }
                    
                    FormTextField(
                        title: String(localized: "form_password"),
                        text: $password,
                        placeholder: String(localized: "placeholder_password"),
                        isSecure: true,
                        errorMessage: passwordError,
                        submitLabel: .go,
                        focusValue: Field.password,
                        focusedField: $focusedField
                    ) {
                        handleEmailSignIn()
                    }
                    
                    // Forgot password link
                    HStack {
                        Spacer()
                        Button {
                            HapticManager.selection()
                            showForgotPasswordSheet = true
                        } label: {
                            Text("forgot_password")
                                .font(AppTypography.footnote)
                                .foregroundColor(Color.white.opacity(0.8))
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let err = generalError {
                        Text(err)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.danger)
                    }
                    // Sign in button
                    Button {
                        handleEmailSignIn()
                    } label: {
                        LoadingButtonLabel(
                            title: String(localized: "button_sign_in"),
                            icon: "arrow.right",
                            isLoading: isLoading,
                            fullWidth: true
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Sign Up Section
    
    private var signUpSection: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("no_account")
                .font(AppTypography.footnote)
                .foregroundColor(Color.white.opacity(0.7))
            
            Button {
                HapticManager.selection()
                appState.showSignUpSheet = true
            } label: {
                Text("button_sign_up")
                    .font(AppTypography.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        Text("terms_agreement")
            .font(AppTypography.caption)
            .foregroundColor(Color.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }
    
    // MARK: - Actions
    
    private func handleAppleSignIn() {
        generalError = String(localized: "error_apple_not_configured")
        HapticManager.impact()
    }

    private func handleEmailSignIn() {
        emailError = nil
        passwordError = nil
        generalError = nil
        if email.isEmpty {
            emailError = String(localized: "error_email_required")
            return
        }
        if !isValidEmail(email) {
            emailError = String(localized: "error_email_invalid")
            return
        }
        if password.isEmpty {
            passwordError = String(localized: "error_password_required")
            return
        }
        if password.count < 6 {
            passwordError = String(localized: "error_password_min_length")
            return
        }
        isLoading = true
        HapticManager.impact()
        Task { @MainActor in
            do {
                try await appState.authService.signIn(email: email, password: password)
                HapticManager.success()
            } catch {
                generalError = AuthService.userFriendlyMessage(for: error)
            }
            isLoading = false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Forgot Password

struct ForgotPasswordSheet: View {
    let onDismiss: () -> Void
    @EnvironmentObject private var appState: AppState
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var message: String?
    @State private var isSuccess = false
    @FocusState private var focusedField: ForgotPasswordField?

    enum ForgotPasswordField: Hashable { case email }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: AppSpacing.xl) {
                    Text("forgot_password_message")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    FormTextField(
                        title: String(localized: "form_email"),
                        text: $email,
                        placeholder: String(localized: "placeholder_email"),
                        keyboardType: .emailAddress,
                        errorMessage: nil,
                        submitLabel: .go,
                        focusValue: ForgotPasswordField.email,
                        focusedField: $focusedField
                    ) {
                        sendResetLink()
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    if let msg = message {
                        Text(msg)
                            .font(AppTypography.footnote)
                            .foregroundColor(isSuccess ? AppColors.success : AppColors.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    PrimaryButton(title: isLoading ? String(localized: "sending") : String(localized: "button_send_reset_link"), fullWidth: true) {
                        sendResetLink()
                    }
                    .disabled(isLoading || email.isEmpty || !isValidEmail(email))
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer()
                }
                .padding(.top, AppSpacing.xl)
            }
            .navigationTitle("forgot_password_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button_cancel")) {
                        onDismiss()
                    }
                }
            }
        }
    }

    private func sendResetLink() {
        guard isValidEmail(email) else {
            message = String(localized: "error_valid_email")
            isSuccess = false
            return
        }
        message = nil
        isLoading = true
        Task { @MainActor in
            do {
                try await appState.authService.resetPassword(email: email)
                isSuccess = true
                message = String(format: String(localized: "reset_password_sent"), email)
                HapticManager.success()
            } catch {
                isSuccess = false
                message = AuthService.userFriendlyMessage(for: error)
            }
            isLoading = false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: regex, options: .regularExpression) != nil
    }
}

// MARK: - Sign Up

struct SignUpView: View {
    @ObservedObject var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: SignUpField?

    enum SignUpField: Hashable { case email, password, name }

    private var displayName: String {
        !name.isEmpty ? name : (email.components(separatedBy: "@").first ?? "User")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        GlassCard {
                            VStack(spacing: AppSpacing.lg) {
                                FormTextField(
                                    title: String(localized: "form_name"),
                                    text: $name,
                                    placeholder: String(localized: "placeholder_name"),
                                    focusValue: SignUpField.name,
                                    focusedField: $focusedField
                                ) { focusedField = .email }
                                FormTextField(
                                    title: String(localized: "form_email"),
                                    text: $email,
                                    placeholder: String(localized: "placeholder_email"),
                                    keyboardType: .emailAddress,
                                    focusValue: SignUpField.email,
                                    focusedField: $focusedField
                                ) { focusedField = .password }
                                FormTextField(
                                    title: "Password",
                                    text: $password,
                                    placeholder: String(localized: "placeholder_password_min"),
                                    isSecure: true,
                                    focusValue: SignUpField.password,
                                    focusedField: $focusedField
                                ) { }
                                if let err = errorMessage {
                                    Text(err)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.danger)
                                }
                                PrimaryActionButton(title: String(localized: "button_create_account"), icon: "person.badge.plus", action: createAccount)
                                    .disabled(isLoading || email.isEmpty || password.count < 6)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.vertical, AppSpacing.xl)
                }
            }
            .navigationTitle("signup_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(String(localized: "button_cancel")) { appState.showSignUpSheet = false } } }
        }
    }

    private func createAccount() {
        errorMessage = nil
        guard isValidEmail(email) else {
            errorMessage = String(localized: "error_valid_email_signup")
            return
        }
        guard password.count >= 6 else {
            errorMessage = String(localized: "error_password_min_signup")
            return
        }
        isLoading = true
        let nameToUse = displayName
        Task { @MainActor in
            do {
                try await appState.authService.signUp(email: email, password: password)
                appState.pendingDisplayName = nameToUse
                await appState.refetchCurrentUser()
                appState.showSignUpSheet = false
            } catch {
                errorMessage = AuthService.userFriendlyMessage(for: error)
            }
            isLoading = false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return (email.range(of: regex, options: .regularExpression) != nil)
    }
}

// MARK: - Role Selection

struct RoleSelectionView: View {
    @ObservedObject var appState: AppState
    @State private var isCreatingCoach = false

    private var displayName: String {
        appState.pendingDisplayName ?? appState.authService.currentFirebaseUser?.email?.components(separatedBy: "@").first ?? "User"
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                SectionHeader(
                    title: "Choose your role",
                    subtitle: "Are you training athletes or following a coach’s plan?"
                )
                .padding(.top, AppSpacing.lg)

                VStack(spacing: AppSpacing.lg) {
                    NavigationLink {
                        InviteCodeView(appState: appState)
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("role_athlete")
                                    .font(AppTypography.title2)
                                Text("role_athlete_desc")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectCoachRole()
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("role_coach")
                                    .font(AppTypography.title2)
                                Text("role_coach_desc")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isCreatingCoach)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
            if isCreatingCoach {
                ProgressView()
            }
        }
        .navigationTitle("nav_role")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectCoachRole() {
        guard let uid = appState.authService.uid else { return }
        isCreatingCoach = true
        Task { @MainActor in
            defer { isCreatingCoach = false }
            do {
                try await appState.userService.createUser(id: uid, name: displayName, role: .coach)
                await appState.refetchCurrentUser()
            } catch { }
        }
    }
}

// MARK: - Invite Code

struct InviteCodeView: View {
    @ObservedObject var appState: AppState
    @State private var inviteCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var displayName: String {
        appState.pendingDisplayName ?? appState.authService.currentFirebaseUser?.email?.components(separatedBy: "@").first ?? "Athlete"
    }

    /// Normalize to XXXX-XXXX (letters/numbers only, uppercase, max 8 chars).
    private static func formatInviteCode(_ raw: String) -> String {
        let s = String(raw.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(8))
        if s.count <= 4 { return s }
        let idx = s.index(s.startIndex, offsetBy: 4)
        return String(s[..<idx]) + "-" + String(s[idx...].prefix(4))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                SectionHeader(
                    title: String(localized: "invite_title"),
                    subtitle: String(localized: "invite_subtitle")
                )
                .padding(.top, AppSpacing.xl)

                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("invite_code_label")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                        TextField(String(localized: "placeholder_invite_code"), text: $inviteCode)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.characters)
                            .font(AppTypography.headline)
                            .padding(.vertical, AppSpacing.sm)
                            .onChange(of: inviteCode) { _, newValue in
                                inviteCode = Self.formatInviteCode(newValue)
                            }
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(AppColors.border.opacity(0.5)),
                                alignment: .bottom
                            )
                        if let err = errorMessage {
                            Text(err)
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.danger)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .allowsHitTesting(!isLoading)

                Button {
                    continueAsAthlete()
                } label: {
                    LoadingButtonLabel(title: String(localized: "button_continue_label"), icon: "arrow.right", isLoading: isLoading, fullWidth: true)
                }
                .buttonStyle(.plain)
                .disabled(isLoading || normalizedCode.isEmpty)
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
            }
        }
        .navigationTitle("nav_invite_code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var normalizedCode: String {
        inviteCode.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "")
    }

    private func continueAsAthlete() {
        guard !normalizedCode.isEmpty, let uid = appState.authService.uid else {
            errorMessage = String(localized: "error_invite_required")
            return
        }
        errorMessage = nil
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                guard let coachId = try await appState.inviteCodeService.redeemCode(normalizedCode) else {
                    errorMessage = String(localized: "error_invite_invalid")
                    return
                }
                try await appState.userService.createUser(id: uid, name: displayName, role: .athlete, coachId: coachId)
                await appState.refetchCurrentUser()
            } catch {
                errorMessage = AuthService.userFriendlyMessage(for: error)
            }
        }
    }
}

// MARK: - Previews

struct AuthViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                WelcomeView()
            }
            .preferredColorScheme(.dark)
            
            NavigationStack {
                SignInView()
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.dark)

            NavigationStack {
                RoleSelectionView(appState: AppState())
            }
            .preferredColorScheme(.light)

            NavigationStack {
                InviteCodeView(appState: AppState())
            }
            .preferredColorScheme(.dark)
        }
    }
}

