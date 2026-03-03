//
//  SoftSurfaceContainer.swift
//  SetFlow
//
//  Level 1 surface: content sections, cards, plan blocks. Soft depth separation.
//

import SwiftUI

private enum SoftSurfaceShadow {
    static let radius: CGFloat = 12
    static let y: CGFloat = 4
    static let opacity: Double = 0.06
}

/// Soft elevated surface — white with slight opacity, 24pt radius, subtle shadow.
/// Use for content sections, cards, plan blocks, tab areas.
struct SoftSurfaceContainer<Content: View>: View {
    var cornerRadius: CGFloat = 24
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(GlassColors.surfaceWhite)
            )
            .shadow(
                color: Color.black.opacity(SoftSurfaceShadow.opacity),
                radius: SoftSurfaceShadow.radius,
                x: 0,
                y: SoftSurfaceShadow.y
            )
    }
}
