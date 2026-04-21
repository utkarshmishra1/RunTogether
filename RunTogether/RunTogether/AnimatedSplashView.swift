//
//  AnimatedSplashView.swift
//  RunTogether
//

import SwiftUI

struct AnimatedSplashView: View {
    @State private var isDone = false

    var body: some View {
        ZStack {
            if isDone {
                ContentView().transition(.opacity)
            } else {
                SplashContent(onFinish: { withAnimation(.easeInOut(duration: 0.5)) { isDone = true } })
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Palette

private enum Palette {
    static let bgTop    = Color(red: 0x0E/255, green: 0x1F/255, blue: 0x4A/255)
    static let bgMid    = Color(red: 0x0B/255, green: 0x1A/255, blue: 0x3F/255)
    static let bgBottom = Color(red: 0x0A/255, green: 0x17/255, blue: 0x38/255)
    static let orange1  = Color(red: 0xFF/255, green: 0x7B/255, blue: 0x2B/255)
    static let orange2  = Color(red: 0xFF/255, green: 0x5A/255, blue: 0x1F/255)
    static let orangeSoft = Color(red: 0xFF/255, green: 0x8C/255, blue: 0x50/255)
    static let tagline  = Color(red: 0xE5/255, green: 0xEA/255, blue: 0xF6/255)
}

// MARK: - Splash

private struct SplashContent: View {
    var onFinish: () -> Void

    // Drive all continuous animations from one timeline (t in seconds).
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Palette.bgTop, Palette.bgMid, Palette.bgBottom],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                Starfield(t: t).ignoresSafeArea()
                GlowView(t: t).ignoresSafeArea()
                WavesView(t: t).ignoresSafeArea()
                ParticlesView(t: t).ignoresSafeArea()
                BrandView(t: t)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { onFinish() }
        }
    }
}

// MARK: - Helpers

private func clamp(_ x: Double, _ lo: Double = 0, _ hi: Double = 1) -> Double {
    min(max(x, lo), hi)
}
private func easeOut(_ x: Double) -> Double {
    let c = clamp(x)
    return 1 - pow(1 - c, 3)
}
private func easeInOut(_ x: Double) -> Double {
    let c = clamp(x)
    return c < 0.5 ? 2 * c * c : 1 - pow(-2 * c + 2, 2) / 2
}
// Spring-ish overshoot for logoIn (0% scale .4, 60% scale 1.08, 100% scale 1)
private func logoInCurve(_ x: Double) -> (scale: Double, rotation: Double, opacity: Double) {
    let c = clamp(x)
    if c < 0.6 {
        let p = c / 0.6
        let e = easeOut(p)
        return (0.4 + (1.08 - 0.4) * e, -8 + 10 * e, e)
    } else {
        let p = (c - 0.6) / 0.4
        let e = easeInOut(p)
        return (1.08 + (1.0 - 1.08) * e, 2 + (-2) * e, 1)
    }
}

// MARK: - Brand (logo + wordmark + tagline)

private struct BrandView: View {
    let t: TimeInterval
    @State private var start = Date().timeIntervalSinceReferenceDate

    var body: some View {
        let elapsed = t - start

        // Animation timings (seconds) — match CSS delays
        let logo = logoInCurve((elapsed - 0.2) / 1.0)
        // Float after logoIn (starts ~1.4s)
        let floatT = max(0, elapsed - 1.4)
        let floatY = sin(floatT * .pi * 2 / 4) * 6       // 4s period, 6px
        let floatScale = 1 + 0.02 * sin(floatT * .pi * 2 / 4)

        // Wordmark fades
        let runOp = easeOut((elapsed - 1.1) / 0.9)
        let togOp = easeOut((elapsed - 1.35) / 0.9)
        let tagOp = easeOut((elapsed - 1.75) / 1.0)

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            VStack(spacing: 14) {
                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Palette.orange1, Palette.orange2],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                .blendMode(.plusLighter)
                                .mask(
                                    LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)
                                )
                        )
                        .shadow(color: Palette.orange2.opacity(0.35), radius: 20, y: 18)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 4)

                    ChevronPair(elapsed: elapsed)
                        .frame(width: 70, height: 70)
                }
                .scaleEffect(logo.scale * floatScale)
                .rotationEffect(.degrees(logo.rotation))
                .opacity(logo.opacity)
                .offset(y: -floatY)
                .padding(.bottom, 8)

                // Wordmark
                HStack(spacing: 2) {
                    Text("Run")
                        .foregroundColor(Palette.orange1)
                        .opacity(runOp)
                        .offset(y: (1 - runOp) * 20)
                    Text("Together")
                        .foregroundColor(.white)
                        .opacity(togOp)
                        .offset(y: (1 - togOp) * 20)
                }
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .tracking(-1)

                // Tagline
                VStack(spacing: 2) {
                    Text("Stronger together.")
                    Text("Every step counts.")
                }
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(Palette.tagline)
                .multilineTextAlignment(.center)
                .opacity(tagOp)
                .offset(y: (1 - tagOp) * 20)
            }
            .frame(width: w, height: h)
            // Pull up so brand sits above center like in CSS (margin-bottom: 18vh)
            .offset(y: -h * 0.09)
        }
    }
}

// MARK: - Chevron pair (looping rise)

private struct ChevronPair: View {
    let elapsed: Double

    var body: some View {
        ZStack {
            chevron(delay: 0.7, topBase: 10)
            chevron(delay: 0.9, topBase: 34)
        }
    }

    private func chevron(delay: Double, topBase: CGFloat) -> some View {
        // 1.6s loop: 0->0.25 fade in while rising from +10 to ~+6,
        // 0.25->0.6 continue rising to -6, 0.6->1.0 rise to -14 and fade out.
        let raw = (elapsed - delay) / 1.6
        let c = raw < 0 ? 0 : raw - floor(raw)

        // Piecewise y from +10 -> -14 over 0..1
        // CSS: 0%: y=10, 60%: y=-6, 100%: y=-14
        let y: Double = {
            if c < 0.6 {
                return 10 + (-6 - 10) * easeOut(c / 0.6)
            } else {
                return -6 + (-14 - (-6)) * easeInOut((c - 0.6) / 0.4)
            }
        }()

        // Opacity: 0 -> 0.25: 0..1, 0.25..0.6: 1, 0.6..1: 1..0
        let op: Double = {
            if c < 0.25 { return c / 0.25 }
            if c < 0.6  { return 1 }
            return 1 - (c - 0.6) / 0.4
        }()

        return ChevronShape()
            .stroke(Color.white, style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
            .frame(width: 60, height: 50)
            .position(x: 35, y: CGFloat(topBase) + CGFloat(y) + 7)
            .opacity(op)
    }
}

private struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Match: M4 12 L28 4 L52 12 in viewBox 56x14
        let sx = w / 56, sy = h / 14
        p.move(to: CGPoint(x: 4 * sx, y: 12 * sy))
        p.addLine(to: CGPoint(x: 28 * sx, y: 4 * sy))
        p.addLine(to: CGPoint(x: 52 * sx, y: 12 * sy))
        return p
    }
}

// MARK: - Glow (radial pulse)

private struct GlowView: View {
    let t: TimeInterval
    @State private var start = Date().timeIntervalSinceReferenceDate

    var body: some View {
        let elapsed = t - start
        let fadeIn = easeOut((elapsed - 0.3) / 1.2)
        let pulseT = max(0, elapsed - 0.8)
        let pulse = 0.5 + 0.5 * sin(pulseT * .pi * 2 / 4)  // 4s
        let scale = 1.0 + 0.12 * pulse
        let opacity = (0.85 + 0.15 * pulse) * fadeIn

        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Palette.orange1.opacity(0.18),
                            Palette.orange1.opacity(0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 260
                    )
                )
                .frame(width: 520, height: 520)
                .blur(radius: 10)
                .scaleEffect(scale)
                .opacity(opacity)
                .position(x: w / 2, y: h * 0.45)
        }
    }
}

// MARK: - Waves

private struct WavePathShape: Shape {
    // Cubic Bezier path designed in a 1200x500 viewBox.
    var commands: [WaveCmd]

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 1200.0
        let sy = rect.height / 500.0
        var p = Path()
        for cmd in commands {
            switch cmd {
            case .move(let pt):
                p.move(to: CGPoint(x: pt.x * sx, y: pt.y * sy))
            case .curve(let c1, let c2, let to):
                p.addCurve(
                    to: CGPoint(x: to.x * sx, y: to.y * sy),
                    control1: CGPoint(x: c1.x * sx, y: c1.y * sy),
                    control2: CGPoint(x: c2.x * sx, y: c2.y * sy)
                )
            }
        }
        return p
    }
}

private enum WaveCmd {
    case move(CGPoint)
    case curve(CGPoint, CGPoint, CGPoint)
}

// Convert "M a,b C c1 c2 to S c2' to'" into explicit cubic curves.
private func waveCommands(baseline: Double) -> [WaveCmd] {
    // Original SVG (baseline 340 example):
    // M-50 340 C 200 260, 400 430, 620 330 S 1000 250, 1250 340
    // Offset everything by (baseline - 340) vertically.
    let dy = baseline - 340
    func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y + dy) }
    // First cubic
    let c1_1 = P(200, 260)
    let c1_2 = P(400, 430)
    let end1 = P(620, 330)
    // S shorthand: reflect previous c2 over end1 for the new c1
    let c2_1 = CGPoint(x: 2 * end1.x - c1_2.x, y: 2 * end1.y - c1_2.y)
    let c2_2 = P(1000, 250)
    let end2 = P(1250, 340)
    return [
        .move(P(-50, 340)),
        .curve(c1_1, c1_2, end1),
        .curve(c2_1, c2_2, end2)
    ]
}

private struct WavesView: View {
    let t: TimeInterval
    @State private var start = Date().timeIntervalSinceReferenceDate

    private struct Layer {
        let baseline: Double
        let color: Color
        let width: CGFloat
        let drawDelay: Double
        let flowDelay: Double
    }

    private let layers: [Layer] = [
        .init(baseline: 340, color: Palette.orange1,                 width: 7,   drawDelay: 0.4, flowDelay: 1.6),
        .init(baseline: 380, color: Palette.orange2,                 width: 4,   drawDelay: 0.6, flowDelay: 1.9),
        .init(baseline: 300, color: Palette.orangeSoft.opacity(0.55),width: 2.5, drawDelay: 0.8, flowDelay: 2.2),
        .init(baseline: 270, color: Color(red: 200/255, green: 215/255, blue: 245/255).opacity(0.35), width: 1.5, drawDelay: 1.0, flowDelay: 2.5),
        .init(baseline: 410, color: Palette.orange1.opacity(0.4),    width: 2,   drawDelay: 1.1, flowDelay: 2.8),
    ]

    var body: some View {
        let elapsed = t - start

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Waves occupy bottom 45% of screen; widen by 20% like CSS (-10%..110%)
            let waveW = w * 1.20
            let waveH = h * 0.45
            let xOffset = -w * 0.10

            ZStack {
                ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
                    let drawP = clamp((elapsed - layer.drawDelay) / 1.2)
                    let fadeIn = easeOut(drawP)

                    let flowT = max(0, elapsed - layer.flowDelay)
                    let flow = sin(flowT * .pi * 2 / 6) // 6s period
                    let tx = -20.0 * (0.5 + 0.5 * flow)  // 0..-20 style; use symmetric ±10
                    let ty = -6.0  * (0.5 + 0.5 * flow)

                    WavePathShape(commands: waveCommands(baseline: layer.baseline))
                        .trim(from: 0, to: drawP)
                        .stroke(layer.color, style: StrokeStyle(lineWidth: layer.width, lineCap: .round))
                        .frame(width: waveW, height: waveH)
                        .opacity(fadeIn)
                        .offset(x: CGFloat(tx), y: CGFloat(ty))
                }
            }
            .frame(width: waveW, height: waveH)
            .offset(x: xOffset, y: h - waveH)
        }
    }
}

// MARK: - Particles

private struct ParticlesView: View {
    let t: TimeInterval
    @State private var start = Date().timeIntervalSinceReferenceDate

    private struct P {
        let xPct: Double      // 0..1
        let delay: Double
        let duration: Double
    }

    private let particles: [P] = [
        .init(xPct: 0.15, delay: 0.0, duration: 7.0),
        .init(xPct: 0.28, delay: 1.5, duration: 8.0),
        .init(xPct: 0.45, delay: 3.0, duration: 6.5),
        .init(xPct: 0.62, delay: 0.8, duration: 9.0),
        .init(xPct: 0.78, delay: 2.2, duration: 7.5),
        .init(xPct: 0.88, delay: 4.0, duration: 8.5),
        .init(xPct: 0.08, delay: 3.5, duration: 10.0),
    ]

    var body: some View {
        let elapsed = t - start
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                ForEach(Array(particles.enumerated()), id: \.offset) { _, p in
                    let raw = (elapsed - p.delay) / p.duration
                    let c = raw < 0 ? 0 : raw - floor(raw)

                    // y: 0 -> -70vh, x: 0 -> +30px
                    let y = -c * h * 0.70
                    let x = c * 30

                    // Opacity: 0->0.1: 0..0.8, 0.1..0.9: 0.8..0.4, 0.9..1: ->0
                    let op: Double = {
                        if c < 0.1  { return (c / 0.1) * 0.8 }
                        if c < 0.9  { return 0.8 - (c - 0.1) / 0.8 * 0.4 }
                        return 0.4 * (1 - (c - 0.9) / 0.1)
                    }()

                    Circle()
                        .fill(Palette.orange1)
                        .frame(width: 4, height: 4)
                        .shadow(color: Palette.orange1.opacity(0.8), radius: 4)
                        .opacity(op)
                        .position(x: p.xPct * w + x, y: h + 20 + y)
                }
            }
        }
    }
}

// MARK: - Starfield

private struct Starfield: View {
    let t: TimeInterval
    @State private var start = Date().timeIntervalSinceReferenceDate

    private struct S { let xPct: Double; let yPct: Double; let alpha: Double }
    private let layerA: [S] = [
        .init(xPct: 0.20, yPct: 0.30, alpha: 0.50),
        .init(xPct: 0.70, yPct: 0.20, alpha: 0.35),
        .init(xPct: 0.40, yPct: 0.65, alpha: 0.30),
        .init(xPct: 0.85, yPct: 0.50, alpha: 0.25),
        .init(xPct: 0.55, yPct: 0.15, alpha: 0.40),
    ]

    var body: some View {
        let elapsed = t - start
        // twinkle: 5s ease-in-out, opacity 0.6..1 ; second layer delayed 2.5s, base opacity 0.5
        let tw1 = 0.6 + 0.4 * (0.5 + 0.5 * sin(elapsed * .pi * 2 / 5))
        let tw2 = (0.6 + 0.4 * (0.5 + 0.5 * sin((elapsed - 2.5) * .pi * 2 / 5))) * 0.5

        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                ForEach(Array(layerA.enumerated()), id: \.offset) { _, s in
                    Circle()
                        .fill(Color.white.opacity(s.alpha))
                        .frame(width: 2, height: 2)
                        .position(x: s.xPct * w, y: s.yPct * h)
                }
                .opacity(tw1)

                ForEach(Array(layerA.enumerated()), id: \.offset) { _, s in
                    Circle()
                        .fill(Color.white.opacity(s.alpha))
                        .frame(width: 2, height: 2)
                        .position(x: (1 - s.xPct) * w, y: (1 - s.yPct) * h * 0.9)
                }
                .opacity(tw2)
            }
        }
    }
}

#Preview {
    AnimatedSplashView()
}
