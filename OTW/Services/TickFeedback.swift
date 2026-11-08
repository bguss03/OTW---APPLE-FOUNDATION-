import AudioToolbox
import QuartzCore
import SwiftUI
import UIKit

final class TickFeedback {
    static let shared = TickFeedback()

    static let soundEnabledKey = "OTW.tickSoundEnabled"
    static let hapticsEnabledKey = "OTW.tickHapticsEnabled"

    private static let tickSound: SystemSoundID = 1157
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

    func prepare() {
        guard isHapticsEnabled else { return }
        selection.prepare()
        impact.prepare()
    }

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

    func settle(_ source: String = #fileID, line: Int = #line) {
        #if DEBUG
        print("[OTW] settle \(source):\(line)")
        #endif
        guard isHapticsEnabled else { return }
        impact.impactOccurred()
        impact.prepare()
    }

    func success() {
        guard isHapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
}

extension View {
    func tickFeedback<Value: Equatable>(trigger: Value) -> some View {
        onChange(of: trigger) { _, _ in
            TickFeedback.shared.tick()
        }
    }
}
