import SwiftUI
import UIKit

/// Keeps the standard edge back-swipe working on screens that hide the system navigation bar
/// and draw their own back button, and gives it priority over horizontal scroll views
/// (such as the Calendar month pager).
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1
    }

    /// Other pans (e.g. a paging ScrollView) wait until the edge swipe has failed.
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === interactivePopGestureRecognizer
    }
}

/// Marker kept on pushed screens with a custom back button. The behaviour lives in the
/// `UINavigationController` extension above.
struct BackSwipeEnabler: View {
    var body: some View {
        Color.clear.allowsHitTesting(false)
    }
}

extension View {
    /// Reserves a 20pt strip at the leading edge for the back-swipe and calls `onBack`
    /// if a rightward drag on it completes without the system gesture taking over.
    func edgeBackSwipe(onBack: @escaping () -> Void) -> some View {
        overlay(alignment: .leading) {
            Color.clear
                .frame(width: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            if value.translation.width > 80 && abs(value.translation.height) < 80 {
                                onBack()
                            }
                        }
                )
                .ignoresSafeArea()
        }
    }
}
