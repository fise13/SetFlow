//
//  AppModifiers.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — базовые модификаторы.
//

import SwiftUI

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.card
    
    func body(content: Content) -> some View {
        content
            .padding(GlassSpacing.lg)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(GlassColors.glassBackground.opacity(0.5))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(GlassColors.strokeSoft, lineWidth: 1)
                }
            }
            .appShadow(AppShadow.soft)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppRadius.card) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Floating Modifier

struct FloatingModifier: ViewModifier {
    var depth: CGFloat = 4
    
    func body(content: Content) -> some View {
        content
            .appShadow(AppShadow.floating)
            .opacity(0.98)
    }
}

extension View {
    func floating(depth: CGFloat = 4) -> some View {
        modifier(FloatingModifier(depth: depth))
    }
}
