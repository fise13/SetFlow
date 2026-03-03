//
//  WorkoutActionBar.swift
//  SetFlow
//
//  Floating bottom action bar: tab icons + Start button with full animation suite.
//

import SwiftUI

// MARK: - Tab

enum Tab: String, CaseIterable {
    case home
    case stats
    case saved
}

// MARK: - Start Button Phase (state for morph animation)

enum StartButtonPhase: Equatable {
    case idle
    case phase1Expand      // capsule expand, arrow slide
    case phase2Loading    // arrow → loading circle
    case phase3Success    // flash, checkmark
}

// MARK: - WorkoutActionBar

struct WorkoutActionBar: View {
    /// Когда `nil` — экран Workout (после Start), ни одна иконка не подсвечена.
    @Binding var selectedTab: Tab?
    var onStart: () -> Void

    @State private var breathingScale: CGFloat = Motion.Breathing.scaleMin
    @State private var breathingShadowRadius: CGFloat = Motion.Breathing.shadowRadiusMin
    @State private var isBarPressed = false
    @State private var isLifted = false
    @State private var hasAppeared = false

    /// Фиксированная высота бара, чтобы не растягиваться и не перекрывать контент.
    private static let barHeight: CGFloat = 56

    var body: some View {
        HStack(spacing: 0) {
            tabIconsSection
            Spacer(minLength: AppSpacing.md)
            AnimatedStartButton(onTap: handleStartTap, onLiftChange: { isLifted = $0 })
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md + 2)
        .frame(height: Self.barHeight)
        .frame(maxWidth: .infinity)
        .background(panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous)
                .strokeBorder(AppColors.strokeSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous))
        .scaleEffect(barScale)
        .clipped()
        .offset(y: barOffsetY)
        .shadow(
            color: AppTheme.ShadowStyle.lifted.color,
            radius: currentShadowRadius,
            x: AppTheme.ShadowStyle.lifted.x,
            y: isLifted ? 14 : AppTheme.ShadowStyle.lifted.y
        )
        .opacity(entranceOpacity)
        .offset(y: entranceOffsetY)
        .blur(radius: entranceBlur)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous))
        .simultaneousGesture(barPressGesture)
        .onAppear(perform: startEntranceAndBreathing)
    }

    private var barScale: CGFloat {
        isBarPressed ? Motion.Press.magneticScale : breathingScale
    }

    private var barOffsetY: CGFloat {
        isLifted ? Motion.Activation.liftOffsetY : 0
    }

    private var currentShadowRadius: CGFloat {
        if isBarPressed { return Motion.Press.pressedShadowRadius }
        return breathingShadowRadius
    }

    private var entranceOpacity: Double {
        hasAppeared ? 1 : 0
    }

    private var entranceOffsetY: CGFloat {
        hasAppeared ? 0 : Motion.Entrance.initialOffsetY
    }

    private var entranceBlur: CGFloat {
        hasAppeared ? 0 : Motion.Entrance.initialBlur
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous)
            .fill(AppTheme.Materials.glass)
    }

    private var barPressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isBarPressed {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                        isBarPressed = true
                    }
                }
            }
            .onEnded { _ in
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.75)) {
                    isBarPressed = false
                }
            }
    }

    private func startEntranceAndBreathing() {
        withAnimation(.easeOut(duration: Motion.Entrance.duration)) {
            hasAppeared = true
        }
        let breathing = Animation.easeInOut(duration: Motion.Breathing.duration).repeatForever(autoreverses: true)
        withAnimation(breathing) {
            breathingScale = Motion.Breathing.scaleMax
            breathingShadowRadius = Motion.Breathing.shadowRadiusMax
        }
    }

    private func handleStartTap() {
        onStart()
    }

    // MARK: - Tab Icons (design system IconToggle)

    private var tabIconsSection: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(Tab.allCases, id: \.self) { tab in
                IconToggle(
                    icon: tab.sfSymbolName,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.spring(
                            response: Motion.Selection.springResponse,
                            dampingFraction: Motion.Selection.springDamping
                        )) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Animated Start Button (extracted, phase-driven)

private struct AnimatedStartButton: View {
    let onTap: () -> Void
    var onLiftChange: ((Bool) -> Void)? = nil

    @State private var phase: StartButtonPhase = .idle
    @State private var glowOpacity: Double = 0

    private static let startGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.92, blue: 0.55),
            Color(red: 0.95, green: 0.85, blue: 0.40)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        Button(action: triggerStartSequence) {
            ZStack {
                // Glow behind capsule (activation)
                Capsule(style: .continuous)
                    .fill(Self.startGradient)
                    .blur(radius: Motion.Activation.glowBlurRadius)
                    .opacity(glowOpacity)
                    .scaleEffect(1.3)

                HStack(spacing: AppSpacing.sm + 2) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 36, height: 36)
                        startButtonCenterContent
                    }
                    .offset(x: phase == .phase1Expand ? Motion.StartButton.phase1ArrowOffsetX : 0)

                    Text("Start")
                        .font(AppTypography.headline)
                        .foregroundStyle(.black)
                }
                .padding(.leading, AppSpacing.xs + 2)
                .padding(.trailing, AppSpacing.lg)
                .frame(height: 44)
                .scaleEffect(capsuleScale)
                .background(
                    Capsule(style: .continuous)
                        .fill(Self.startGradient)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(phase == .phase3Success ? 0.8 : 0.4), lineWidth: 0.5)
                        .blur(radius: 0.5)
                )
                .shadow(color: Color(red: 0.95, green: 0.85, blue: 0.35).opacity(phase == .phase3Success ? 0.9 : 0.6), radius: 10, x: 0, y: 2)
            }
        }
        .buttonStyle(StartButtonMagneticStyle())
    }

    @ViewBuilder
    private var startButtonCenterContent: some View {
        switch phase {
        case .idle, .phase1Expand:
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        case .phase2Loading:
            LoadingTrimCircle()
        case .phase3Success:
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var capsuleScale: CGFloat {
        switch phase {
        case .phase1Expand: return Motion.StartButton.phase1CapsuleScale
        case .phase2Loading, .phase3Success, .idle: return 1.0
        }
    }

    private func triggerStartSequence() {
        onLiftChange?(true)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            glowOpacity = Motion.Activation.glowOpacityMax
        }
        // Phase 1: expand + стрелка и чёрный круг уезжают вправо
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            phase = .phase1Expand
        }
        // Phase 2: loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = .phase2Loading
            }
        }
        // Phase 3: success + callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Motion.StartButton.loadingTrimDuration) {
            onTap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                phase = .phase3Success
            }
            // Reset and lift down
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) {
                    glowOpacity = 0
                    phase = .idle
                    onLiftChange?(false)
                }
            }
        }
    }
}

// MARK: - Loading Trim Circle (Phase 2)

private struct LoadingTrimCircle: View {
    @State private var trimEnd: CGFloat = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: trimEnd)
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(-90))
            .onAppear {
                withAnimation(.easeInOut(duration: Motion.StartButton.loadingTrimDuration).repeatCount(1, autoreverses: false)) {
                    trimEnd = 1.0
                }
            }
            .onDisappear { trimEnd = 0 }
    }
}

// MARK: - Button Styles

private struct ActionBarScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct StartButtonMagneticStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Tab SF Symbol

private extension Tab {
    var sfSymbolName: String {
        switch self {
        case .home: return "house"
        case .stats: return "chart.line.uptrend.xyaxis"
        case .saved: return "bookmark"
        }
    }
}

// MARK: - Coach Action Bar (тот же стиль, что у атлета: стекло, дыхание, вход)

struct CoachActionBar: View {
    @Binding var selectedTab: CoachTab

    @State private var breathingScale: CGFloat = Motion.Breathing.scaleMin
    @State private var breathingShadowRadius: CGFloat = Motion.Breathing.shadowRadiusMin
    @State private var isBarPressed = false
    @State private var hasAppeared = false

    private static let barHeight: CGFloat = 56

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(CoachTab.allCases, id: \.self) { tab in
                CoachTabIconButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.spring(
                            response: Motion.Selection.springResponse,
                            dampingFraction: Motion.Selection.springDamping
                        )) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md + 2)
        .frame(height: Self.barHeight)
        .frame(maxWidth: .infinity)
        .background(panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous)
                .strokeBorder(AppColors.strokeSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous))
        .scaleEffect(isBarPressed ? Motion.Press.magneticScale : breathingScale)
        .clipped()
        .shadow(
            color: AppTheme.ShadowStyle.lifted.color,
            radius: isBarPressed ? Motion.Press.pressedShadowRadius : breathingShadowRadius,
            x: AppTheme.ShadowStyle.lifted.x,
            y: AppTheme.ShadowStyle.lifted.y
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : Motion.Entrance.initialOffsetY)
        .blur(radius: hasAppeared ? 0 : Motion.Entrance.initialBlur)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous))
        .simultaneousGesture(barPressGesture)
        .onAppear(perform: startEntranceAndBreathing)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.Corners.xl, style: .continuous)
            .fill(AppTheme.Materials.glass)
    }

    private var barPressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isBarPressed {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                        isBarPressed = true
                    }
                }
            }
            .onEnded { _ in
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.75)) {
                    isBarPressed = false
                }
            }
    }

    private func startEntranceAndBreathing() {
        withAnimation(.easeOut(duration: Motion.Entrance.duration)) {
            hasAppeared = true
        }
        let breathing = Animation.easeInOut(duration: Motion.Breathing.duration).repeatForever(autoreverses: true)
        withAnimation(breathing) {
            breathingScale = Motion.Breathing.scaleMax
            breathingShadowRadius = Motion.Breathing.shadowRadiusMax
        }
    }
}

private struct CoachTabIconButton: View {
    let tab: CoachTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .symbolVariant(isSelected ? .fill : .none)
                .foregroundStyle(isSelected ? .white : Color(.systemGray2))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .scaleEffect(isSelected ? Motion.Selection.selectedScale : 1.0)
                .opacity(isSelected ? Motion.Selection.selectedOpacity : Motion.Selection.unselectedOpacity)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Corners.sm, style: .continuous)
                        .fill(isSelected ? Color.black : Color.clear)
                )
        }
        .buttonStyle(ActionBarScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview("WorkoutActionBar") {
    struct PreviewWrapper: View {
        @State private var selectedTab: Tab? = .home

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    WorkoutActionBar(selectedTab: $selectedTab) {
                        // onStart
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .preferredColorScheme(.light)
        }
    }
    return PreviewWrapper()
}
