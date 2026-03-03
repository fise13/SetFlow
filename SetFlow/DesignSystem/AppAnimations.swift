//
//  AppAnimations.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — анимации.
//  Unified motion system: idle breathing, press, activation, entrance.
//

import SwiftUI

enum AppAnimations {
    /// Пружина для переключений табов и состояний
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    
    /// Мягкое появление карточек
    static let cardAppear = Animation.easeOut(duration: 0.4)
    
    /// Длительность для glow
    static let glowDuration: Double = 0.6
}

// MARK: - Motion (unified constants for bars, buttons, cards)

enum Motion {
    enum Breathing {
        static let duration: Double = 3.5
        static let scaleMin: CGFloat = 1.0
        static let scaleMax: CGFloat = 1.02
        static let shadowRadiusMin: CGFloat = 8
        static let shadowRadiusMax: CGFloat = 14
    }
    enum Selection {
        static let springResponse: Double = 0.35
        static let springDamping: Double = 0.7
        static let selectedScale: CGFloat = 1.2
        static let selectedOpacity: Double = 1.0
        static let unselectedOpacity: Double = 0.5
    }
    enum Press {
        static let magneticScale: CGFloat = 0.96
        static let pressedShadowRadius: CGFloat = 6
    }
    enum Activation {
        static let liftOffsetY: CGFloat = -8
        static let glowBlurRadius: CGFloat = 20
        static let glowOpacityMax: Double = 0.7
    }
    enum Entrance {
        static let initialOffsetY: CGFloat = 40
        static let initialBlur: CGFloat = 10
        static let duration: Double = 0.5
    }
    enum StartButton {
        static let phase1CapsuleScale: CGFloat = 1.15
        static let phase1ArrowOffsetX: CGFloat = 28
        static let loadingTrimDuration: Double = 0.8
    }
}

// MARK: - View Extensions для анимаций

extension View {
    /// Плавное появление с лёгким смещением снизу
    func softAppear(delay: Double = 0) -> some View {
        modifier(SoftAppearModifier(delay: delay))
    }
}

struct SoftAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                withAnimation(AppAnimations.cardAppear.delay(delay)) {
                    appeared = true
                }
            }
    }
}
