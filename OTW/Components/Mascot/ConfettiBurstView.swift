import SwiftUI

/// Orange dots and dashes that burst outward from the centre, then drift down and fade.
/// Drawn in a single Canvas driven by TimelineView and paused once the burst is over.
struct ConfettiBurstView: View {
    /// When set, the burst starts at this time.
    let start: Date?

    private static let duration: TimeInterval = 1.8
    @State private var particles: [Particle] = Particle.makeBurst(count: 26)
    @State private var isFinished = false

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: start == nil || isFinished)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                guard t >= 0, t < Self.duration else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for particle in particles {
                    // Drag eases the outward burst; gravity adds the drift.
                    let k = 3.2
                    let travel = (1 - exp(-k * t)) / k
                    let x = center.x + particle.velocity.dx * travel
                    let y = center.y + particle.velocity.dy * travel + 70 * t * t
                    let opacity = t < 0.9 ? 1 : max(0, 1 - (t - 0.9) / (Self.duration - 0.9))
                    var piece = context
                    piece.opacity = opacity
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .degrees(particle.spin * t + particle.angle))
                    let rect = CGRect(x: -particle.size.width / 2, y: -particle.size.height / 2,
                                      width: particle.size.width, height: particle.size.height)
                    piece.fill(Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 2), with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
        .task(id: start) {
            guard start != nil else { return }
            isFinished = false
            particles = Particle.makeBurst(count: 26)
            try? await Task.sleep(for: .seconds(Self.duration))
            isFinished = true
        }
        .accessibilityHidden(true)
    }

    struct Particle {
        let velocity: CGVector
        let size: CGSize
        let color: Color
        let angle: Double
        let spin: Double

        static func makeBurst(count: Int) -> [Particle] {
            let colors = [Theme.Colors.accent, Theme.Colors.accentPale, Theme.Colors.accentDeep,
                          Theme.Colors.accentTintSoft, Theme.Colors.accentSoft, Theme.Colors.accentShadow]
            return (0..<count).map { _ in
                let direction = Double.random(in: 0..<(2 * .pi))
                let speed = Double.random(in: 380...720)
                let isDash = Bool.random()
                let side = CGFloat.random(in: 6...11)
                return Particle(
                    velocity: CGVector(dx: cos(direction) * speed, dy: sin(direction) * speed - 120),
                    size: isDash ? CGSize(width: side * 1.9, height: side * 0.75) : CGSize(width: side, height: side),
                    color: colors.randomElement() ?? Theme.Colors.accent,
                    angle: Double.random(in: 0...180),
                    spin: Double.random(in: -420...420)
                )
            }
        }
    }
}
