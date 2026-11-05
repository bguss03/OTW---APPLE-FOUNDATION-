import SwiftUI
import SwiftData

/// Pressed state for every tappable element: a slight shrink and fade with a quick spring.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.spring(duration: 0.25, bounce: 0.35), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// Default pressed style for buttons and chips.
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    /// Subtler pressed style for full-width cards.
    static var pressableCard: PressableButtonStyle { PressableButtonStyle(scale: 0.98) }
}

/// A rectangle grown beyond the view's bounds, used to reach the 44 x 44 pt minimum tap area
/// without changing the drawn size.
struct ExpandedHitShape: Shape {
    var dx: CGFloat
    var dy: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: -dx, dy: -dy))
    }
}

extension View {
    /// Extends the hit area by `dx` / `dy` points on each side.
    func expandedHitArea(dx: CGFloat = 0, dy: CGFloat = 0) -> some View {
        contentShape(ExpandedHitShape(dx: dx, dy: dy))
    }
}

// MARK: - Card → Detail zoom (iOS 18+, normal push on iOS 17)

extension EnvironmentValues {
    /// Namespace shared by the navigation stack for card → detail zoom transitions.
    @Entry var zoomNamespace: Namespace.ID? = nil
}

/// Stable transition id for a card on a given screen.
func zoomID(_ screen: String, _ id: PersistentIdentifierBox) -> String {
    "\(screen)-\(id.id.hashValue)"
}

extension View {
    @ViewBuilder
    func zoomTransitionSource(_ id: String, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func zoomTransitionDestination(_ id: String?, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let id, let namespace {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
