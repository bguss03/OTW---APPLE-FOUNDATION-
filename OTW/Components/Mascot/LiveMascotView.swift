import SwiftUI

// Fully posable OTW pet built from the "OTW/Pet/*" Sketch shapes as separate layers:
// head (ears cut out), left ear, right ear, left eye, right eye. Every part is driven by a
// `MascotPose`, so keyframe sequences can move eyes, ears and body independently.

/// One frame of the mascot rig. Offsets are additive, scales multiplicative.
struct MascotPose {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var scale: CGFloat = 1
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    /// Body tilt in degrees, anchored at the bottom.
    var tilt: Double = 0
    /// Horizontal eye shift in artboard units (112-wide artboard).
    var eyeShift: CGFloat = 0
    /// 0 = open, 1 = closed.
    var blink: Double = 0
    /// 0 = open right eye, 1 = curved wink.
    var wink: Double = 0
    /// 0 = normal eyes, 1 = happy "^ ^" eyes.
    var happy: Double = 0
    /// Ear rotation in degrees around each ear's base (positive = clockwise).
    var leftEar: Double = 0
    var rightEar: Double = 0
    /// Vertical stretch of both ears from their base ("perk up").
    var earLift: CGFloat = 1
    /// Single-ear flick amount; applied to one side by the view.
    var flick: Double = 0

    static func + (a: MascotPose, b: MascotPose) -> MascotPose {
        MascotPose(
            x: a.x + b.x,
            y: a.y + b.y,
            scale: a.scale * b.scale,
            scaleX: a.scaleX * b.scaleX,
            scaleY: a.scaleY * b.scaleY,
            tilt: a.tilt + b.tilt,
            eyeShift: a.eyeShift + b.eyeShift,
            blink: a.blink + b.blink,
            wink: a.wink + b.wink,
            happy: a.happy + b.happy,
            leftEar: a.leftEar + b.leftEar,
            rightEar: a.rightEar + b.rightEar,
            earLift: a.earLift * b.earLift,
            flick: a.flick + b.flick
        )
    }
}

/// The animated mascot used in the Pet Tip banner and the Home avatar.
///
/// While visible it loops one seamless 5.28 s sequence: look forward → glance left → glance
/// right → centre → wink → neutral → ear wiggle + two blinks → idle pause. Every track starts and
/// ends on the neutral pose with eased linear keyframes (never a spring as the last keyframe, whose
/// value at the end of a short duration is not its target), so the loop never drifts or sticks.
struct LiveMascotView: View {
    var expression: PetExpression = .default
    /// Runs the loop while visible. Off = static neutral pose.
    var isLive = true
    /// Banner only: pop in (0.6 → 1.1 → 1) before the loop starts.
    var playsIntro = false
    /// Tap reaction: happy bounce, ears perk up, then the loop restarts from neutral.
    var tapTrigger = 0
    var hopTrigger = 0
    var shakeTrigger = 0
    var hopHeight: CGFloat = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var introTrigger = 0
    @State private var nervousTrigger = 0
    /// The loop plays only while true; false shows the neutral pose.
    @State private var isLooping = false
    /// Bumped to restart the loop from step 1 (fresh animator identity).
    @State private var loopGeneration = 0
    @State private var isVisible = false
    @State private var resumeToken = 0

    private static let introLength: Duration = .milliseconds(450)
    private static let tapLength: Duration = .milliseconds(950)

    private var loopsEnabled: Bool { isLive && !reduceMotion }

    var body: some View {
        KeyframeAnimator(
            initialValue: MascotPose(scale: playsIntro && !reduceMotion ? 0.6 : 1),
            trigger: introTrigger
        ) { intro in
            KeyframeAnimator(initialValue: MascotPose(), trigger: tapTrigger) { tap in
                KeyframeAnimator(initialValue: MascotPose(), trigger: hopTrigger) { hop in
                    KeyframeAnimator(initialValue: MascotPose(), trigger: shakeTrigger &+ nervousTrigger) { shake in
                        KeyframeAnimator(initialValue: MascotPose(), repeating: isLooping) { loop in
                            MascotRig(expression: expression, pose: combined(intro, tap, hop, shake, loop))
                        } keyframes: { _ in Self.loopKeyframes }
                        .id(loopGeneration)
                    } keyframes: { _ in Self.shakeKeyframes }
                } keyframes: { _ in hopKeyframes }
            } keyframes: { _ in tapKeyframes }
        } keyframes: { _ in Self.introKeyframes }
        .onAppear {
            isVisible = true
            if playsIntro && !reduceMotion { introTrigger += 1 }
            startLoop(after: playsIntro ? Self.introLength : .zero)
        }
        .onDisappear {
            // Stop and reset so the next appearance starts fresh from step 1.
            isVisible = false
            isLooping = false
            resumeToken += 1
        }
        .onChange(of: loopsEnabled) { _, enabled in
            if enabled { startLoop(after: .zero) } else { isLooping = false }
        }
        .onChange(of: tapTrigger) { _, _ in
            // Pause on neutral for the bounce, then restart the loop from step 1.
            isLooping = false
            startLoop(after: Self.tapLength)
        }
        // While nervous, shake every few seconds.
        .task(id: loopsEnabled && expression == .nervous) {
            guard loopsEnabled && expression == .nervous else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3.5...5.5)))
                guard !Task.isCancelled else { return }
                nervousTrigger &+= 1
            }
        }
        .accessibilityHidden(true)
    }

    /// Restarts the loop from step 1 after `delay`, unless something newer happened meanwhile.
    private func startLoop(after delay: Duration) {
        resumeToken += 1
        let token = resumeToken
        Task {
            if delay > .zero { try? await Task.sleep(for: delay) }
            guard token == resumeToken, isVisible, loopsEnabled else { return }
            loopGeneration += 1
            isLooping = true
        }
    }

    private func combined(_ intro: MascotPose, _ tap: MascotPose, _ hop: MascotPose,
                          _ shake: MascotPose, _ loop: MascotPose) -> MascotPose {
        if reduceMotion { return MascotPose() }
        return intro + tap + hop + shake + (isLooping ? loop : MascotPose())
    }

    // MARK: - Loop (5.28 s, starts and ends on the neutral pose)

    private static let ease = UnitCurve.easeInOut

    /// 0.0 look forward (hold 0.8) · 0.8 glance left (hold 0.4) · 1.4 glance right (hold 0.4)
    /// · 2.05 centre · 2.25 wink · 2.6 neutral · 2.6 ear wiggle ×2 · 3.21 blink · 3.62 blink
    /// · 3.78 idle pause until 5.28.
    @KeyframesBuilder<MascotPose>
    private static var loopKeyframes: some Keyframes<MascotPose> {
        // Gentle breathing 1.0 ↔ 1.03, two breaths per loop so the cycle stays seamless.
        KeyframeTrack(\.scale) {
            LinearKeyframe(1.03, duration: 1.32, timingCurve: ease)
            LinearKeyframe(1, duration: 1.32, timingCurve: ease)
            LinearKeyframe(1.03, duration: 1.32, timingCurve: ease)
            LinearKeyframe(1, duration: 1.32, timingCurve: ease)
        }
        KeyframeTrack(\.eyeShift) {
            LinearKeyframe(0, duration: 0.8, timingCurve: ease)
            LinearKeyframe(-4.8, duration: 0.2, timingCurve: ease)
            LinearKeyframe(-4.8, duration: 0.4, timingCurve: ease)
            LinearKeyframe(4.8, duration: 0.25, timingCurve: ease)
            LinearKeyframe(4.8, duration: 0.4, timingCurve: ease)
            LinearKeyframe(0, duration: 0.2, timingCurve: ease)
            LinearKeyframe(0, duration: 3.03, timingCurve: ease)
        }
        KeyframeTrack(\.tilt) {
            LinearKeyframe(0, duration: 0.8, timingCurve: ease)
            LinearKeyframe(-4, duration: 0.2, timingCurve: ease)
            LinearKeyframe(-4, duration: 0.4, timingCurve: ease)
            LinearKeyframe(4, duration: 0.25, timingCurve: ease)
            LinearKeyframe(4, duration: 0.4, timingCurve: ease)
            LinearKeyframe(0, duration: 0.2, timingCurve: ease)
            LinearKeyframe(3, duration: 0.12, timingCurve: ease)
            LinearKeyframe(3, duration: 0.08, timingCurve: ease)
            LinearKeyframe(0, duration: 0.15, timingCurve: ease)
            LinearKeyframe(0, duration: 2.68, timingCurve: ease)
        }
        KeyframeTrack(\.wink) {
            LinearKeyframe(0, duration: 2.25, timingCurve: ease)
            LinearKeyframe(1, duration: 0.12, timingCurve: ease)
            LinearKeyframe(1, duration: 0.08, timingCurve: ease)
            LinearKeyframe(0, duration: 0.15, timingCurve: ease)
            LinearKeyframe(0, duration: 2.68, timingCurve: ease)
        }
        KeyframeTrack(\.leftEar) {
            LinearKeyframe(0, duration: 2.6, timingCurve: ease)
            LinearKeyframe(8, duration: 0.1, timingCurve: ease)
            LinearKeyframe(-8, duration: 0.12, timingCurve: ease)
            LinearKeyframe(8, duration: 0.12, timingCurve: ease)
            LinearKeyframe(-8, duration: 0.12, timingCurve: ease)
            LinearKeyframe(0, duration: 0.15, timingCurve: ease)
            LinearKeyframe(0, duration: 2.07, timingCurve: ease)
        }
        KeyframeTrack(\.rightEar) {
            LinearKeyframe(0, duration: 2.6, timingCurve: ease)
            LinearKeyframe(-8, duration: 0.1, timingCurve: ease)
            LinearKeyframe(8, duration: 0.12, timingCurve: ease)
            LinearKeyframe(-8, duration: 0.12, timingCurve: ease)
            LinearKeyframe(8, duration: 0.12, timingCurve: ease)
            LinearKeyframe(0, duration: 0.15, timingCurve: ease)
            LinearKeyframe(0, duration: 2.07, timingCurve: ease)
        }
        KeyframeTrack(\.blink) {
            LinearKeyframe(0, duration: 3.21, timingCurve: ease)
            LinearKeyframe(1, duration: 0.06, timingCurve: ease)
            LinearKeyframe(1, duration: 0.03, timingCurve: ease)
            LinearKeyframe(0, duration: 0.07, timingCurve: ease)
            LinearKeyframe(0, duration: 0.25, timingCurve: ease)
            LinearKeyframe(1, duration: 0.06, timingCurve: ease)
            LinearKeyframe(1, duration: 0.03, timingCurve: ease)
            LinearKeyframe(0, duration: 0.07, timingCurve: ease)
            LinearKeyframe(0, duration: 1.5, timingCurve: ease)
        }
    }

    // MARK: - One-shot reactions (each ends exactly on neutral)

    /// Banner pop-in: 0.6 → 1.1 → 1.
    @KeyframesBuilder<MascotPose>
    private static var introKeyframes: some Keyframes<MascotPose> {
        KeyframeTrack(\.scale) {
            MoveKeyframe(0.6)
            LinearKeyframe(1.1, duration: 0.25, timingCurve: .easeOut)
            LinearKeyframe(1, duration: 0.2, timingCurve: ease)
        }
    }

    /// Happy bounce, ears perk up, happy eyes, then back to normal (0.95 s).
    @KeyframesBuilder<MascotPose>
    private var tapKeyframes: some Keyframes<MascotPose> {
        KeyframeTrack(\.scale) {
            LinearKeyframe(0.88, duration: 0.08, timingCurve: Self.ease)
            LinearKeyframe(1.12, duration: 0.15, timingCurve: .easeOut)
            LinearKeyframe(0.97, duration: 0.15, timingCurve: Self.ease)
            LinearKeyframe(1, duration: 0.15, timingCurve: Self.ease)
        }
        KeyframeTrack(\.y) {
            LinearKeyframe(0, duration: 0.08, timingCurve: Self.ease)
            LinearKeyframe(-hopHeight * 0.7, duration: 0.15, timingCurve: .easeOut)
            LinearKeyframe(0, duration: 0.2, timingCurve: .easeIn)
        }
        KeyframeTrack(\.earLift) {
            LinearKeyframe(1.15, duration: 0.12, timingCurve: .easeOut)
            LinearKeyframe(1.15, duration: 0.5, timingCurve: Self.ease)
            LinearKeyframe(1, duration: 0.25, timingCurve: Self.ease)
        }
        KeyframeTrack(\.leftEar) {
            LinearKeyframe(-6, duration: 0.12, timingCurve: .easeOut)
            LinearKeyframe(-6, duration: 0.5, timingCurve: Self.ease)
            LinearKeyframe(0, duration: 0.25, timingCurve: Self.ease)
        }
        KeyframeTrack(\.rightEar) {
            LinearKeyframe(6, duration: 0.12, timingCurve: .easeOut)
            LinearKeyframe(6, duration: 0.5, timingCurve: Self.ease)
            LinearKeyframe(0, duration: 0.25, timingCurve: Self.ease)
        }
        KeyframeTrack(\.happy) {
            LinearKeyframe(1, duration: 0.12, timingCurve: Self.ease)
            LinearKeyframe(1, duration: 0.65, timingCurve: Self.ease)
            LinearKeyframe(0, duration: 0.15, timingCurve: Self.ease)
        }
    }

    @KeyframesBuilder<MascotPose>
    private var hopKeyframes: some Keyframes<MascotPose> {
        KeyframeTrack(\.y) {
            LinearKeyframe(0, duration: 0.08, timingCurve: Self.ease)
            LinearKeyframe(-hopHeight, duration: 0.16, timingCurve: .easeOut)
            LinearKeyframe(0, duration: 0.16, timingCurve: .easeIn)
            LinearKeyframe(0, duration: 0.15, timingCurve: Self.ease)
        }
        KeyframeTrack(\.scaleX) {
            LinearKeyframe(1.08, duration: 0.08, timingCurve: Self.ease)
            LinearKeyframe(0.94, duration: 0.16, timingCurve: Self.ease)
            LinearKeyframe(1.08, duration: 0.16, timingCurve: Self.ease)
            LinearKeyframe(1, duration: 0.15, timingCurve: Self.ease)
        }
        KeyframeTrack(\.scaleY) {
            LinearKeyframe(0.9, duration: 0.08, timingCurve: Self.ease)
            LinearKeyframe(1.08, duration: 0.16, timingCurve: Self.ease)
            LinearKeyframe(0.9, duration: 0.16, timingCurve: Self.ease)
            LinearKeyframe(1, duration: 0.15, timingCurve: Self.ease)
        }
    }

    @KeyframesBuilder<MascotPose>
    private static var shakeKeyframes: some Keyframes<MascotPose> {
        KeyframeTrack(\.x) {
            LinearKeyframe(-1.5, duration: 0.06, timingCurve: ease)
            LinearKeyframe(1.5, duration: 0.07, timingCurve: ease)
            LinearKeyframe(-1.2, duration: 0.07, timingCurve: ease)
            LinearKeyframe(1, duration: 0.07, timingCurve: ease)
            LinearKeyframe(0, duration: 0.1, timingCurve: ease)
        }
        KeyframeTrack(\.tilt) {
            LinearKeyframe(-4, duration: 0.06, timingCurve: ease)
            LinearKeyframe(4, duration: 0.07, timingCurve: ease)
            LinearKeyframe(-3, duration: 0.07, timingCurve: ease)
            LinearKeyframe(2, duration: 0.07, timingCurve: ease)
            LinearKeyframe(0, duration: 0.1, timingCurve: ease)
        }
    }
}

// MARK: - Rig

/// Draws the mascot from a pose: head, two ears, two (or three, for Nervous) eye shapes.
struct MascotRig: View {
    let expression: PetExpression
    let pose: MascotPose

    var body: some View {
        ZStack {
            MascotShape(path: RigArt.head)
                .fill(Theme.Colors.accent)
            MascotShape(path: RigArt.ear(0, angle: pose.leftEar, lift: pose.earLift))
                .fill(Theme.Colors.accent)
            MascotShape(path: RigArt.ear(1, angle: pose.rightEar, lift: pose.earLift))
                .fill(Theme.Colors.accent)
            RigEyes(expression: expression, pose: pose)
                .id(expression)
                .transition(.eyeMorph)
        }
        .animation(.spring(duration: 0.3, bounce: 0.2), value: expression)
        .scaleEffect(x: pose.scale * pose.scaleX, y: pose.scale * pose.scaleY, anchor: .bottom)
        .rotationEffect(.degrees(pose.tilt), anchor: .bottom)
        .offset(x: pose.x, y: pose.y)
    }
}

private struct RigEyes: View {
    let expression: PetExpression
    let pose: MascotPose

    var body: some View {
        ZStack {
            ForEach(Array(shapes.enumerated()), id: \.offset) { _, path in
                MascotShape(path: path)
                    .fill(Color.white)
            }
        }
    }

    /// Eye paths for this frame, already squashed and shifted in artboard space.
    private var shapes: [Path] {
        let shift = pose.eyeShift
        let blink = 1 - 0.92 * min(max(pose.blink, 0), 1)
        let happy = min(max(pose.happy, 0), 1)
        let wink = min(max(pose.wink, 0), 1)

        // Tap: every eye squashes closed, then the happy "^ ^" eyes open.
        if happy >= 0.5 && expression != .happy {
            return MascotArt.eyes(for: .happy).map { RigArt.squash($0.path, scaleY: (happy - 0.5) * 2, dx: shift) }
        }

        let baseOpen = expression == .happy ? 1 : 1 - 2 * happy
        return MascotArt.eyes(for: expression).enumerated().map { index, eye in
            var scale = baseOpen * (eye.blinks ? blink : 1)
            // Wink: the right eye squashes into the curved wink shape.
            if index == 1 && expression == .default && wink > 0 {
                if wink >= 0.5 {
                    return RigArt.squash(RigArt.winkArc, scaleY: (wink - 0.5) * 2, dx: shift)
                }
                scale *= 1 - 2 * wink
            }
            return RigArt.squash(eye.path, scaleY: scale, dx: shift)
        }
    }
}

private enum RigArt {
    /// Head layer: the body with both ear areas removed.
    static let head: Path = {
        var cuts = Path()
        for ear in MascotArt.ears { cuts.addRect(ear.cut) }
        return MascotArt.body.subtracting(cuts)
    }()

    /// Ear layers: the body clipped to each ear area (which overlaps the head to hide seams).
    static let ears: [Path] = MascotArt.ears.map { MascotArt.body.intersection(Path($0.piece)) }

    /// Curved wink shape from "OTW/Pet/Wink".
    static let winkArc: Path = MascotArt.eyes(for: .wink)[1].path

    static func ear(_ index: Int, angle: Double, lift: CGFloat) -> Path {
        let ear = MascotArt.ears[index]
        let pivot = CGPoint(x: ear.pivot.x * MascotArt.size.width, y: ear.pivot.y * MascotArt.size.height)
        let transform = CGAffineTransform(translationX: pivot.x, y: pivot.y)
            .rotated(by: angle * .pi / 180)
            .scaledBy(x: 1, y: lift)
            .translatedBy(x: -pivot.x, y: -pivot.y)
        return ears[index].applying(transform)
    }

    /// Squashes a path vertically around its own centre and shifts it horizontally.
    static func squash(_ path: Path, scaleY: CGFloat, dx: CGFloat) -> Path {
        let box = path.boundingRect
        let transform = CGAffineTransform(translationX: box.midX + dx, y: box.midY)
            .scaledBy(x: 1, y: max(scaleY, 0.04))
            .translatedBy(x: -box.midX, y: -box.midY)
        return path.applying(transform)
    }
}

#Preview {
    @Previewable @State var taps = 0
    LiveMascotView(playsIntro: true, tapTrigger: taps)
        .frame(width: 140, height: 152)
        .onTapGesture { taps += 1 }
}
