//
//  AppFont.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — типографика.
//

import SwiftUI

// MARK: - App Typography

enum AppFont {
    /// Крупный заголовок — Bold
    static let titleLarge = Font.system(size: 28, weight: .bold, design: .rounded)
    
    /// Средний заголовок
    static let titleMedium = Font.system(size: 22, weight: .semibold, design: .rounded)
    
    /// Подзаголовок
    static let titleSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
    
    /// Основной текст — regular / light
    static let bodySoft = Font.system(size: 16, weight: .regular, design: .rounded)
    
    /// Мягкое описание
    static let bodyLight = Font.system(size: 15, weight: .light, design: .rounded)
    
    /// Текст кнопок — medium
    static let buttonText = Font.system(size: 16, weight: .medium, design: .rounded)
    
    /// Подписи и метки
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    
    /// Мелкий текст
    static let footnote = Font.system(size: 12, weight: .regular, design: .rounded)
}

// MARK: - View + Font Modifier (optional convenience)

extension View {
    func appFont(_ font: Font) -> some View {
        self.font(font)
    }
}
