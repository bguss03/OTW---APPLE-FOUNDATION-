import SwiftUI
import UIKit

/// "v3 / Save · 1 Saving" → "v3 / Save · 2 Saved" confirmation shown after a plan is stored.
struct SaveConfirmationView: View {
    let isSaved: Bool
    let savedDate: Date
    let onContinue: () -> Void
    var isEditing = false
    /// "View in Calendar"; falls back to Continue when nil.
    var onViewInCalendar: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            if isSaved {
                SavedContent(
                    savedDate: savedDate,
                    onContinue: onContinue,
                    onViewInCalendar: onViewInCalendar ?? onContinue,
                    isEditing: isEditing
                )
                .transition(.opacity)
            } else {
                SavingContent()
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0), value: isSaved)
    }
}

// MARK: - Saving

/// Squash-and-stretch hop of the squashed pet (156 x 132) in front of a pulsing glow.
private struct SavingMotion {
    var y: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
}

private struct SavingContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dotsUp = false
    @State private var progress: CGFloat = 0.12

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            hero
                .frame(height: 142)

            // Loader dots: orange, FDB27A, FED4B3.
            HStack(spacing: 9) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(dotColor(index))
                        .frame(width: 14, height: 14)
                        .scaleEffect(dotsUp || reduceMotion ? 1 : 0.8)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(index) * 0.15),
                            value: dotsUp
                        )
                }
            }
            .padding(.top, 32)

            Text("Saving your plan...")
                .font(Theme.Fonts.savingTitle)
                .foregroundStyle(Theme.Colors.label)
                .frame(height: 26)
                .padding(.top, 20)

            Text("Hold on, I am writing it down!")
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(height: 18)
                .padding(.top, 6)

            // Progress 240 x 10, radius 5.
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.accentTint)
                Capsule().fill(Theme.Colors.accent)
                    .frame(width: 240 * progress)
            }
            .frame(width: 240, height: 10)
            .padding(.top, 24)

            Spacer()

            Text("Saving...")
                .font(Theme.Fonts.navTitle)
                .foregroundStyle(Theme.Colors.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.primaryButton, style: .continuous)
                        .fill(Theme.Colors.accentTintSoft)
                )
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.bottom, 14)
        }
        .onAppear {
            dotsUp = true
            withAnimation(.spring(duration: 1.4, bounce: 0)) {
                progress = 0.9
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        if reduceMotion {
            pet(SavingMotion())
        } else {
            KeyframeAnimator(initialValue: SavingMotion(), repeating: true) { motion in
                pet(motion)
            } keyframes: { _ in
                // One 0.7 s hop: anticipation squash → stretch in the air → landing squash.
                KeyframeTrack(\.y) {
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-18, duration: 0.22)
                    CubicKeyframe(0, duration: 0.22)
                    CubicKeyframe(0, duration: 0.16)
                }
                KeyframeTrack(\.scaleX) {
                    CubicKeyframe(1.07, duration: 0.1)
                    CubicKeyframe(0.95, duration: 0.22)
                    CubicKeyframe(1.0, duration: 0.12)
                    CubicKeyframe(1.08, duration: 0.1)
                    CubicKeyframe(1.0, duration: 0.16)
                }
                KeyframeTrack(\.scaleY) {
                    CubicKeyframe(0.92, duration: 0.1)
                    CubicKeyframe(1.06, duration: 0.22)
                    CubicKeyframe(1.0, duration: 0.12)
                    CubicKeyframe(0.9, duration: 0.1)
                    CubicKeyframe(1.0, duration: 0.16)
                }
            }
        }
    }

    /// Pet above its ground shadow; the shadow shrinks and fades with the hop height.
    private func pet(_ motion: SavingMotion) -> some View {
        let lift = min(max(-motion.y / 18, 0), 1)
        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(0.10 * (1 - 0.45 * lift)))
                .frame(width: 140, height: 16)
                .scaleEffect(1 - 0.35 * lift)
                .offset(y: 10)
            PetMascotView(expression: .default, isLive: false)
                .frame(width: 156, height: 132)
                .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
                .offset(y: motion.y)
                .background {
                    PulsingGlow(diameter: 250, isAnimated: !reduceMotion)
                        .offset(y: motion.y * 0.4)
                }
        }
    }

    private func dotColor(_ index: Int) -> Color {
        switch index {
        case 0: Theme.Colors.accent
        case 1: Theme.Colors.accentPale
        default: Theme.Colors.accentTintSoft
        }
    }
}

/// Soft orange radial glow that pulses on a ~0.7 s loop.
private struct PulsingGlow: View {
    let diameter: CGFloat
    let isAnimated: Bool

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Theme.Colors.accent.opacity(0.28), Theme.Colors.accent.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .phaseAnimator(isAnimated ? [false, true] : [false]) { content, bright in
                content
                    .scaleEffect(bright ? 1.1 : 0.9)
                    .opacity(bright ? 1 : 0.6)
            } animation: { _ in
                .easeInOut(duration: 0.35)
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Saved

/// Happy jump: crouch → leap (eyes morph to ^ ^ at the apex) → landing squash.
private struct JumpMotion {
    var y: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
}

/// Check badge pop: 0 → 1.15 → 1 with a small rotation.
private struct BadgeMotion {
    var scale: CGFloat = 1
    var angle: Double = 0
}

private struct SavedContent: View {
    let savedDate: Date
    let onContinue: () -> Void
    let onViewInCalendar: () -> Void
    var isEditing = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var expression: PetExpression = .default
    @State private var jumpTrigger = 0
    @State private var badgeTrigger = 0
    @State private var isBadgeVisible = false
    @State private var isRevealed = false
    @State private var isTextVisible = false
    @State private var confettiStart: Date?

    /// The jump lands (and the badge pops) this long after the Saved screen appears.
    private static let landing: Duration = .milliseconds(580)

    private var streakText: String {
        if isEditing { return "Plan updated" }
        return Calendar.current.isDateInToday(savedDate) ? "+1 plan today" : "+1 plan on \(OTWFormat.shortDate(savedDate))"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            hero
                .frame(width: 340, height: 340)

            Text("Saved!")
                .font(Theme.Fonts.savedTitle)
                .foregroundStyle(Theme.Colors.label)
                .frame(height: 40)
                .padding(.top, 24)
                .modifier(StaggeredReveal(isVisible: isTextVisible, index: 0))

            Text(isEditing ? "Your changes are saved. I will remind you with the new details." : "Your plan is on the list. I will remind you before it starts.")
                .font(Theme.Fonts.formValue)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(width: 320)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .modifier(StaggeredReveal(isVisible: isTextVisible, index: 1))

            Text(streakText)
                .font(Theme.Fonts.streak)
                .foregroundStyle(Theme.Colors.accentDeep)
                .padding(.horizontal, 20)
                .frame(height: 34)
                .background(Capsule().fill(Theme.Colors.accentTint))
                .padding(.top, 24)
                .modifier(StaggeredReveal(isVisible: isTextVisible, index: 2))

            Spacer()

            Button(action: onViewInCalendar) {
                Text("View in Calendar")
                    .font(Theme.Fonts.navTitle)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(height: 20)
                    .expandedHitArea(dx: 8, dy: 12)
            }
            .buttonStyle(.pressable)
            .modifier(StaggeredReveal(isVisible: isTextVisible, index: 3))

            Button(action: onContinue) {
                Text("CONTINUE")
                    .font(Theme.Fonts.continueLabel)
                    .foregroundStyle(Theme.Colors.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
            }
            .buttonStyle(ThreeDButtonStyle())
            .padding(.top, 26)
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.bottom, 18)
            .modifier(StaggeredReveal(isVisible: isTextVisible, index: 4))
        }
        .task { await play() }
    }

    // MARK: Choreography

    private func play() async {
        let haptics = UINotificationFeedbackGenerator()
        haptics.prepare()
        SoundEffects.shared.prepare()

        if reduceMotion {
            expression = .happy
            isBadgeVisible = true
            isRevealed = true
            isTextVisible = true
            haptics.notificationOccurred(.success)
            SoundEffects.shared.playSave()
            return
        }

        jumpTrigger += 1
        try? await Task.sleep(for: .milliseconds(300))
        expression = .happy // Eyes morph at the top of the jump.
        try? await Task.sleep(for: Self.landing - .milliseconds(300))

        // Landing: badge pop, haptic, sound and confetti all on the same frame.
        isBadgeVisible = true
        badgeTrigger += 1
        confettiStart = .now
        haptics.notificationOccurred(.success)
        SoundEffects.shared.playSave()
        withAnimation(.spring(duration: 0.45, bounce: 0.3)) { isRevealed = true }

        try? await Task.sleep(for: .milliseconds(80))
        isTextVisible = true
    }

    // MARK: Hero

    /// Glow, confetti, jumping pet, check badge and shadow, laid out on a 340pt stage.
    private var hero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.accent.opacity(0.25), Theme.Colors.accent.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .scaleEffect(isRevealed ? 1 : 0.7)
                .opacity(isRevealed ? 1 : 0.5)

            ForEach(Array(confetti.enumerated()), id: \.offset) { _, piece in
                RoundedRectangle(cornerRadius: piece.radius, style: .continuous)
                    .fill(piece.color)
                    .frame(width: piece.size.width, height: piece.size.height)
                    .rotationEffect(.degrees(piece.rotation))
                    .offset(x: piece.offset.x, y: piece.offset.y - 14)
                    .opacity(isRevealed ? 1 : 0)
                    .scaleEffect(isRevealed ? 1 : 0.3)
            }

            KeyframeAnimator(initialValue: JumpMotion(), trigger: jumpTrigger) { motion in
                jumpingPet(motion)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-46, duration: 0.22)
                    CubicKeyframe(0, duration: 0.26)
                    SpringKeyframe(0, duration: 0.22)
                }
                KeyframeTrack(\.scaleX) {
                    CubicKeyframe(1.1, duration: 0.1)
                    CubicKeyframe(0.92, duration: 0.22)
                    CubicKeyframe(1.0, duration: 0.16)
                    CubicKeyframe(1.1, duration: 0.1)
                    SpringKeyframe(1.0, duration: 0.22, spring: .bouncy)
                }
                KeyframeTrack(\.scaleY) {
                    CubicKeyframe(0.86, duration: 0.1)
                    CubicKeyframe(1.1, duration: 0.22)
                    CubicKeyframe(1.0, duration: 0.16)
                    CubicKeyframe(0.88, duration: 0.1)
                    SpringKeyframe(1.0, duration: 0.22, spring: .bouncy)
                }
            }

            // Check badge: 60pt orange circle with a 5pt white ring and glow.
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 60, height: 60)
                    .overlay(Circle().stroke(Color.white, lineWidth: 5))
                    .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 7, y: 6)
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Colors.onAccent)
            }
            .keyframeAnimator(initialValue: BadgeMotion(), trigger: badgeTrigger) { content, motion in
                content
                    .scaleEffect(reduceMotion ? 1 : motion.scale)
                    .rotationEffect(.degrees(reduceMotion ? 0 : motion.angle))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    MoveKeyframe(0)
                    CubicKeyframe(1.15, duration: 0.18)
                    SpringKeyframe(1, duration: 0.24, spring: .bouncy)
                }
                KeyframeTrack(\.angle) {
                    MoveKeyframe(-25)
                    CubicKeyframe(8, duration: 0.18)
                    SpringKeyframe(0, duration: 0.24, spring: .bouncy)
                }
            }
            .opacity(isBadgeVisible ? 1 : 0)
            .offset(x: 78, y: 52)

            // Burst from the pet's centre.
            ConfettiBurstView(start: confettiStart)
                .frame(width: 600, height: 700)
                .offset(y: -14)
        }
    }

    /// Happy pet (160 x 172) with a ground shadow that scales with the jump height.
    private func jumpingPet(_ motion: JumpMotion) -> some View {
        let lift = min(max(-motion.y / 46, 0), 1)
        return ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.06 * (1 - 0.5 * lift)))
                .frame(width: 120, height: 12)
                .scaleEffect(1 - 0.45 * lift)
                .offset(y: 152)

            PetMascotView(expression: expression, isLive: false)
                .frame(width: 160, height: 172)
                .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
                .offset(y: -14 + motion.y)
        }
    }

    private struct Confetti {
        let offset: CGPoint
        let size: CGSize
        let radius: CGFloat
        let color: Color
        let rotation: Double
    }

    /// Positions from the Sketch "Confetti" group, relative to the pet centre.
    private var confetti: [Confetti] {
        [
            Confetti(offset: CGPoint(x: -137, y: -120), size: CGSize(width: 12, height: 12), radius: 6, color: Theme.Colors.accent, rotation: 0),
            Confetti(offset: CGPoint(x: 135, y: -101), size: CGSize(width: 10, height: 10), radius: 5, color: Theme.Colors.accentPale, rotation: 0),
            Confetti(offset: CGPoint(x: -106, y: 88), size: CGSize(width: 8, height: 8), radius: 4, color: Theme.Colors.accentDeep, rotation: 0),
            Confetti(offset: CGPoint(x: 117, y: 111), size: CGSize(width: 14, height: 14), radius: 7, color: Theme.Colors.accentTintSoft, rotation: 0),
            Confetti(offset: CGPoint(x: -151, y: -12), size: CGSize(width: 16, height: 7), radius: 3.5, color: Theme.Colors.accentTintSoft, rotation: -30),
            Confetti(offset: CGPoint(x: 157, y: 8), size: CGSize(width: 18, height: 8), radius: 4, color: Theme.Colors.accent, rotation: 25),
            Confetti(offset: CGPoint(x: -65, y: -164), size: CGSize(width: 9, height: 4), radius: 2, color: Theme.Colors.accentSoft, rotation: -40),
            Confetti(offset: CGPoint(x: 78, y: -172), size: CGSize(width: 12, height: 5), radius: 2.5, color: Theme.Colors.accentShadow, rotation: 60),
            Confetti(offset: CGPoint(x: -2, y: -192), size: CGSize(width: 8, height: 8), radius: 4, color: Theme.Colors.accentPale, rotation: 0),
            Confetti(offset: CGPoint(x: -119, y: 158), size: CGSize(width: 10, height: 4.5), radius: 2, color: Theme.Colors.accentSoft, rotation: -60),
            Confetti(offset: CGPoint(x: 124, y: 168), size: CGSize(width: 8, height: 3.6), radius: 1.8, color: Theme.Colors.accentDeep, rotation: 20),
        ]
    }
}

/// Fade + slide up, staggered 60 ms per item.
private struct StaggeredReveal: ViewModifier {
    let isVisible: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .animation(Theme.Motion.standard.delay(Double(index) * 0.06), value: isVisible)
    }
}

/// CONTINUE: orange face over a darker bottom edge; pressing pushes the face 3pt down into it.
struct ThreeDButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        // Both shapes are backgrounds, so the button keeps the label's 58pt height.
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.primaryButton, style: .continuous)
                    .fill(Theme.Colors.accent)
            )
            .offset(y: configuration.isPressed ? 3 : 0)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.primaryButton, style: .continuous)
                    .fill(Theme.Colors.accentShadow)
                    .offset(y: 5)
            )
            .animation(.spring(duration: 0.25, bounce: 0.3), value: configuration.isPressed)
    }
}

#Preview("Saving") {
    SaveConfirmationView(isSaved: false, savedDate: .now, onContinue: {})
}

#Preview("Saved") {
    SaveConfirmationView(isSaved: true, savedDate: .now, onContinue: {})
}
