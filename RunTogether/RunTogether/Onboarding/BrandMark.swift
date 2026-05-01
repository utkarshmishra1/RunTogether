//
//  BrandMark.swift
//  RunTogether
//
//  The orange-rounded-square chevron logo from the splash screen.
//  Used on the onboarding welcome screen so the brand identity carries through.

import SwiftUI

struct BrandMark: View {
    /// Outer square size. Splash uses 130; onboarding uses 130 too.
    var size: CGFloat = 130

    /// Reference size used to author the chevron pair's internal coordinates.
    /// We scale the pair to fit `size` while preserving its centered layout.
    private let chevronReferenceSize: CGFloat = 70
    private let plateReferenceSize: CGFloat = 130

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                // Orange rounded-square plate
                RoundedRectangle(cornerRadius: size * 0.215, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [OnboardingTheme.orange, OnboardingTheme.orangeDeep],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.215, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            .blendMode(.plusLighter)
                            .mask(
                                LinearGradient(colors: [.white, .clear],
                                               startPoint: .top, endPoint: .center)
                            )
                    )
                    .shadow(color: OnboardingTheme.orangeDeep.opacity(0.35), radius: 20, y: 18)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 4)

                // White chevron pair — render at native 70×70 reference and
                // scale to match the plate so it stays centered at any size.
                BrandChevronPair(elapsed: elapsed)
                    .frame(width: chevronReferenceSize, height: chevronReferenceSize)
                    .scaleEffect(size / plateReferenceSize)
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Plateless emblem — chevron pair only, used on the welcome screen

/// The white chevron pair without the orange rounded-square plate.
/// A soft warm glow sits behind it so it still feels brand-anchored.
struct BrandChevronEmblem: View {
    var size: CGFloat = 150
    private let chevronReferenceSize: CGFloat = 70

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                // Soft orange halo behind the chevrons
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                OnboardingTheme.orange.opacity(0.45),
                                OnboardingTheme.orange.opacity(0.10),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.7
                        )
                    )
                    .frame(width: size * 1.6, height: size * 1.6)
                    .blur(radius: 20)

                BrandChevronPair(elapsed: elapsed)
                    .frame(width: chevronReferenceSize, height: chevronReferenceSize)
                    .scaleEffect(size / chevronReferenceSize)
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Chevron pair (looping rise) — same animation as splash

struct BrandChevronPair: View {
    let elapsed: Double

    var body: some View {
        ZStack {
            chevron(delay: 0.0, topBase: 10)
            chevron(delay: 0.2, topBase: 34)
        }
    }

    private func chevron(delay: Double, topBase: CGFloat) -> some View {
        let raw = (elapsed - delay) / 1.6
        let c = raw < 0 ? 0 : raw - floor(raw)

        // y: 0 -> -14 over 0..1 (piecewise easing)
        let y: Double = {
            if c < 0.6 { return 10 + (-6 - 10) * easeOut(c / 0.6) }
            return -6 + (-14 - (-6)) * easeInOut((c - 0.6) / 0.4)
        }()

        // Opacity: 0..0.25: 0..1, 0.25..0.6: 1, 0.6..1: 1..0
        let op: Double = {
            if c < 0.25 { return c / 0.25 }
            if c < 0.6  { return 1 }
            return 1 - (c - 0.6) / 0.4
        }()

        return BrandChevronShape()
            .stroke(Color.white,
                    style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
            .frame(width: 60, height: 50)
            .position(x: 35, y: CGFloat(topBase) + CGFloat(y) + 7)
            .opacity(op)
    }

    private func easeOut(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return 1 - pow(1 - c, 3)
    }
    private func easeInOut(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c < 0.5 ? 2 * c * c : 1 - pow(-2 * c + 2, 2) / 2
    }
}

private struct BrandChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let sx = w / 56, sy = h / 14
        p.move(to: CGPoint(x: 4 * sx, y: 12 * sy))
        p.addLine(to: CGPoint(x: 28 * sx, y: 4 * sy))
        p.addLine(to: CGPoint(x: 52 * sx, y: 12 * sy))
        return p
    }
}
