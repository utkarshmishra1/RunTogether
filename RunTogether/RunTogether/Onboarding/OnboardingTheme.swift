//
//  OnboardingTheme.swift
//  RunTogether
//

import SwiftUI

enum OnboardingTheme {
    // Brand orange — matches splash screen exactly
    static let orange      = Color(red: 0xFF/255, green: 0x7B/255, blue: 0x2B/255)
    static let orangeDeep  = Color(red: 0xFF/255, green: 0x5A/255, blue: 0x1F/255)
    static let orangeGlow  = Color(red: 0xFF/255, green: 0x8C/255, blue: 0x50/255)

    // Accent colors for events / leaderboard
    static let neon        = Color(red: 0x00/255, green: 0xD4/255, blue: 0xFF/255)
    static let neonDeep    = Color(red: 0x00/255, green: 0x96/255, blue: 0xC7/255)
    static let yellow      = Color(red: 0xFF/255, green: 0xD9/255, blue: 0x3D/255)

    // Navy gradient — matches splash bgTop / bgMid / bgBottom exactly
    static let navy        = Color(red: 0x0E/255, green: 0x1F/255, blue: 0x4A/255)
    static let navyMid     = Color(red: 0x0B/255, green: 0x1A/255, blue: 0x3F/255)
    static let navyDeep    = Color(red: 0x0A/255, green: 0x17/255, blue: 0x38/255)
    static let navyLight   = Color(red: 0x1B/255, green: 0x26/255, blue: 0x3B/255)

    // Text — splash uses 0xE5EAF6 for tagline; we keep that as `tagline` and
    // use a soft white for headlines.
    static let text        = Color.white
    static let textSoft    = Color.white.opacity(0.72)
    static let tagline     = Color(red: 0xE5/255, green: 0xEA/255, blue: 0xF6/255)

    static let surface     = Color.white.opacity(0.06)
    static let surface2    = Color.white.opacity(0.10)
    static let border      = Color.white.opacity(0.10)
}

struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            // 3-stop navy gradient — matches splash exactly
            LinearGradient(
                colors: [OnboardingTheme.navy, OnboardingTheme.navyMid, OnboardingTheme.navyDeep],
                startPoint: .top, endPoint: .bottom
            )
            // Subtle warm glow near top, cool glow at bottom
            RadialGradient(
                colors: [OnboardingTheme.orange.opacity(0.10), .clear],
                center: UnitPoint(x: 0.3, y: 0.0),
                startRadius: 0, endRadius: 380
            )
            RadialGradient(
                colors: [OnboardingTheme.neon.opacity(0.06), .clear],
                center: UnitPoint(x: 0.85, y: 1.0),
                startRadius: 0, endRadius: 360
            )
            EmbersField()
        }
        .ignoresSafeArea()
    }
}

private struct EmbersField: View {
    private struct Ember {
        let xPct: Double
        let yPct: Double
        let color: Color
        let radius: CGFloat
    }
    private let embers: [Ember] = [
        .init(xPct: 0.20, yPct: 0.30, color: OnboardingTheme.orangeGlow.opacity(0.6),  radius: 2),
        .init(xPct: 0.60, yPct: 0.70, color: OnboardingTheme.neon.opacity(0.5),         radius: 1.5),
        .init(xPct: 0.80, yPct: 0.20, color: OnboardingTheme.yellow.opacity(0.5),       radius: 1.5),
        .init(xPct: 0.40, yPct: 0.80, color: OnboardingTheme.orange.opacity(0.55),      radius: 2),
        .init(xPct: 0.10, yPct: 0.60, color: OnboardingTheme.orangeGlow.opacity(0.5),   radius: 1.5),
    ]

    @State private var start = Date().timeIntervalSinceReferenceDate

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate - start
            // 30s drift loop, sin wave for vertical/horizontal
            let phase = sin(t * .pi * 2 / 30)
            let dy = -30.0 * (0.5 + 0.5 * phase)
            let dx =  20.0 * (0.5 + 0.5 * phase)
            let opacity = 0.7 + 0.3 * phase

            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    ForEach(Array(embers.enumerated()), id: \.offset) { _, e in
                        Circle()
                            .fill(e.color)
                            .frame(width: e.radius * 2, height: e.radius * 2)
                            .blur(radius: 1.5)
                            .position(
                                x: e.xPct * w + dx,
                                y: e.yPct * h + dy
                            )
                    }
                }
                .opacity(opacity)
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = 18

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(OnboardingTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(OnboardingTheme.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.30), radius: 11, y: 8)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.25)
            )
    }
}

extension View {
    func eyebrow() -> some View {
        self
            .font(.system(size: 11, weight: .heavy))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundColor(OnboardingTheme.orange)
    }
    func headline() -> some View {
        self
            .font(.system(size: 26, weight: .heavy))
            .foregroundColor(OnboardingTheme.text)
            .lineSpacing(2)
    }
    func subcopy() -> some View {
        self
            .font(.system(size: 14.5, weight: .regular))
            .foregroundColor(OnboardingTheme.textSoft)
            .lineSpacing(3)
    }
}
