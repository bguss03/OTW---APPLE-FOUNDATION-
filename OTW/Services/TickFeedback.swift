import AudioToolbox
import QuartzCore
import SwiftUI
import UIKit

/// Picker-style feedback: a short system tick sound plus a selection haptic, like the iOS
/// time wheel. Throttled so fast scrolls never stutter. Haptics only work on a real iPhone.
final class TickFeedback {
    static let shared = TickFeedback()

    /// UserDefaults keys for a future Settings toggle (both default ON).
    static let soundEnabledKey = "OTW.tickSoundEnabled"
    static let hapticsEnabledKey = "OTW.tickHapticsEnabled"

    /// System picker tick. 1157 is the wheel-picker click; 1104 (keyboard tock) is the fallback.
    private static let tickSound: SystemSoundID = 1157
    /// At most one tick per 35 ms.
    private static let minimumInterval: CFTimeInterval = 0.035

    private let selection = UISelectionFeedbackGenerator()
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()
    private var lastTick: CFTimeInterval = 0

    var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Self.soundEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.soundEnabledKey) }
    }

    var isHapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Self.hapticsEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.hapticsEnabledKey) }
    }

    /// Call when scrolling starts so the first tick has no latency.
    func prepare() {
        guard isHapticsEnabled else { return }
        selection.prepare()
        impact.prepare()
    }

    /// One picker tick: sound + selection haptic.
    func tick(_ source: String = #fileID, line: Int = #line) {
        let now = CACurrentMediaTime()
        guard now - lastTick >= Self.minimumInterval else { return }
        lastTick = now
        if isHapticsEnabled {
            selection.selectionChanged()
            selection.prepare()
        }
        if isSoundEnabled {
            AudioServicesPlaySystemSound(Self.tickSound)
        }
        #if DEBUG
        print("[OTW] tick \(source):\(line)")
        #endif
    }

    /// Light impact when a scroll snaps and settles.
    func settle(_ source: String = #fileID, line: Int = #line) {
        #if DEBUG
        print("[OTW] settle \(source):\(line)")
        #endif
        guard isHapticsEnabled else { return }
        impact.impactOccurred()
        impact.prepare()
    }

    /// Success haptic (reminder checked done); no sound.
    func success() {
        guard isHapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
}

extension View {
    /// Plays a picker tick whenever `trigger` changes.
    func tickFeedback<Value: Equatable>(trigger: Value) -> some View {
        onChange(of: trigger) { _, _ in
            TickFeedback.shared.tick()
        }
    }
}
