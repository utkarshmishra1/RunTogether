//
//  CompeteScreen.swift
//  RunTogether
//

import SwiftUI

struct CompeteScreen: View {
    private let tabs = ["Friends", "City", "Global"]

    private struct Row {
        let rank: Int
        let initial: String
        let name: String
        let streak: Int
        let km: Double
        let avatar: AvatarStyle
        let isYou: Bool
    }

    private enum AvatarStyle { case orange, mint, yellow, purple }

    private let rows: [Row] = [
        .init(rank: 1, initial: "U", name: "You",   streak: 12, km: 42.6, avatar: .orange, isYou: true),
        .init(rank: 2, initial: "J", name: "John",  streak: 9,  km: 38.1, avatar: .mint,   isYou: false),
        .init(rank: 3, initial: "E", name: "Emma",  streak: 7,  km: 31.4, avatar: .yellow, isYou: false),
        .init(rank: 4, initial: "M", name: "Mike",  streak: 4,  km: 22.8, avatar: .purple, isYou: false),
    ]

    var body: some View {
        ZStack {
            // Decorative blob
            Circle()
                .fill(OnboardingTheme.yellow)
                .frame(width: 160, height: 160)
                .blur(radius: 50)
                .opacity(0.3)
                .offset(x: 130, y: -260)

            VStack(alignment: .leading, spacing: 0) {
                Text("Race & climb").eyebrow()
                    .padding(.bottom, 10)

                Text("Compete in real time").headline()
                    .padding(.bottom, 10)

                Text("Live races, daily streaks, and a leaderboard for every circle.")
                    .subcopy()
                    .padding(.bottom, 18)

                GlassCard {
                    VStack(spacing: 0) {
                        livePill
                            .padding(.bottom, 14)

                        scopeTabs
                            .padding(.bottom, 6)

                        ForEach(Array(rows.enumerated()), id: \.offset) { idx, r in
                            row(r)
                            if idx < rows.count - 1 && !r.isYou {
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }
                    }
                    .padding(16)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 70)
            .padding(.bottom, 110)
        }
    }

    private var livePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(OnboardingTheme.orange)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(OnboardingTheme.orange)
                        .modifier(BreathingScale())
                )
                .shadow(color: OnboardingTheme.orange, radius: 4)
            Text("3 friends running now")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(OnboardingTheme.orange)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(
            Capsule()
                .fill(OnboardingTheme.orange.opacity(0.15))
                .overlay(Capsule().strokeBorder(OnboardingTheme.orange.opacity(0.3), lineWidth: 1))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scopeTabs: some View {
        HStack(spacing: 6) {
            ForEach(0..<tabs.count, id: \.self) { i in
                // Only the Friends tab (index 0) is selectable; the others are
                // shown as preview/disabled in the onboarding leaderboard.
                let active = i == 0
                Text(tabs[i])
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(active ? .white : OnboardingTheme.textSoft.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        Group {
                            if active {
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [OnboardingTheme.orange, OnboardingTheme.orangeDeep],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            }
                        }
                    )
                    .shadow(color: active ? OnboardingTheme.orange.opacity(0.45) : .clear, radius: 4, y: 3)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.04))
                .overlay(Capsule().strokeBorder(OnboardingTheme.border, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func row(_ r: Row) -> some View {
        HStack(spacing: 12) {
            Text("\(r.rank)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(r.rank == 1 ? OnboardingTheme.orange : OnboardingTheme.textSoft)
                .shadow(color: r.rank == 1 ? OnboardingTheme.orange.opacity(0.6) : .clear, radius: 5)
                .frame(width: 22)

            avatar(r.initial, style: r.avatar)

            Text(r.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(OnboardingTheme.text)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Text("🔥 \(r.streak)")
                    .foregroundColor(OnboardingTheme.orangeGlow)
                    .fontWeight(.bold)
                Text("· \(String(format: "%.1f", r.km)) km")
                    .foregroundColor(OnboardingTheme.textSoft)
            }
            .font(.system(size: 12.5))
        }
        .padding(.vertical, 11)
        .padding(.horizontal, r.isYou ? 10 : 0)
        .background(
            Group {
                if r.isYou {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [OnboardingTheme.orange.opacity(0.18), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(OnboardingTheme.orange.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        )
        .padding(.horizontal, r.isYou ? -10 : 0)
    }

    @ViewBuilder
    private func avatar(_ letter: String, style: AvatarStyle) -> some View {
        let gradient: LinearGradient = {
            switch style {
            case .orange:
                return LinearGradient(colors: [OnboardingTheme.orange, OnboardingTheme.orangeDeep],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            case .mint:
                return LinearGradient(colors: [OnboardingTheme.neon, OnboardingTheme.neonDeep],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            case .yellow:
                return LinearGradient(colors: [OnboardingTheme.yellow, Color(red: 0xF4/255, green: 0xA2/255, blue: 0x61/255)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            case .purple:
                return LinearGradient(colors: [Color(red: 0xB7/255, green: 0x94/255, blue: 0xF4/255), Color(red: 0x80/255, green: 0x5A/255, blue: 0xD5/255)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }()
        let textColor: Color = {
            switch style {
            case .mint: return Color(red: 0x06/255, green: 0x26/255, blue: 0x33/255)
            case .yellow: return Color(red: 0x2D/255, green: 0x22/255, blue: 0x00/255)
            default: return .white
            }
        }()

        Circle()
            .fill(gradient)
            .frame(width: 38, height: 38)
            .overlay(
                Text(letter)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textColor)
            )
    }
}

// MARK: - Pulse helper

private struct BreathingScale: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1.5 : 1)
            .opacity(on ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}
