//
//  AppLayouts.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — экранные контейнеры и секции.
//

import SwiftUI

// MARK: - Screen Container (базовый контейнер экрана)

struct ScreenContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            AppBackground()
            content()
                .padding(.horizontal, GlassSpacing.lg)
                .padding(.top, GlassSpacing.sm)
                .padding(.bottom, GlassSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section Container (секция с отступами и плавающими блоками)

struct SectionContainer<Content: View>: View {
    var title: String? = nil
    var subtitle: String? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: GlassSpacing.md) {
            if let title = title {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .appFont(AppFont.titleSmall)
                        .foregroundStyle(GlassColors.textPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .appFont(AppFont.caption)
                            .foregroundStyle(GlassColors.textSecondary)
                    }
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
