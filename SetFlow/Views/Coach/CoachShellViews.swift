import SwiftUI

// MARK: - Send Update (Top-level)

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

// MARK: - Updates + Profile Shells (Top-level)

struct CoachUpdatesView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    SectionHeader(
                        title: "Recent updates",
                        subtitle: "What your athletes will see next"
                    )
                    
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
        }
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CoachProfileView: View {
    let coach: User
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
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
                    
                    SectionHeader(title: "Workspace", actionTitle: nil, action: nil)
                    
                    VStack(spacing: AppSpacing.md) {
                        SecondaryButton(title: "Billing & subscription") { }
                        SecondaryButton(title: "Export data") { }
                        SecondaryButton(title: "Sign out") { }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

