import SwiftUI

// MARK: - App Theme

enum AppTheme {
    
    // MARK: Colors
    
    enum Colors {
        // Surfaces
        static let background = Color("Background", bundle: .main).resolveFallback(.init(.systemBackground))
        static let backgroundElevated = Color("BackgroundElevated", bundle: .main).resolveFallback(.init(.secondarySystemBackground))
        static let card = Color("Card", bundle: .main).resolveFallback(.init(.secondarySystemBackground))
        
        // Accents
        static let accent = Color("Accent", bundle: .main).resolveFallback(.init(.systemTeal))
        static let accentSecondary = Color("AccentSecondary", bundle: .main).resolveFallback(.init(.systemPurple))
        static let accentSoft = Color("AccentSoft", bundle: .main).resolveFallback(.init(.systemGreen))
        
        // Text
        static let textPrimary = Color("TextPrimary", bundle: .main).resolveFallback(.primary)
        // Use system colors directly to avoid runtime warnings when asset entries are missing.
        static let textSecondary: Color = .secondary
        static let textMuted: Color = .secondary
        
        // States
        static let border = Color("Border", bundle: .main).resolveFallback(.init(.separator))
        static let danger = Color("Danger", bundle: .main).resolveFallback(.init(.systemRed))
        static let success = Color("Success", bundle: .main).resolveFallback(.init(.systemGreen))
        static let warning = Color("Warning", bundle: .main).resolveFallback(.init(.systemOrange))
        
        // Utility
        static let progressBackground = Color("ProgressBackground", bundle: .main).resolveFallback(.init(.systemGray5))
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
    
    // MARK: Shadows
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
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

// MARK: - Helpers

private extension Color {
    /// Fallback to system color if asset is missing
    func resolveFallback(_ fallback: Color) -> Color {
        #if os(iOS)
        // In practice this just returns self; fallback is here for non-asset builds.
        return self
        #else
        return fallback
        #endif
    }
}

extension View {
    func appShadow(_ style: AppTheme.ShadowStyle = .subtle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

