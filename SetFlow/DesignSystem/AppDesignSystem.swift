import SwiftUI

// MARK: - App Theme

enum AppTheme {
    
    // MARK: Colors
    
    enum Colors {
        // Surfaces — Level 0: soft neutral (unified with onboarding), not pure white
        static let background = Color(red: 0.96, green: 0.97, blue: 0.98)
        static let backgroundElevated = Color(.secondarySystemBackground)
        static let card = Color(.secondarySystemBackground)
        
        // Athlete / design system: soft minimalism
        static let backgroundSoft = Color(red: 0.96, green: 0.96, blue: 0.97) // F5F6F7
        static let surfaceCard = Color.white.opacity(0.65)
        static let strokeSoft = Color.white.opacity(0.18)
        
        // Accents (lime glow primary for athlete)
        static let accent = Color(red: 0.11, green: 0.82, blue: 0.82)
        static let primaryAccentLime = Color(red: 0.78, green: 1.0, blue: 0.0)   // C8FF00
        static let primaryAccentLimeDark = Color(red: 0.66, green: 0.88, blue: 0.0) // A8E000
        static let primaryAccentSoft = Color(red: 0.78, green: 1.0, blue: 0.0).opacity(0.35)
        static let accentSecondary = Color(.systemPurple)
        static let accentSoft = Color(.systemGreen)
        
        // Text
        static let textPrimary = Color.primary
        static let textSecondary: Color = .secondary
        static let textMuted: Color = .secondary
        
        // States
        static let border = Color(.separator)
        static let danger = Color(.systemRed)
        static let success = Color(.systemGreen)
        static let warning = Color(.systemOrange)
        
        // Utility
        static let progressBackground = Color(.systemGray5)
    }
    
    // MARK: Typography
    
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 15, weight: .medium, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
        static let monoCaption = Font.system(size: 11, weight: .medium, design: .monospaced)
    }
    
    // MARK: Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: Corners
    
    enum Corners {
        static let pill: CGFloat = 999
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 28
    }
    
    // MARK: Shadows (unified: idle / lifted / pressed)
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        /// Idle: soft, low radius (cards at rest)
        static let idle = ShadowStyle(
            color: Color.black.opacity(0.06),
            radius: 16,
            x: 0,
            y: 6
        )
        /// Lifted: floating surfaces, bars
        static let lifted = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 24,
            x: 0,
            y: 10
        )
        /// Pressed: magnetic state (reduced)
        static let pressed = ShadowStyle(
            color: Color.black.opacity(0.06),
            radius: 6,
            x: 0,
            y: 4
        )
        static let subtle = ShadowStyle(
            color: Color.black.opacity(0.10),
            radius: 16,
            x: 0,
            y: 10
        )
        static let softCard = ShadowStyle(
            color: Color.black.opacity(0.18),
            radius: 24,
            x: 0,
            y: 18
        )
        static let floating = ShadowStyle(
            color: Color.black.opacity(0.25),
            radius: 30,
            x: 0,
            y: 24
        )
    }
    
    // MARK: Gradients
    
    enum Gradients {
        /// Lime glow primary (athlete CTA, Start button DNA)
        static let primaryLime = LinearGradient(
            colors: [
                Color(red: 0.78, green: 1.0, blue: 0.0),
                Color(red: 0.66, green: 0.88, blue: 0.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let primary = LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.82, blue: 0.82),
                Color(red: 0.40, green: 0.47, blue: 0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warm = LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.63, blue: 0.33),
                Color(red: 0.93, green: 0.23, blue: 0.46)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardOverlay = LinearGradient(
            colors: [
                Color.black.opacity(0.0),
                Color.black.opacity(0.35)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: Materials
    
    enum Materials {
        static let glass = AnyShapeStyle(.ultraThinMaterial)
        static let navBar = AnyShapeStyle(.thinMaterial)
        static let bottomBar = AnyShapeStyle(.regularMaterial)
    }
}

// MARK: - Convenience aliases for existing code

typealias AppColors = AppTheme.Colors
typealias AppTypography = AppTheme.Typography
typealias AppSpacing = AppTheme.Spacing

extension View {
    func appShadow(_ style: AppTheme.ShadowStyle = .subtle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// Soft nav bar background so it doesn’t float on pure white; use on root views inside NavigationStack.
    func softNavigationBarBackground() -> some View {
        toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Material.ultraThinMaterial.opacity(0.4), for: .navigationBar)
    }
}

