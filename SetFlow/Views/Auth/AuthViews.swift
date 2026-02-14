import SwiftUI
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
                        title: "Train with intention",
                        subtitle: "Personalized strength blocks, designed by your coach and delivered to your wrist.",
                        icon: "figure.strengthtraining.traditional",
                        accentGradient: AppTheme.Gradients.primary
                    )
                    .tag(0)
                    
                    OnboardingSlide(
                        title: "Focus on the next set",
                        subtitle: "Clear live workout mode with timers, progress rings and subtle haptics.",
                        icon: "timer",
                        accentGradient: AppTheme.Gradients.warm
                    )
                    .tag(1)
                    
                    OnboardingSlide(
                        title: "Coaches in sync",
                        subtitle: "Coaches edit plans, send updates and track athlete progress in real time.",
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
                PrimaryActionButton(title: "Continue") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        currentPage = min(currentPage + 1, 2)
                    }
                }
            } else {
                NavigationLink {
                    SignInView()
                } label: {
                    PrimaryActionButtonLabel(title: "Get started", icon: "arrow.right")
                }
                .buttonStyle(.plain)
            }
            
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    currentPage = 2
                }
            } label: {
                Text(currentPage == 2 ? " " : "Skip to sign in")
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
                    
                    Text("SETFLOW")
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
    @State private var signInMethod: SignInMethod? = nil
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var showSignUp: Bool = false
    @State private var navigateToRoleSelection: Bool = false
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
                        
                        // Continue without account
                        continueWithoutAccountSection
                            .padding(.top, AppSpacing.md)
                            .padding(.bottom, AppSpacing.lg)
                        
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
        .background(
            NavigationLink(
                destination: RoleSelectionView(),
                isActive: $navigateToRoleSelection
            ) {
                EmptyView()
            }
            .hidden()
        )
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
            
            Text("SETFLOW")
                .font(AppTypography.monoCaption)
                .foregroundColor(Color.white.opacity(0.8))
                .tracking(2)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Welcome back")
                .font(AppTypography.largeTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Sign in to continue your training journey")
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
                    Text("Continue with Apple")
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
                    Text("Continue with Email")
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
                        title: "Email",
                        text: $email,
                        placeholder: "your@email.com",
                        keyboardType: .emailAddress,
                        errorMessage: emailError,
                        submitLabel: .next,
                        focusValue: Field.email,
                        focusedField: $focusedField
                    ) {
                        focusedField = .password
                    }
                    
                    FormTextField(
                        title: "Password",
                        text: $password,
                        placeholder: "Enter your password",
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
                            // TODO: Implement forgot password flow
                        } label: {
                            Text("Forgot password?")
                                .font(AppTypography.footnote)
                                .foregroundColor(Color.white.opacity(0.8))
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Sign in button
                    Button {
                        handleEmailSignIn()
                    } label: {
                        LoadingButtonLabel(
                            title: "Sign In",
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
    
    // MARK: - Continue Without Account Section
    
    private var continueWithoutAccountSection: some View {
        NavigationLink {
            RoleSelectionView()
        } label: {
            Text("Continue without account")
                .font(AppTypography.footnote)
                .foregroundColor(Color.white.opacity(0.75))
                .underline()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Sign Up Section
    
    private var signUpSection: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("Don't have an account?")
                .font(AppTypography.footnote)
                .foregroundColor(Color.white.opacity(0.7))
            
            Button {
                HapticManager.selection()
                showSignUp = true
                // TODO: Navigate to sign up flow
            } label: {
                Text("Sign up")
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
        Text("By continuing, you agree to SetFlow's Terms of Service and Privacy Policy.")
            .font(AppTypography.caption)
            .foregroundColor(Color.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }
    
    // MARK: - Actions
    
    private func handleAppleSignIn() {
        isLoading = true
        HapticManager.impact()
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            HapticManager.success()
            navigateToRoleSelection = true
        }
    }
    
    private func handleEmailSignIn() {
        // Validate email
        emailError = nil
        passwordError = nil
        
        if email.isEmpty {
            emailError = "Email is required"
            return
        }
        
        if !isValidEmail(email) {
            emailError = "Please enter a valid email"
            return
        }
        
        if password.isEmpty {
            passwordError = "Password is required"
            return
        }
        
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        HapticManager.impact()
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            HapticManager.success()
            navigateToRoleSelection = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Role Selection

struct RoleSelectionView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                SectionHeader(
                    title: "Choose your space",
                    subtitle: "You can always switch later in settings."
                )
                .padding(.top, AppSpacing.lg)
                
                VStack(spacing: AppSpacing.lg) {
                    NavigationLink {
                        InviteCodeView()
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("I'm an athlete")
                                    .font(AppTypography.title2)
                                Text("Follow precise programming from your coach, track every set and see your progress.")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        CoachTabRootView(
                            coach: MockData.sampleCoach,
                            athletes: MockData.sampleAthletes
                        )
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("I'm a coach")
                                    .font(AppTypography.title2)
                                Text("Design blocks, adjust plans on the fly and keep every athlete on track.")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
            }
        }
        .navigationTitle("Role")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Invite Code

struct InviteCodeView: View {
    @State private var inviteCode: String = ""
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                SectionHeader(
                    title: "Connect with your coach",
                    subtitle: "Enter the invite code they sent you."
                )
                .padding(.top, AppSpacing.xl)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Invite code")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("XXXX-XXXX", text: $inviteCode)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.characters)
                            .font(AppTypography.headline)
                            .padding(.vertical, AppSpacing.sm)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(AppColors.border.opacity(0.5)),
                                alignment: .bottom
                            )
                        Text("Mock validation only – code is not checked yet.")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                NavigationLink {
                    AthleteTabRootView(
                        user: MockData.sampleAthlete,
                        plans: MockData.samplePlans
                    )
                } label: {
                    PrimaryActionButtonLabel(title: "Continue", icon: "arrow.right")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
            }
        }
        .navigationTitle("Invite code")
        .navigationBarTitleDisplayMode(.inline)
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
            }
            .preferredColorScheme(.dark)
            
            NavigationStack {
                RoleSelectionView()
            }
            .preferredColorScheme(.light)
            
            NavigationStack {
                InviteCodeView()
            }
            .preferredColorScheme(.dark)
        }
    }
}

