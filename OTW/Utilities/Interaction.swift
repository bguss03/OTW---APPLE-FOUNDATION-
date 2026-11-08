import SwiftUI
import SwiftData

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
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    static var pressableCard: PressableButtonStyle { PressableButtonStyle(scale: 0.98) }
}

struct ExpandedHitShape: Shape {
    var dx: CGFloat
    var dy: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: -dx, dy: -dy))
    }
}

extension View {
    func expandedHitArea(dx: CGFloat = 0, dy: CGFloat = 0) -> some View {
        contentShape(ExpandedHitShape(dx: dx, dy: dy))
    }
}

// MARK: - Zoom Transition

extension EnvironmentValues {
    @Entry var zoomNamespace: Namespace.ID? = nil
}

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
