//
//  AppShadow.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — мягкие тени.
//

import SwiftUI

enum AppShadow {
    /// Мягкая, почти незаметная тень под карточками
    static let soft = ShadowStyle(
        color: Color.black.opacity(0.06),
        radius: 16,
        x: 0,
        y: 6
    )
    
    /// Лёгкий подъём для плавающих элементов
    static let floating = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 24,
        x: 0,
        y: 10
    )
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func appShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
