//
//  WelcomeScreen.swift
//  RunTogether
//

import SwiftUI

struct WelcomeScreen: View {
    /// Driven by container — when `true` the brand lifts and fades out
    /// before the next screen slides in.
    let exiting: Bool

    var body: some View {
        ZStack {
            // Decorative ambient blobs (subtle, behind the brand)
            Circle()
                .fill(OnboardingTheme.orange)
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .opacity(0.30)
                .offset(x: 100, y: -260)

            Circle()
                .fill(OnboardingTheme.neon)
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .opacity(0.20)
                .offset(x: -130, y: 200)

            VStack(spacing: 26) {
                BrandChevronEmblem(size: 110)
                    .scaleEffect(exiting ? 2.4 : 1)
                    .offset(y: exiting ? -300 : 0)
                    .opacity(exiting ? 0 : 1)
                    .animation(.timingCurve(0.2, 0.75, 0.2, 1.15, duration: 0.75),
                               value: exiting)

                wordmark
                    .opacity(exiting ? 0 : 1)
                    .offset(y: exiting ? 20 : 0)
                    .animation(.easeOut(duration: 0.45), value: exiting)

                Text("Where every run is a story you share.")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(OnboardingTheme.tagline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                    .opacity(exiting ? 0 : 1)
                    .offset(y: exiting ? 20 : 0)
                    .animation(.easeOut(duration: 0.45), value: exiting)
            }
            .padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 24)
    }

    /// "Run" in brand orange + "Together" in white — matches splash exactly.
    private var wordmark: some View {
        HStack(spacing: 2) {
            Text("Run")
                .foregroundColor(OnboardingTheme.orange)
            Text("Together")
                .foregroundColor(.white)
        }
        .font(.system(size: 54, weight: .heavy, design: .rounded))
        .tracking(-1)
    }
}

#Preview {
    ZStack {
        OnboardingBackground()
        WelcomeScreen(exiting: false)
    }
    .preferredColorScheme(.dark)
}
