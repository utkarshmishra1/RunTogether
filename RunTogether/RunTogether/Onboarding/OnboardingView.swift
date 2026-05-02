//
//  OnboardingView.swift
//  RunTogether
//

import SwiftUI

struct OnboardingView: View {
    @State private var current: Int = 0
    @State private var chevronExiting: Bool = false
    private let total = 4

    // Triggers screen-3 map to start animating once visible
    @State private var territoryAppearedToken: Int = 0

    var body: some View {
        ZStack {
            OnboardingBackground()

            GeometryReader { geo in
                let topInset = geo.safeAreaInsets.top
                let bottomInset = geo.safeAreaInsets.bottom

                ZStack {
                    // Screens stacked, slid horizontally. We push their content
                    // down/up by the safe area insets so the brand mark, the
                    // headlines, and the bottom padding all sit inside the
                    // readable area while the background still extends edge to
                    // edge underneath.
                    screensStack(width: geo.size.width)
                        .padding(.top, topInset)
                        .padding(.bottom, bottomInset)

                    // Skip button — kept clear of the status bar
                    if current < total - 1 {
                        Button("Skip") {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                current = total - 1
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(OnboardingTheme.textSoft)
                        .padding(.top, topInset + 12)
                        .padding(.trailing, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .transition(.opacity)
                    }

                    // Footer — kept clear of the home indicator
                    footer
                        .padding(.horizontal, 24)
                        .padding(.bottom, bottomInset + 26)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    if value.translation.width < -50 { advance() }
                    else if value.translation.width > 50 { retreat() }
                }
        )
        .onChange(of: current) { _, newValue in
            // Whenever the territory screen becomes current — forward, back,
            // or via skip — bump its activation token so it starts the run
            // fresh from the beginning.
            if newValue == 2 {
                territoryAppearedToken &+= 1
            }
        }
    }

    // MARK: Screens

    @ViewBuilder
    private func screensStack(width: CGFloat) -> some View {
        ZStack {
            screen(index: 0, width: width) {
                WelcomeScreen(exiting: chevronExiting)
            }
            screen(index: 1, width: width) {
                EventsScreen()
            }
            screen(index: 2, width: width) {
                TerritoryScreen(activationToken: territoryAppearedToken)
            }
            screen(index: 3, width: width) {
                CompeteScreen()
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func screen<Content: View>(index: Int, width: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let xOffset: CGFloat = {
            if index == current { return 0 }
            return index < current ? -width : width
        }()
        let isActive = index == current

        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: xOffset)
            .opacity(isActive ? 1 : 0)
            .animation(.timingCurve(0.2, 0.85, 0.25, 1, duration: 0.45), value: current)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            // Dots
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { i in
                    let active = i == current
                    Capsule()
                        .fill(active ? OnboardingTheme.orange : Color.white.opacity(0.2))
                        .frame(width: active ? 26 : 8, height: 8)
                        .shadow(color: active ? OnboardingTheme.orange.opacity(0.7) : .clear, radius: 6)
                        .animation(.easeInOut(duration: 0.35), value: current)
                }
            }
            Spacer()
            Button(action: handlePrimary) {
                Text(current == total - 1 ? "Let's run 🏃" : "Next →")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, current == total - 1 ? 26 : 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [OnboardingTheme.orange, OnboardingTheme.orangeDeep],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    )
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                            .blendMode(.plusLighter)
                            .mask(
                                LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)
                            )
                    )
                    .shadow(color: OnboardingTheme.orange.opacity(0.5), radius: 9, y: 6)
            }
        }
    }

    // MARK: Actions

    private func handlePrimary() {
        if current == total - 1 {
            // Final CTA: send the user to the main app.
            NotificationCenter.default.post(name: .onboardingFinished, object: nil)
            return
        }
        advance()
    }

    private func advance() {
        guard current < total - 1 else { return }
        // Welcome → Events: play chevron lift first
        if current == 0 {
            withAnimation(.timingCurve(0.2, 0.75, 0.2, 1.15, duration: 0.75)) {
                chevronExiting = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.timingCurve(0.2, 0.85, 0.25, 1, duration: 0.45)) {
                    current = 1
                }
                // Reset for when user comes back
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    chevronExiting = false
                }
            }
            return
        }
        let nextIndex = current + 1
        withAnimation(.timingCurve(0.2, 0.85, 0.25, 1, duration: 0.45)) {
            current = nextIndex
        }
    }

    private func retreat() {
        guard current > 0 else { return }
        withAnimation(.timingCurve(0.2, 0.85, 0.25, 1, duration: 0.45)) {
            current -= 1
        }
    }
}

extension Notification.Name {
    static let onboardingFinished = Notification.Name("onboardingFinished")
}

#Preview {
    OnboardingView()
}
