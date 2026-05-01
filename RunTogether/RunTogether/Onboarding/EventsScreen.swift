//
//  EventsScreen.swift
//  RunTogether
//

import SwiftUI

struct EventsScreen: View {
    @State private var appearedAt: Date = Date()

    private struct Event {
        let emoji: String
        let title: String
        let meta: String
        let pillText: String
        let pillStyle: PillStyle
        let bg: Color
    }

    enum PillStyle {
        case orange, mint, yellow
    }

    private let events: [Event] = [
        .init(emoji: "🌅",
              title: "Sunday Sunrise 5K",
              meta: "Indiranagar · Sun 6 AM",
              pillText: "12 going",
              pillStyle: .orange,
              bg: OnboardingTheme.orange.opacity(0.18)),
        .init(emoji: "💚",
              title: "Hope Run for Cancer",
              meta: "Charity · Sat 6 AM",
              pillText: "240 going",
              pillStyle: .mint,
              bg: OnboardingTheme.neon.opacity(0.18)),
        .init(emoji: "🏢",
              title: "Bandra Run Club Weekly",
              meta: "Club · Thu 6 PM",
              pillText: "18 going",
              pillStyle: .yellow,
              bg: OnboardingTheme.yellow.opacity(0.18))
    ]

    var body: some View {
        ZStack {
            // Decorative blob
            Circle()
                .fill(OnboardingTheme.neon)
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .opacity(0.35)
                .offset(x: 110, y: -240)

            VStack(alignment: .leading, spacing: 0) {
                Text("Run together").eyebrow()
                    .padding(.bottom, 10)

                Text("Find your running crew").headline()
                    .padding(.bottom, 10)

                Text("Join runs hosted by people, clubs and charities — or rally your own.")
                    .subcopy()
                    .padding(.bottom, 18)

                VStack(spacing: 12) {
                    ForEach(Array(events.enumerated()), id: \.offset) { idx, e in
                        eventCard(e)
                            .modifier(SlideUpAppear(delay: 0.1 * Double(idx)))
                    }

                    hostCTA()
                        .modifier(SlideUpAppear(delay: 0.35))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 70) // leaves room above for status bar / skip button
            .padding(.bottom, 110)
        }
    }

    @ViewBuilder
    private func eventCard(_ e: Event) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(e.bg)
                        .frame(width: 46, height: 46)
                    Text(e.emoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(e.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(OnboardingTheme.text)
                    HStack(spacing: 6) {
                        Text(e.meta)
                            .font(.system(size: 12))
                            .foregroundColor(OnboardingTheme.textSoft)
                        pill(e.pillText, style: e.pillStyle)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func pill(_ text: String, style: PillStyle) -> some View {
        let colors: (bg: Color, fg: Color, glow: Color) = {
            switch style {
            case .orange:
                return (OnboardingTheme.orange, .white, OnboardingTheme.orange.opacity(0.4))
            case .mint:
                return (OnboardingTheme.neon,
                        Color(red: 0x06/255, green: 0x26/255, blue: 0x33/255),
                        OnboardingTheme.neon.opacity(0.4))
            case .yellow:
                return (OnboardingTheme.yellow,
                        Color(red: 0x2D/255, green: 0x22/255, blue: 0x00/255),
                        OnboardingTheme.yellow.opacity(0.4))
            }
        }()

        return Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(colors.fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Capsule().fill(colors.bg))
            .shadow(color: colors.glow, radius: 5)
    }

    @ViewBuilder
    private func hostCTA() -> some View {
        HStack(spacing: 6) {
            Text("Host your own run · ")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OnboardingTheme.text)
            Text("tap +")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OnboardingTheme.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            OnboardingTheme.orange.opacity(0.15),
                            OnboardingTheme.neon.opacity(0.15)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(OnboardingTheme.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - SlideUp on appear

private struct SlideUpAppear: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    shown = true
                }
            }
            .onDisappear { shown = false }
    }
}
