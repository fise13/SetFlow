import SwiftUI

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
                    PrimaryActionButton(title: "Get started", icon: "arrow.right") { }
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

struct SignInView: View {
    var body: some View {
        ZStack {
            AppTheme.Gradients.primary
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                VStack(spacing: AppSpacing.sm) {
                    Text("Welcome to SetFlow")
                        .font(AppTypography.title1)
                        .foregroundColor(.white)
                    Text("Log in to sync your training with your coach.")
                        .font(AppTypography.body)
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                .padding(.top, AppSpacing.xxxl)
                
                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        PrimaryActionButton(title: "Sign in with Apple", icon: "apple.logo") {
                            // Placeholder for Sign in with Apple
                        }
                        
                        SecondaryButton(title: "Sign in with email") {
                            // Placeholder for email sign in
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                NavigationLink {
                    RoleSelectionView()
                } label: {
                    Text("Continue without account")
                        .font(AppTypography.footnote)
                        .foregroundColor(Color.white.opacity(0.8))
                        .underline()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("By continuing you agree to the Terms & Privacy Policy.")
                    .font(AppTypography.footnote)
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
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
                    PrimaryActionButton(title: "Continue", icon: "arrow.right") { }
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

