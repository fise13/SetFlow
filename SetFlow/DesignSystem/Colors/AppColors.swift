//
//  AppColors.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — цветовая система.
//

import SwiftUI

// MARK: - Semantic Colors (Glass UI Kit — не конфликтует с AppTheme.Colors / AppColors)

enum GlassColors {
    /// Level 0: мягкий холодный нейтральный фон экрана (245, 247, 250) — не серый, не чисто белый.
    static let background = Color(red: 0.96, green: 0.97, blue: 0.98)
    
    /// Level 1: поверхность для карточек — белый с лёгкой прозрачностью.
    static let surfaceWhite = Color.white.opacity(0.92)
    
    /// Поверхность для glass-карточек (используется с ultraThinMaterial)
    static let glassBackground = Color.white.opacity(0.65)
    
    /// Неоново лаймовый акцент
    static let primaryAccent = Color(hex: "C8FF00")
    
    /// Лаймовый с пониженной насыщенностью для фонов
    static let primaryAccentSoft = Color(hex: "C8FF00").opacity(0.35)
    
    /// Почти чёрный — основной текст
    static let textPrimary = Color(hex: "1C1C1E")
    
    /// Серый — вторичный текст
    static let textSecondary = Color(hex: "6B6B70")
    
    /// Светло-серый для неактивных иконок
    static let iconInactive = Color(hex: "AEAEB2")
    
    /// Тонкая обводка для границ
    static let strokeSoft = Color(hex: "C6C6C8").opacity(0.6)
    
    /// Для затемнённых overlay
    static let overlay = Color.black.opacity(0.08)
}

// MARK: - Color Extension (convenience)

extension Color {
    static let appBackground = GlassColors.background
    static let appSurfaceWhite = GlassColors.surfaceWhite
    static let appGlass = GlassColors.glassBackground
    static let appAccent = GlassColors.primaryAccent
    static let appAccentSoft = GlassColors.primaryAccentSoft
    static let appTextPrimary = GlassColors.textPrimary
    static let appTextSecondary = GlassColors.textSecondary
}

// MARK: - Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
