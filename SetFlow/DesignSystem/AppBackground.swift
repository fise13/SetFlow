//
//  AppBackground.swift
//  SetFlow
//
//  Soft glass / minimal neon fitness — глобальный фон приложения.
//  Адаптируется к светлой и тёмной теме.
//

import SwiftUI

/// Level 0: default screen background — soft cool neutral, premium and calm (not grey, not pure white).
private enum BackgroundPalette {
    /// RGB 245, 247, 250 — soft elevated neutral for light theme.
    static let lightBase = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let lightTop = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let lightBottom = Color(red: 0.94, green: 0.95, blue: 0.97)
    static let darkTop = Color(hex: "1C1C1E")
    static let darkMid = Color(hex: "2C2C2E")
    static let darkBottom = Color(hex: "0D0D0F")
}

/// Мягкий градиентный фон с лёгким ощущением глубины. В тёмной теме — тёмный фон.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                darkGradient
            } else {
                lightGradient
            }
            if colorScheme == .dark {
                NoiseOverlayView(dark: true, opacity: 0.04)
                    .ignoresSafeArea()
            } else {
                NoiseOverlayView(dark: false, opacity: 0.025)
                    .ignoresSafeArea()
            }
        }
    }

    private var lightGradient: some View {
        LinearGradient(
            colors: [
                BackgroundPalette.lightTop,
                BackgroundPalette.lightBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var darkGradient: some View {
        LinearGradient(
            colors: [
                BackgroundPalette.darkTop,
                BackgroundPalette.darkMid,
                BackgroundPalette.darkBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

/// Минимальный шум для текстуры фона.
private struct NoiseOverlayView: View {
    let dark: Bool
    let opacity: Double

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let count = Int(size.width * size.height / 120)
                let dotColor = dark ? Color.white : Color.white
                for _ in 0..<count {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(dotColor.opacity(opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
