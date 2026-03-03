//
//  AppComponentsKit.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — UI Kit компоненты.
//

import SwiftUI

// MARK: - Glass Card (контейнер, soft glass UI Kit — не конфликтует с AppComponents.GlassCard)

struct KitGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = AppRadius.card
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
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

// MARK: - Soft Icon Button

struct SoftIconButton: View {
    let icon: String
    var isActive: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .symbolVariant(isActive ? .fill : .none)
                .foregroundStyle(isActive ? GlassColors.primaryAccent : GlassColors.iconInactive)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(isActive ? GlassColors.primaryAccentSoft : Color.white.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .strokeBorder(isActive ? Color.clear : GlassColors.strokeSoft, lineWidth: 1)
                )
        }
        .buttonStyle(GlassScaleButtonStyle())
    }
}

// MARK: - Primary Start Button (капсула + градиент лайм + стрелка в круге)

struct PrimaryStartButton: View {
    let title: String
    let action: () -> Void
    
    private let gradient = LinearGradient(
        colors: [
            Color(hex: "C8FF00"),
            Color(hex: "A8E000")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: GlassSpacing.sm) {
                Text(title)
                    .font(AppFont.buttonText)
                    .foregroundStyle(.black)
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.leading, GlassSpacing.md)
            .padding(.trailing, GlassSpacing.xs + 2)
            .padding(.vertical, GlassSpacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(gradient)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: GlassColors.primaryAccent.opacity(0.4), radius: 10, x: 0, y: 2)
        }
        .buttonStyle(GlassScaleButtonStyle())
    }
}

// MARK: - Tab Bar (плавающий: 3 иконки + start button)

struct FitnessTabBar: View {
    struct Item: Identifiable {
        let id: Int
        let icon: String
        let label: String
    }
    
    let items: [Item]
    @Binding var selection: Int
    let startTitle: String
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: GlassSpacing.sm) {
                ForEach(items) { item in
                    SoftIconButton(
                        icon: item.icon,
                        isActive: selection == item.id,
                        action: { selection = item.id }
                    )
                }
            }
            Spacer(minLength: GlassSpacing.sm)
            PrimaryStartButton(title: startTitle, action: onStart)
        }
        .padding(.horizontal, GlassSpacing.lg)
        .padding(.vertical, GlassSpacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(GlassColors.strokeSoft, lineWidth: 1)
                )
        )
        .appShadow(AppShadow.soft)
    }
}

// MARK: - Soft List Item

struct SoftListItem<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(GlassSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .strokeBorder(GlassColors.strokeSoft.opacity(0.5), lineWidth: 1)
                    )
            )
            .appShadow(AppShadow.soft)
    }
}

// MARK: - Scale Button Style (анимация нажатия)

struct GlassScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
