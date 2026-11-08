import SwiftUI
import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === interactivePopGestureRecognizer
    }
}

struct BackSwipeEnabler: View {
    var body: some View {
        Color.clear.allowsHitTesting(false)
    }
}

extension View {
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
